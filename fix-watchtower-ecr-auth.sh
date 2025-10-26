#!/bin/bash

# Script to fix Watchtower ECR authentication on existing instances
# This script should be run on both staging and production instances

set -e

echo "🔧 Fixing Watchtower ECR authentication..."

# Get AWS region and ECR repository URL from environment or Terraform
AWS_REGION=$(aws configure get region)
ECR_REPO_URL=$(aws ecr describe-repositories --repository-names sttf-api --query 'repositories[0].repositoryUri' --output text)

echo "📍 AWS Region: $AWS_REGION"
echo "📍 ECR Repository: $ECR_REPO_URL"

# Create ECR credential refresh script
cat > /home/ec2-user/refresh-ecr-credentials.sh << EOF
#!/bin/bash
# Script to refresh ECR credentials for Watchtower
while true; do
    echo "\$(date): Refreshing ECR credentials..."
    
    # Refresh ECR login every 10 hours (ECR tokens expire after 12 hours)
    aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REPO_URL
    
    # Also refresh for ec2-user
    sudo -u ec2-user aws ecr get-login-password --region $AWS_REGION | sudo -u ec2-user docker login --username AWS --password-stdin $ECR_REPO_URL
    
    echo "\$(date): ECR credentials refreshed successfully"
    
    # Wait 10 hours before next refresh
    sleep 36000
done
EOF

# Make the script executable
chmod +x /home/ec2-user/refresh-ecr-credentials.sh

# Stop any existing credential refresh process
pkill -f refresh-ecr-credentials.sh || true

# Start the credential refresh script in background
echo "🚀 Starting ECR credential refresh daemon..."
nohup /home/ec2-user/refresh-ecr-credentials.sh > /home/ec2-user/ecr-refresh.log 2>&1 &

# Refresh credentials immediately
echo "🔄 Refreshing ECR credentials now..."
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REPO_URL
sudo -u ec2-user aws ecr get-login-password --region $AWS_REGION | sudo -u ec2-user docker login --username AWS --password-stdin $ECR_REPO_URL

# Restart Watchtower to pick up new credentials
echo "🔄 Restarting Watchtower..."
docker-compose restart watchtower-prod 2>/dev/null || docker-compose restart watchtower-staging 2>/dev/null || echo "⚠️  Could not restart Watchtower - check container name"

echo "✅ Watchtower ECR authentication fix applied!"
echo ""
echo "📋 What was fixed:"
echo "   • Created ECR credential refresh script that runs every 10 hours"
echo "   • Refreshed ECR credentials for both root and ec2-user"
echo "   • Restarted Watchtower to pick up new credentials"
echo ""
echo "📊 Monitor the fix:"
echo "   • Check ECR refresh logs: tail -f /home/ec2-user/ecr-refresh.log"
echo "   • Check Watchtower logs: docker logs watchtower-prod (or watchtower-staging)"
echo "   • Test ECR access: docker pull $ECR_REPO_URL:prod"
echo ""
echo "🔄 The credential refresh will run automatically every 10 hours"
