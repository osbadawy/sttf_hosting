#!/bin/bash

# Update system
yum update -y

# Install Docker
yum install -y docker
systemctl start docker
systemctl enable docker
usermod -a -G docker ec2-user

# Install AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install

# Configure AWS CLI
aws configure set region ${aws_region}

# Login to ECR
aws ecr get-login-password --region ${aws_region} | docker login --username AWS --password-stdin ${ecr_repository_url}

# Pull and run the :prod image
docker pull ${ecr_repository_url}:prod
docker run -d -p 80:80 --name sttf-api-prod ${ecr_repository_url}:prod

# Create a simple health check
echo "#!/bin/bash" > /home/ec2-user/health_check.sh
echo "curl -f http://localhost:80/health || exit 1" >> /home/ec2-user/health_check.sh
chmod +x /home/ec2-user/health_check.sh

# Add to crontab for periodic health checks
echo "*/5 * * * * /home/ec2-user/health_check.sh" | crontab -u ec2-user -
