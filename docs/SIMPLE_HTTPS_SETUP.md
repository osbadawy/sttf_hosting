# Simple HTTPS Setup for STTF API (No Domain Required)

This guide explains how to set up your Docker containers running on port 5000 with load balancing using AWS Application Load Balancer, without requiring a custom domain.

## 🚀 **What You Get**

- **Load Balancer**: Distributes traffic between your EC2 instances
- **Health Checks**: Automatic monitoring of your containers
- **Path-based Routing**: 
  - Production API: `http://ALB_DNS_NAME/`
  - Staging API: `http://ALB_DNS_NAME/staging/`
- **Security**: Private EC2 instances with proper security groups
- **Scalability**: Easy to add more instances later

## 📋 **Prerequisites**

- AWS CLI configured with appropriate permissions
- Terraform installed
- Your Docker containers must expose a `/health` endpoint

## 🚀 **Quick Start**

### 1. Deploy the Infrastructure

```bash
# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Apply the changes
terraform apply
```

### 2. Get Your API URLs

After deployment, run:

```bash
terraform output
```

You'll see output like:
```
api_url = "http://sttf-alb-1234567890.eu-central-1.elb.amazonaws.com"
staging_api_url = "http://sttf-alb-1234567890.eu-central-1.elb.amazonaws.com/staging"
alb_dns_name = "sttf-alb-1234567890.eu-central-1.elb.amazonaws.com"
```

### 3. Test Your APIs

```bash
# Test production API
curl http://sttf-alb-1234567890.eu-central-1.elb.amazonaws.com/health

# Test staging API
curl http://sttf-alb-1234567890.eu-central-1.elb.amazonaws.com/staging/health
```

## 🔧 **Configuration**

### Current Setup
- **Production API**: Available at the ALB DNS name root path
- **Staging API**: Available at the ALB DNS name with `/staging` prefix
- **Health Checks**: Both APIs are monitored via `/health` endpoint
- **Security**: EC2 instances are in private subnets, only accessible via ALB

### Update Frontend URLs

After deployment, update your `terraform.tfvars` with the actual ALB DNS name:

```hcl
# Replace ALB_DNS_NAME with the actual DNS name from terraform output
staging_env_vars = {
  # ... other vars ...
  WEB_FRONTEND_URL    = "http://sttf-alb-1234567890.eu-central-1.elb.amazonaws.com/staging"
  MOBILE_FRONTEND_URL = "http://sttf-alb-1234567890.eu-central-1.elb.amazonaws.com/staging"
}

prod_env_vars = {
  # ... other vars ...
  WEB_FRONTEND_URL    = "http://sttf-alb-1234567890.eu-central-1.elb.amazonaws.com"
  MOBILE_FRONTEND_URL = "http://sttf-alb-1234567890.eu-central-1.elb.amazonaws.com"
}
```

Then run `terraform apply` to update the environment variables.

## 🏗️ **Architecture**

```
Internet → ALB (Public Subnets) → EC2 Instances (Private Subnets)
                                    ↓
                              RDS Database (Private Subnets)
```

### Components
- **VPC**: Custom VPC with public and private subnets
- **ALB**: Application Load Balancer in public subnets
- **EC2**: Your instances in private subnets (more secure)
- **RDS**: Database in private subnets
- **Security Groups**: Properly configured for ALB ↔ EC2 ↔ RDS communication

## 💰 **Cost Estimate**

- **ALB**: ~$16/month + data processing
- **NAT Gateway**: ~$32/month + data processing
- **Total**: ~$48/month + data processing charges

## 🔒 **Security Features**

- ✅ **Private EC2 instances** (not directly accessible from internet)
- ✅ **Security groups** restrict traffic to necessary ports only
- ✅ **ALB health checks** ensure only healthy instances receive traffic
- ✅ **VPC isolation** for better network security

## 🚨 **Troubleshooting**

### Health Check Failures
If your containers aren't responding to health checks:

1. **Check your application**: Ensure it responds to `GET /health` with HTTP 200
2. **Check security groups**: ALB should be able to reach EC2 on port 5000
3. **Check container logs**: `docker logs <container_name>`

### ALB Not Responding
1. **Check ALB status**: Ensure it's in "active" state
2. **Check target groups**: Ensure instances are healthy
3. **Check security groups**: ALB should allow HTTP traffic on port 80

### Common Commands

```bash
# Check ALB status
aws elbv2 describe-load-balancers --names sttf-alb

# Check target group health
aws elbv2 describe-target-health --target-group-arn <TARGET_GROUP_ARN>

# Check EC2 instance status
aws ec2 describe-instances --instance-ids <INSTANCE_ID>
```

## 🔄 **Adding HTTPS Later**

If you get a domain later, you can easily add HTTPS:

1. **Set your domain** in `terraform.tfvars`:
   ```hcl
   domain_name = "api.yourdomain.com"
   ```

2. **Configure Route53** (either provide existing zone ID or set `create_route53_zone = true`)

3. **Run terraform apply** - it will automatically:
   - Create SSL certificate
   - Set up HTTPS listener
   - Redirect HTTP to HTTPS
   - Create DNS records

## 🧹 **Cleanup**

To remove all resources:

```bash
terraform destroy
```

## 📞 **Need Help?**

1. **Check terraform plan** for any errors before applying
2. **Verify AWS credentials** have sufficient permissions
3. **Check CloudWatch logs** for application-level issues
4. **Ensure your Docker containers** expose the `/health` endpoint

## 🎯 **Next Steps**

1. **Deploy**: Run `terraform apply`
2. **Test**: Verify both APIs are accessible
3. **Update frontend**: Use the ALB DNS name in your applications
4. **Monitor**: Set up CloudWatch alarms for health checks
5. **Scale**: Add more EC2 instances to the target groups as needed

Your APIs are now accessible via the ALB with proper load balancing and health monitoring! 🎉
