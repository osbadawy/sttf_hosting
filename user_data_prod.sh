#!/bin/bash

# Update system
yum update -y

# Install Docker
yum install -y docker
systemctl start docker
systemctl enable docker
usermod -a -G docker ec2-user

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

# Install jq for JSON parsing
yum install -y jq

# Install AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install

# Configure AWS CLI
aws configure set region ${aws_region}

# Login to ECR
aws ecr get-login-password --region ${aws_region} | docker login --username AWS --password-stdin ${ecr_repository_url}

# Create ECR credential refresh script for Watchtower
cat > /home/ec2-user/refresh-ecr-credentials.sh << 'EOF'
#!/bin/bash
# Script to refresh ECR credentials for Watchtower
while true; do
    # Refresh ECR login every 10 hours (ECR tokens expire after 12 hours)
    aws ecr get-login-password --region ${aws_region} | docker login --username AWS --password-stdin ${ecr_repository_url}
    
    # Also refresh for ec2-user
    sudo -u ec2-user aws ecr get-login-password --region ${aws_region} | sudo -u ec2-user docker login --username AWS --password-stdin ${ecr_repository_url}
    
    # Wait 10 hours before next refresh
    sleep 36000
done
EOF

# Make the script executable
chmod +x /home/ec2-user/refresh-ecr-credentials.sh

# Start the credential refresh script in background
nohup /home/ec2-user/refresh-ecr-credentials.sh > /home/ec2-user/ecr-refresh.log 2>&1 &

# Also login as ec2-user for Docker Compose
sudo -u ec2-user aws ecr get-login-password --region ${aws_region} | sudo -u ec2-user docker login --username AWS --password-stdin ${ecr_repository_url}

# Create SSL certificates directory
mkdir -p /home/ec2-user/ssl

# Copy SSL certificate files from Terraform directory
# Note: These files should be uploaded to the EC2 instance during deployment
# For now, we'll create placeholder files that will be replaced with actual certificates
cat > /home/ec2-user/ssl/sttf.api.crt << 'EOF'
-----BEGIN CERTIFICATE-----
# SSL certificate will be copied here during deployment
# Placeholder - replace with actual certificate content
-----END CERTIFICATE-----
EOF

cat > /home/ec2-user/ssl/sttf.api.key << 'EOF'
-----BEGIN PRIVATE KEY-----
# SSL private key will be copied here during deployment
# Placeholder - replace with actual private key content
-----END PRIVATE KEY-----
EOF

# Set proper permissions for SSL certificates
chmod 600 /home/ec2-user/ssl/sttf.api.key
chmod 644 /home/ec2-user/ssl/sttf.api.crt
chown -R ec2-user:ec2-user /home/ec2-user/ssl

# Create environment file from Secrets Manager
aws secretsmanager get-secret-value --secret-id ${secrets_arn} --region ${aws_region} --query SecretString --output text | jq -r 'to_entries[] | "\(.key)=\(.value)"' > /home/ec2-user/.env

# Set up ECR credential helper for Watchtower
echo "🔧 Setting up ECR credential helper for Watchtower..."

# Create ECR credential helper Dockerfile
mkdir -p /home/ec2-user/ecr-credential-helper
cat > /home/ec2-user/ecr-credential-helper/Dockerfile << 'EOF'
FROM golang:1.21
ENV GO111MODULE off
ENV CGO_ENABLED 0
ENV REPO github.com/awslabs/amazon-ecr-credential-helper/ecr-login/cli/docker-credential-ecr-login
RUN go get -u $REPO
RUN rm /go/bin/docker-credential-ecr-login
RUN go build \
 -o /go/bin/docker-credential-ecr-login \
 /go/src/$REPO
WORKDIR /go/bin/
EOF

# Create helper volume
docker volume create helper
echo "✅ Created helper volume"

# Build ECR credential helper image
echo "🏗️ Building ECR credential helper..."
docker build -f /home/ec2-user/ecr-credential-helper/Dockerfile -t aws-ecr-dock-cred-helper /home/ec2-user/ecr-credential-helper/

# Build the credential helper command and store it in the volume
echo "📦 Building credential helper command..."
docker run -d --rm --name aws-cred-helper --volume helper:/go/bin aws-ecr-dock-cred-helper

# Wait for the build to complete
sleep 10

# Clean up the build container
docker stop aws-cred-helper 2>/dev/null || true

echo "✅ ECR credential helper setup complete!"

# Create Docker config for ECR credential helper
mkdir -p /home/ec2-user/.docker
cat > /home/ec2-user/.docker/config.json << EOF
{
   "credsStore" : "ecr-login",
   "HttpHeaders" : {
     "User-Agent" : "Docker-Client/19.03.1 (linux)"
   },
   "auths" : {
     "${ecr_repository_url}" : {}
   },
   "credHelpers": {
     "${ecr_repository_url}" : "ecr-login"
   }
}
EOF

# Create docker-compose file with ECR-enabled Watchtower
cat > /home/ec2-user/docker-compose.yml << EOF
services:
  api:
    image: ${ecr_repository_url}:prod
    container_name: sttf-api-prod
    restart: unless-stopped
    ports:
      - "5000:5000"
      - "443:443"
    volumes:
      - /home/ec2-user/ssl:/app/ssl:ro
    env_file:
      - .env
    environment:
      - SSL_CERT_PATH=/app/ssl/sttf.api.crt
      - SSL_KEY_PATH=/app/ssl/sttf.api.key
      - HTTPS_PORT=443
    healthcheck:
      test: ["CMD", "curl", "-f", "https://localhost:443/health", "-k"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

  watchtower:
    image: containrrr/watchtower:latest
    container_name: watchtower-prod-ecr
    restart: unless-stopped
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - /home/ec2-user/.docker/config.json:/config.json
      - helper:/go/bin
    environment:
      - HOME=/
      - PATH=\$PATH:/go/bin
      - AWS_REGION=${aws_region}
      - WATCHTOWER_POLL_INTERVAL=300
      - WATCHTOWER_CLEANUP=true
      - WATCHTOWER_INCLUDE_STOPPED=true
      - WATCHTOWER_REVIVE_STOPPED=true
    command: sttf-api-prod

volumes:
  helper:
    external: true
EOF

# Set proper permissions
chown ec2-user:ec2-user /home/ec2-user/.env
chown ec2-user:ec2-user /home/ec2-user/docker-compose.yml

# Start the application
cd /home/ec2-user
docker-compose up -d

# Create a simple health check script
cat > /home/ec2-user/health_check.sh << 'EOF'
#!/bin/bash
# Test HTTPS endpoint
response=$$(curl -s -o /dev/null -w "%%{http_code}" https://localhost:443/health -k)
if [ $response -eq 200 ]; then
    echo "API is healthy (HTTPS)"
    exit 0
else
    echo "API is unhealthy (HTTPS $response)"
    exit 1
fi
EOF

chmod +x /home/ec2-user/health_check.sh
chown ec2-user:ec2-user /home/ec2-user/health_check.sh