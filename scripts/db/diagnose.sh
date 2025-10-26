#!/bin/bash

# Diagnostic script to troubleshoot table creation issues

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Diagnostics Script ===${NC}"
echo ""

# Get Terraform outputs
EC2_IP=$(terraform output -raw prod_instance_public_ip 2>/dev/null || echo "")
KEY_PAIR=$(terraform output -raw ssh_connection_prod 2>/dev/null | grep -o '~/.ssh/[^.]*\.pem' | sed 's|~/.ssh/||' || echo "")

if [ -z "$EC2_IP" ]; then
    echo -e "${RED}Error: Could not get Terraform outputs${NC}"
    exit 1
fi

KEY_FILE="$HOME/.ssh/$KEY_PAIR"
CONTAINER_NAME="sttf-api-prod"

echo -e "${YELLOW}1. Checking container status...${NC}"
ssh -i "$KEY_FILE" ec2-user@$EC2_IP "docker ps -a | grep $CONTAINER_NAME"
echo ""

echo -e "${YELLOW}2. Checking INITIAL_SETUP value in .env...${NC}"
ssh -i "$KEY_FILE" ec2-user@$EC2_IP "grep -i INITIAL_SETUP /home/ec2-user/.env || echo 'INITIAL_SETUP not found in .env'"
echo ""

echo -e "${YELLOW}3. Checking recent container logs (last 100 lines)...${NC}"
ssh -i "$KEY_FILE" ec2-user@$EC2_IP "docker logs $CONTAINER_NAME --tail 100"
echo ""

echo -e "${YELLOW}4. Checking if database connection works from container...${NC}"
ssh -i "$KEY_FILE" ec2-user@$EC2_IP "docker exec $CONTAINER_NAME env | grep -i postgres || echo 'No postgres env vars found'"
echo ""

echo -e "${YELLOW}5. Checking Sequelize/TypeORM sync settings...${NC}"
ssh -i "$KEY_FILE" ec2-user@$EC2_IP "docker exec $CONTAINER_NAME sh -c 'grep -i synchronize /app/dist/app.module.js 2>/dev/null || echo \"Cannot check code\"'"
echo ""

echo -e "${BLUE}=== Diagnostics Complete ===${NC}"

