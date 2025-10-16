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

# Install AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install

# Configure AWS CLI
aws configure set region ${aws_region}

# Login to ECR
aws ecr get-login-password --region ${aws_region} | docker login --username AWS --password-stdin ${ecr_repository_url}

# Create environment file from Secrets Manager
aws secretsmanager get-secret-value --secret-id ${secrets_arn} --region ${aws_region} --query SecretString --output text | jq -r 'to_entries[] | "\(.key)=\(.value)"' > /home/ec2-user/.env

# Create docker-compose file with watchtower
cat > /home/ec2-user/docker-compose.yml << EOF
version: '3.8'

services:
  api:
    image: ${ecr_repository_url}:latest
    container_name: sttf-api-staging
    restart: unless-stopped
    ports:
      - "5000:5000"
    env_file:
      - .env
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:5000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

  watchtower:
    image: containrrr/watchtower
    container_name: watchtower-staging
    restart: unless-stopped
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    environment:
      - WATCHTOWER_POLL_INTERVAL=300
      - WATCHTOWER_CLEANUP=true
      - WATCHTOWER_INCLUDE_STOPPED=true
      - WATCHTOWER_REVIVE_STOPPED=true
    command: sttf-api-staging
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
response=$$(curl -s -o /dev/null -w "%%{http_code}" http://localhost:5000/health)
if [ $response -eq 200 ]; then
    echo "API is healthy"
    exit 0
else
    echo "API is unhealthy (HTTP $response)"
    exit 1
fi
EOF

chmod +x /home/ec2-user/health_check.sh
chown ec2-user:ec2-user /home/ec2-user/health_check.sh