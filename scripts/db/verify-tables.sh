#!/bin/bash

# Verify Database Tables Script
# This script checks if tables exist in the production database

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Database Tables Verification ===${NC}"
echo ""

# Get Terraform outputs
EC2_IP=$(terraform output -raw prod_instance_public_ip 2>/dev/null || echo "")
KEY_PAIR=$(terraform output -raw ssh_connection_prod 2>/dev/null | grep -o '~/.ssh/[^.]*\.pem' | sed 's|~/.ssh/||' || echo "")
RDS_HOST=$(terraform output -raw prod_db_hostname 2>/dev/null || echo "")
RDS_PORT=$(terraform output -raw prod_db_port 2>/dev/null || echo "")

if [ -z "$EC2_IP" ] || [ -z "$RDS_HOST" ]; then
    echo -e "${RED}Error: Could not get required Terraform outputs.${NC}"
    exit 1
fi

KEY_FILE="$HOME/.ssh/$KEY_PAIR"
LOCAL_PORT=5433
PROD_DB_PASSWORD="VZ27V4bm1BGPhDODG0rC7umRQG4xZ0Gt"

# Setup SSH tunnel
echo -e "${YELLOW}Setting up SSH tunnel...${NC}"
if lsof -Pi :$LOCAL_PORT -sTCP:LISTEN -t >/dev/null 2>&1; then
    echo -e "${GREEN}SSH tunnel already running on port $LOCAL_PORT${NC}"
else
    ssh -i "$KEY_FILE" -L $LOCAL_PORT:$RDS_HOST:$RDS_PORT -N ec2-user@$EC2_IP -f
    sleep 2
    echo -e "${GREEN}SSH tunnel established${NC}"
fi

echo ""
echo -e "${BLUE}Checking database tables...${NC}"

# Count tables
TABLES_COUNT=$(PGPASSWORD="$PROD_DB_PASSWORD" psql -h localhost -p $LOCAL_PORT -U sttf_admin -d postgres -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public' AND table_type = 'BASE TABLE';" 2>/dev/null | xargs)

echo -e "${YELLOW}Total tables: $TABLES_COUNT${NC}"
echo ""

if [ -z "$TABLES_COUNT" ] || [ "$TABLES_COUNT" -eq 0 ]; then
    echo -e "${RED}✗ No tables found in the database${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Tables found: $TABLES_COUNT${NC}"
echo ""

# List table names
echo -e "${BLUE}Table names:${NC}"
PGPASSWORD="$PROD_DB_PASSWORD" psql -h localhost -p $LOCAL_PORT -U sttf_admin -d postgres -c "SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' AND table_type = 'BASE TABLE' ORDER BY table_name;" 2>/dev/null

echo ""
echo -e "${GREEN}✓ Database verification complete!${NC}"

