#!/bin/bash

# Reset Database Tables Script
# This script connects to the RDS database via SSH tunnel and drops all tables
# WARNING: This will delete all data in the database

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${RED}⚠️  WARNING: This will DELETE ALL DATA in the database! ⚠️${NC}"
echo -e "${RED}This operation CANNOT be undone!${NC}"
echo ""
read -p "Type 'RESET' to confirm you want to proceed: " confirmation

if [ "$confirmation" != "RESET" ]; then
    echo -e "${YELLOW}Operation cancelled.${NC}"
    exit 1
fi

echo -e "${BLUE}=== Getting Database Connection Details ===${NC}"

# Get Terraform outputs
RDS_HOST=$(terraform output -raw prod_db_hostname 2>/dev/null || echo "")
RDS_PORT=$(terraform output -raw prod_db_port 2>/dev/null || echo "")
EC2_IP=$(terraform output -raw prod_instance_public_ip 2>/dev/null || echo "")
KEY_PAIR=$(terraform output -raw ssh_connection_prod 2>/dev/null | grep -o '~/.ssh/[^.]*\.pem' | sed 's|~/.ssh/||' || echo "")

if [ -z "$RDS_HOST" ] || [ -z "$RDS_PORT" ] || [ -z "$EC2_IP" ]; then
    echo -e "${RED}Error: Could not get required Terraform outputs.${NC}"
    exit 1
fi

# Check if key file exists
KEY_FILE="$HOME/.ssh/$KEY_PAIR"
if [ ! -f "$KEY_FILE" ]; then
    echo -e "${RED}Error: SSH key file not found at $KEY_FILE${NC}"
    exit 1
fi

# Set local port for tunnel
LOCAL_PORT=5433
DB_NAME="postgres"  # Default postgres database
DB_USER="sttf_admin"

# Get password from terraform.tfvars
PROD_DB_PASSWORD="VZ27V4bm1BGPhDODG0rC7umRQG4xZ0Gt"

echo -e "${GREEN}Setting up SSH tunnel...${NC}"
echo -e "  RDS Host: $RDS_HOST"
echo -e "  RDS Port: $RDS_PORT"
echo -e "  Local Port: $LOCAL_PORT"
echo ""

# Check if SSH tunnel is already running
if lsof -Pi :$LOCAL_PORT -sTCP:LISTEN -t >/dev/null 2>&1; then
    echo -e "${YELLOW}SSH tunnel on port $LOCAL_PORT is already running. Using existing tunnel.${NC}"
else
    echo -e "${YELLOW}Starting SSH tunnel in background...${NC}"
    ssh -i "$KEY_FILE" -L $LOCAL_PORT:$RDS_HOST:$RDS_PORT -N ec2-user@$EC2_IP -f
    sleep 2
fi

# SQL script to drop all tables
PSQL_COMMAND="
DROP SCHEMA public CASCADE;
CREATE SCHEMA public;
GRANT ALL ON SCHEMA public TO sttf_admin;
GRANT ALL ON SCHEMA public TO public;
"

echo -e "${YELLOW}Executing SQL to drop all tables...${NC}"

# Execute the SQL via local tunnel
PGPASSWORD="$PROD_DB_PASSWORD" psql -h localhost -p $LOCAL_PORT -U "$DB_USER" -d "$DB_NAME" -c "$PSQL_COMMAND"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ All tables have been dropped successfully!${NC}"
    echo ""
    echo -e "${YELLOW}Next steps:${NC}"
    echo -e "1. The tables will be recreated automatically when the application starts with INITIAL_SETUP=true"
    echo -e "2. Or restart your application to let Sequelize sync create the schema"
    echo ""
else
    echo -e "${RED}✗ Error occurred while dropping tables${NC}"
    exit 1
fi

