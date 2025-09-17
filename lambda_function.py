import json
import boto3
import os
import time

def handler(event, context):
    """
    Lambda function to automatically deploy new ECR images to EC2 instances
    """
    print(f"Received event: {json.dumps(event)}")
    
    # Get environment variables
    staging_instance_id = os.environ['STAGING_INSTANCE_ID']
    prod_instance_id = os.environ['PROD_INSTANCE_ID']
    ecr_repository_url = os.environ['ECR_REPOSITORY_URL']
    aws_region = os.environ['DEPLOYMENT_REGION']
    
    # Get the image tag from the event
    image_tag = event['detail']['image-tag']
    repository_name = event['detail']['repository-name']
    
    print(f"Processing image push for {repository_name}:{image_tag}")
    
    # Initialize AWS clients
    ssm_client = boto3.client('ssm', region_name=aws_region)
    ecr_client = boto3.client('ecr', region_name=aws_region)
    
    # Determine which instance to update based on image tag
    if image_tag == 'latest':
        target_instance_id = staging_instance_id
        container_name = 'sttf-api-staging'
        secret_name = 'SttfApiStagingContainerSecrets'
        print(f"Deploying to staging instance: {target_instance_id}")
    elif image_tag == 'prod':
        target_instance_id = prod_instance_id
        container_name = 'sttf-api-prod'
        secret_name = 'SttfApiProdContainerSecrets'
        print(f"Deploying to production instance: {target_instance_id}")
    else:
        print(f"Unknown image tag: {image_tag}. Skipping deployment.")
        return {
            'statusCode': 200,
            'body': json.dumps(f'Unknown image tag: {image_tag}')
        }
    
    try:
        # Create deployment script
        deployment_script = f"""#!/bin/bash
set -e

# Login to ECR
aws ecr get-login-password --region {aws_region} | docker login --username AWS --password-stdin {ecr_repository_url}

# Pull the new image
docker pull {ecr_repository_url}:{image_tag}

# Stop and remove existing container
docker stop {container_name} 2>/dev/null || true
docker rm {container_name} 2>/dev/null || true

# Run the new container with environment variables from Secrets Manager
docker run -d -p 5000:5000 --name {container_name} \
  --env-file <(aws secretsmanager get-secret-value \
    --secret-id {secret_name} \
    --query SecretString --output text | jq -r 'to_entries|map("\(.key)=\(.value|tostring)")|.[]') \
  {ecr_repository_url}:{image_tag}

# Verify container is running
sleep 10
if docker ps | grep -q {container_name}; then
    echo "Deployment successful: {container_name} is running"
else
    echo "Deployment failed: {container_name} is not running"
    exit 1
fi
"""
        
        # Send command to EC2 instance
        response = ssm_client.send_command(
            InstanceIds=[target_instance_id],
            DocumentName="AWS-RunShellScript",
            Parameters={
                'commands': [deployment_script]
            },
            TimeoutSeconds=300
        )
        
        command_id = response['Command']['CommandId']
        print(f"Sent deployment command {command_id} to instance {target_instance_id}")
        
        # Wait for command to complete
        max_attempts = 30
        for attempt in range(max_attempts):
            time.sleep(10)
            
            try:
                result = ssm_client.get_command_invocation(
                    CommandId=command_id,
                    InstanceId=target_instance_id
                )
                
                status = result['Status']
                print(f"Command status: {status}")
                
                if status in ['Success', 'Failed', 'Cancelled', 'TimedOut']:
                    if status == 'Success':
                        print(f"Deployment successful for {image_tag}")
                        return {
                            'statusCode': 200,
                            'body': json.dumps(f'Deployment successful for {image_tag}')
                        }
                    else:
                        error_message = result.get('StandardErrorContent', 'Unknown error')
                        print(f"Deployment failed: {error_message}")
                        return {
                            'statusCode': 500,
                            'body': json.dumps(f'Deployment failed: {error_message}')
                        }
                        
            except ssm_client.exceptions.InvocationDoesNotExist:
                print(f"Command {command_id} not found, waiting...")
                continue
        
        print("Command timed out")
        return {
            'statusCode': 500,
            'body': json.dumps('Deployment timed out')
        }
        
    except Exception as e:
        print(f"Error during deployment: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps(f'Deployment error: {str(e)}')
        }