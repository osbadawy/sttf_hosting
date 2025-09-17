# HTTPS Setup for STTF API

This guide explains how to set up HTTPS access for your Docker containers running on port 5000 of your EC2 instances using AWS Application Load Balancer (ALB) with SSL certificates.

## Architecture Overview

The solution includes:
- **Custom VPC** with public and private subnets
- **Application Load Balancer (ALB)** in public subnets
- **EC2 instances** in private subnets running Docker containers
- **SSL certificates** from AWS Certificate Manager (ACM)
- **Route53** DNS configuration
- **Security groups** properly configured for ALB and EC2 communication

## Prerequisites

1. **Domain Name**: You need a domain name (e.g., `api.yourdomain.com`)
2. **Route53 Hosted Zone**: Either use an existing hosted zone or create a new one
3. **AWS CLI**: Configured with appropriate permissions
4. **Terraform**: Installed and configured

## Configuration Steps

### 1. Update Domain Configuration

Edit `terraform.tfvars` and update the domain configuration:

```hcl
# Domain configuration
domain_name = "api.yourdomain.com"  # Replace with your actual domain
route53_zone_id = "Z1234567890ABCDEF"  # Your Route53 hosted zone ID
create_route53_zone = false  # Set to true if you want to create a new hosted zone
```

### 2. Update Frontend URLs

The frontend URLs in `terraform.tfvars` have been updated to use HTTPS:

```hcl
# For staging
WEB_FRONTEND_URL    = "https://staging.api.yourdomain.com"
MOBILE_FRONTEND_URL = "https://staging.api.yourdomain.com"

# For production  
WEB_FRONTEND_URL    = "https://api.yourdomain.com"
MOBILE_FRONTEND_URL = "https://api.yourdomain.com"
```

### 3. Deploy the Infrastructure

```bash
# Initialize Terraform
terraform init

# Plan the deployment
terraform plan

# Apply the changes
terraform apply
```

## Access URLs

After deployment, your APIs will be accessible at:

- **Production API**: `https://api.yourdomain.com`
- **Staging API**: `https://staging.api.yourdomain.com`

## SSL Certificate

The SSL certificate is automatically provisioned using AWS Certificate Manager (ACM) and includes:
- Wildcard certificate for `*.yourdomain.com`
- Automatic validation via Route53 DNS records
- Automatic renewal (managed by AWS)

## Security Configuration

### ALB Security Group
- Allows HTTP (80) and HTTPS (443) traffic from anywhere
- Redirects HTTP to HTTPS automatically

### EC2 Security Group
- Allows traffic on port 5000 only from the ALB
- Allows SSH access (optional)
- Allows all outbound traffic

### RDS Security Group
- Allows PostgreSQL (5432) traffic only from EC2 instances

## Load Balancer Configuration

### Target Groups
- **Production**: Routes to production EC2 instance
- **Staging**: Routes to staging EC2 instance via path-based routing (`/staging/*`)

### Health Checks
- Path: `/health`
- Protocol: HTTP
- Port: 5000
- Interval: 30 seconds
- Timeout: 5 seconds
- Healthy threshold: 2
- Unhealthy threshold: 2

## Monitoring and Troubleshooting

### Health Check Endpoint
Ensure your Docker containers expose a `/health` endpoint that returns HTTP 200 when healthy.

### ALB Logs
Enable ALB access logs to monitor traffic and troubleshoot issues:

```bash
# Enable ALB access logs (optional)
aws elbv2 modify-load-balancer-attributes \
  --load-balancer-arn <ALB_ARN> \
  --attributes Key=access_logs.s3.enabled,Value=true
```

### Common Issues

1. **Certificate Validation Fails**
   - Ensure your domain is properly configured in Route53
   - Check that the hosted zone ID is correct

2. **Health Checks Fail**
   - Verify your application responds to `/health` endpoint
   - Check security group rules allow ALB to reach EC2 on port 5000

3. **DNS Resolution Issues**
   - Verify Route53 records are created correctly
   - Check that the domain is pointing to the ALB

## Cost Considerations

- **ALB**: ~$16/month + data processing charges
- **NAT Gateway**: ~$32/month + data processing charges
- **SSL Certificate**: Free (AWS managed)
- **Route53**: ~$0.50/month per hosted zone + query charges

## Cleanup

To remove all resources:

```bash
terraform destroy
```

## Next Steps

1. Update your frontend applications to use the new HTTPS URLs
2. Configure monitoring and alerting for the ALB and EC2 instances
3. Set up CloudWatch logs for better observability
4. Consider implementing WAF rules for additional security

## Support

For issues or questions:
1. Check the Terraform plan output for any errors
2. Verify all required variables are set correctly
3. Ensure your AWS credentials have sufficient permissions
4. Check CloudWatch logs for application-level issues
