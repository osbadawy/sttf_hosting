#!/bin/bash

# SSL Certificate Deployment Script
# This script copies SSL certificates to the EC2 instance

set -e

# Configuration
EC2_IP="63.180.45.110"  # Update this with your actual EC2 IP
KEY_PATH="~/.ssh/EC2Prod"  # Update this with your actual key path
USER="ec2-user"

# SSL certificate files
CERT_FILE="ssl/cloudflare-origin-fullchain.pem"
KEY_FILE="ssl/cloudflare-origin.key"

# Check if certificate files exist
if [ ! -f "$CERT_FILE" ]; then
    echo "Error: Certificate file $CERT_FILE not found!"
    exit 1
fi

if [ ! -f "$KEY_FILE" ]; then
    echo "Error: Private key file $KEY_FILE not found!"
    exit 1
fi

echo "Deploying SSL certificates to EC2 instance..."

# Copy certificate file
echo "Copying certificate file..."
scp -i "$KEY_PATH" "$CERT_FILE" "$USER@$EC2_IP:/home/$USER/ssl/sttf.api.crt"

# Copy private key file
echo "Copying private key file..."
scp -i "$KEY_PATH" "$KEY_FILE" "$USER@$EC2_IP:/home/$USER/ssl/sttf.api.key"

# Set proper permissions on the remote server
echo "Setting proper permissions..."
ssh -i "$KEY_PATH" "$USER@$EC2_IP" "sudo chmod 600 /home/$USER/ssl/sttf.api.key && sudo chmod 644 /home/$USER/ssl/sttf.api.crt && sudo chown -R $USER:$USER /home/$USER/ssl"

# Restart the Docker container to pick up the new certificates
echo "Restarting Docker container..."
ssh -i "$KEY_PATH" "$USER@$EC2_IP" "cd /home/$USER && docker-compose restart api"

echo "SSL certificates deployed successfully!"
echo "Your API should now be available at: https://sttf.api"
