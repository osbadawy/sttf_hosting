# STTF Hosting - Simplified Infrastructure

A cost-effective AWS infrastructure setup for hosting STTF API with automatic container updates.

## 🏗️ Architecture

```
Internet → EC2 Instances (Public) → RDS Databases (Public Subnets)
```

### Components
- **2x EC2 Instances** (t3.micro) - Staging & Production
- **2x RDS PostgreSQL** (db.t3.micro) - Staging & Production databases  
- **1x ECR Repository** - Container image storage
- **Watchtower** - Automatic container updates every 5 minutes

## 💰 Cost Estimate

- **EC2 Instances**: ~$15-30/month (2x t3.micro)
- **RDS Databases**: ~$25-50/month (2x db.t3.micro)
- **ECR Repository**: ~$1-5/month (storage + transfer)
- **Total**: ~$40-85/month (vs ~$110-175/month with ALB + NAT Gateway)

## 🚀 Quick Start

### 1. Configure Variables

Copy and edit the variables file:
```bash
cp terraform.tfvars.example terraform.tfvars
```

Update `terraform.tfvars` with your values:
```hcl
# Key pair for SSH access
key_pair_name = "your-key-pair-name"

# Database passwords
staging_db_password = "your-staging-db-password"
prod_db_password = "your-prod-db-password"

# Environment variables for your application
staging_env_vars = {
  NODE_ENV = "staging"
  # Add your staging environment variables here
}

prod_env_vars = {
  NODE_ENV = "production"
  # Add your production environment variables here
}
```

### 2. Deploy Infrastructure

```bash
# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Deploy the infrastructure
terraform apply
```

### 3. Get Your API URLs

After deployment, run:
```bash
terraform output
```

You'll get URLs like:
- **Staging API**: `http://1.2.3.4:5000`
- **Production API**: `http://5.6.7.8:5000`

## 🔄 Automatic Updates

**Watchtower** automatically:
- Polls ECR every 5 minutes for new images
- Pulls and deploys the latest `:prod` or `:latest` tag
- Cleans up old container images
- Restarts containers if they stop

### Manual Container Management

SSH into your instances to manage containers:
```bash
# Connect to staging
ssh -i ~/.ssh/your-key.pem ec2-user@<staging-ip>

# Connect to production  
ssh -i ~/.ssh/your-key.pem ec2-user@<production-ip>

# View running containers
docker ps

# View logs
docker logs sttf-api-staging
docker logs sttf-api-prod

# Restart containers
docker-compose restart

# Update to latest image manually
docker-compose pull && docker-compose up -d
```

## 🔐 Environment Variables & Secrets Management

All sensitive environment variables are stored securely in **AWS Secrets Manager**:

- **Staging secrets**: `SttfApiStagingContainerSecrets-v2`
- **Production secrets**: `SttfApiProdContainerSecrets-v2`

### What's Stored in Secrets Manager:
- Database credentials (host, port, username, password)
- Application secrets (encryption keys, session secrets)
- Third-party API keys (Firebase, Whoop, Sentry)
- Frontend URLs

### How It Works:
1. **Terraform** creates secrets in AWS Secrets Manager
2. **EC2 instances** retrieve secrets at startup using IAM roles
3. **Docker containers** use the secrets as environment variables
4. **Secrets are encrypted** at rest and in transit

### Updating Secrets:
```bash
# Update secrets in terraform.tfvars
# Then run:
terraform apply
```

## 🔒 Security

- **EC2 instances** are in public subnets but protected by security groups
- **RDS databases** are accessible only from EC2 instances
- **Port 5000** is open for API access
- **Port 22** is open for SSH access (optional)
- **AWS Secrets Manager** stores all sensitive environment variables securely
- **IAM roles** provide least-privilege access to ECR and Secrets Manager

## 🏥 Health Checks

Each instance includes a health check script:
```bash
# On the instance
./health_check.sh
```

Test your APIs:
```bash
# Staging health check
curl http://<staging-ip>:5000/health

# Production health check
curl http://<production-ip>:5000/health
```

## 🧹 Cleanup

To remove all resources:
```bash
terraform destroy
```

## 📝 Notes

- **No Load Balancer**: Direct access to EC2 instances via public IPs
- **No NAT Gateway**: Significant cost savings (~$45/month)
- **Automatic Updates**: Watchtower handles container updates
- **Simple Architecture**: Easy to understand and maintain
- **Cost Effective**: ~60% cheaper than ALB-based setup

## 🔧 Troubleshooting

### Container Not Starting
1. Check logs: `docker logs sttf-api-staging`
2. Verify environment variables: `cat .env`
3. Check database connectivity
4. Ensure ECR login is working

### Watchtower Not Updating
1. Check watchtower logs: `docker logs watchtower-staging`
2. Verify ECR permissions
3. Check if new images are being pushed to ECR

### Database Connection Issues
1. Verify security groups allow port 5432
2. Check database endpoint and credentials
3. Ensure RDS instances are running