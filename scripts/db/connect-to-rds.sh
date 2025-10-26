#!/bin/bash

# SSH Tunnel Script for RDS Database Connection
# This script creates an SSH tunnel through your EC2 instance to access the RDS database

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== RDS SSH Tunnel Setup ===${NC}"

# Check if required tools are installed
if ! command -v ssh &> /dev/null; then
    echo -e "${RED}Error: SSH is not installed or not in PATH${NC}"
    exit 1
fi

if ! command -v terraform &> /dev/null; then
    echo -e "${RED}Error: Terraform is not installed or not in PATH${NC}"
    exit 1
fi

# Get Terraform outputs
echo -e "${YELLOW}Getting Terraform outputs...${NC}"
EC2_IP=$(terraform output -raw prod_instance_public_ip 2>/dev/null || echo "")
RDS_HOST=$(terraform output -raw prod_db_hostname 2>/dev/null || echo "")
RDS_PORT=$(terraform output -raw prod_db_port 2>/dev/null || echo "")
KEY_PAIR=$(terraform output -raw ssh_connection_prod 2>/dev/null | grep -o '~/.ssh/[^.]*\.pem' | sed 's|~/.ssh/||' || echo "")

if [ -z "$EC2_IP" ] || [ -z "$RDS_HOST" ] || [ -z "$RDS_PORT" ]; then
    echo -e "${RED}Error: Could not get required Terraform outputs. Make sure you're in the correct directory and Terraform has been applied.${NC}"
    exit 1
fi

# Check if key file exists
KEY_FILE="$HOME/.ssh/$KEY_PAIR"
if [ ! -f "$KEY_FILE" ]; then
    echo -e "${RED}Error: SSH key file not found at $KEY_FILE${NC}"
    echo -e "${YELLOW}Please ensure your SSH key is in the correct location.${NC}"
    exit 1
fi

# Set local port for tunnel (use 5433 to avoid conflicts with local PostgreSQL)
LOCAL_PORT=5433

echo -e "${GREEN}Configuration:${NC}"
echo -e "  EC2 Instance: $EC2_IP"
echo -e "  RDS Host: $RDS_HOST"
echo -e "  RDS Port: $RDS_PORT"
echo -e "  Local Port: $LOCAL_PORT"
echo -e "  SSH Key: $KEY_FILE"
echo ""

# Check if local port is already in use
if lsof -Pi :$LOCAL_PORT -sTCP:LISTEN -t >/dev/null 2>&1; then
    echo -e "${YELLOW}Warning: Port $LOCAL_PORT is already in use.${NC}"
    echo -e "${YELLOW}You may need to stop the existing process or choose a different port.${NC}"
    echo -e "${YELLOW}To stop the existing process: kill \$(lsof -ti:$LOCAL_PORT)${NC}"
    echo ""
    read -p "Do you want to continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo -e "${YELLOW}Creating SSH tunnel...${NC}"
echo -e "${BLUE}Command: ssh -i $KEY_FILE -L $LOCAL_PORT:$RDS_HOST:$RDS_PORT -N ec2-user@$EC2_IP${NC}"
echo ""
echo -e "${GREEN}SSH tunnel established!${NC}"
echo -e "${GREEN}You can now connect to your RDS database using:${NC}"
echo -e "  Host: localhost"
echo -e "  Port: $LOCAL_PORT"
echo -e "  Database: postgres"
echo -e "  Username: sttf_admin"
echo -e "  Password: [from your Terraform variables]"
echo ""
echo -e "${YELLOW}Press Ctrl+C to stop the tunnel${NC}"

# Create the SSH tunnel
ssh -i "$KEY_FILE" -L $LOCAL_PORT:$RDS_HOST:$RDS_PORT -N ec2-user@$EC2_IP
