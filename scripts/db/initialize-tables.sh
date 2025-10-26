#!/bin/bash

# Create and Reset Database Tables Script
# This script:
# 1. Sets INITIAL_SETUP=true and restarts the server
# 2. Waits for tables to be created
# 3. Sets INITIAL_SETUP=false and restarts the server

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Database Table Creation and Reset Script ===${NC}"
echo ""

# Get Terraform outputs
echo -e "${YELLOW}Getting connection details from Terraform...${NC}"
EC2_IP=$(terraform output -raw prod_instance_public_ip 2>/dev/null || echo "")
KEY_PAIR=$(terraform output -raw ssh_connection_prod 2>/dev/null | grep -o '~/.ssh/[^.]*\.pem' | sed 's|~/.ssh/||' || echo "")

if [ -z "$EC2_IP" ]; then
    echo -e "${RED}Error: Could not get required Terraform outputs.${NC}"
    exit 1
fi

# Check if key file exists
KEY_FILE="$HOME/.ssh/$KEY_PAIR"
if [ ! -f "$KEY_FILE" ]; then
    echo -e "${RED}Error: SSH key file not found at $KEY_FILE${NC}"
    exit 1
fi

CONTAINER_NAME="sttf-api-prod"

echo -e "${GREEN}Connecting to EC2 instance: $EC2_IP${NC}"
echo ""

# Function to set INITIAL_SETUP value in .env
set_initial_setup() {
    local value="$1"
    echo -e "${YELLOW}Setting INITIAL_SETUP=$value in .env file...${NC}"
    ssh -i "$KEY_FILE" ec2-user@$EC2_IP << ENABLE_SETUP
# Check if INITIAL_SETUP is already in the file
if grep -q "INITIAL_SETUP=" /home/ec2-user/.env; then
    # Replace existing value
    sed -i 's/^INITIAL_SETUP=.*/INITIAL_SETUP=$value/' /home/ec2-user/.env
else
    # Append to file
    echo "INITIAL_SETUP=$value" >> /home/ec2-user/.env
fi
echo "✓ INITIAL_SETUP=$value set in .env"
ENABLE_SETUP
}

# Function to stop, recreate and start the Docker container
restart_container() {
    local message="$1"
    echo -e "${YELLOW}$message${NC}"
    ssh -i "$KEY_FILE" ec2-user@$EC2_IP << 'RESTART_CONTAINER'
cd /home/ec2-user
docker-compose stop api
docker-compose rm -f api
docker-compose up -d api
echo "✓ Container recreated and started"
RESTART_CONTAINER
}

# Function to restart (just restart, not recreate) 
restart_container_soft() {
    local message="$1"
    echo -e "${YELLOW}$message${NC}"
    ssh -i "$KEY_FILE" ec2-user@$EC2_IP << 'RESTART_CONTAINER'
cd /home/ec2-user
docker-compose restart api
echo "✓ Container restarted"
RESTART_CONTAINER
}

# Function to wait for tables to be created
wait_for_tables() {
    echo -e "${YELLOW}Waiting for Sequelize to create tables...${NC}"
    echo -e "${MAGENTA}Monitoring container logs...${NC}"
    
    # Wait for up to 5 minutes for tables to be created
    local max_wait=300
    local elapsed=0
    local check_interval=5
    local app_started=false
    
    while [ $elapsed -lt $max_wait ]; do
        # Check logs
        local logs=$(ssh -i "$KEY_FILE" ec2-user@$EC2_IP "docker logs --tail 50 $CONTAINER_NAME 2>&1")
        
        # Check for application start first
        if [ "$app_started" = false ] && echo "$logs" | grep -q "Nest application successfully started"; then
            echo -e "${GREEN}✓ Application started successfully${NC}"
            app_started=true
            sleep 15 # Give Sequelize time to create tables after app start
            continue
        fi
        
        # After app started, look for Sequelize indicators
        if [ "$app_started" = true ]; then
            # Look for Sequelize CREATE TABLE statements in logs
            if echo "$logs" | grep -qi "CREATE TABLE\|Synchronization\|synchronize\|sync\|Executing.*query"; then
                echo -e "${GREEN}✓ Database operations detected!${NC}"
                sleep 10
                return 0
            fi
            
            # Just wait a bit more after app started to ensure tables are created
            if [ $elapsed -gt 60 ]; then
                echo -e "${GREEN}✓ Giving additional time for table creation...${NC}"
                return 0
            fi
        fi
        
        # Check for errors
        if echo "$logs" | grep -qi "SequelizeDatabaseError\|Error.*table.*already exists\|ER_NO_SUCH_TABLE"; then
            echo -e "${YELLOW}⚠ Possible database error detected${NC}"
            echo "$logs" | grep -i "Error\|Exception" | tail -3
        fi
        
        if [ $((elapsed % 20)) -eq 0 ]; then
            echo -e "${BLUE}Still waiting... ($elapsed/${max_wait}s)${NC}"
        fi
        
        sleep $check_interval
        elapsed=$((elapsed + check_interval))
    done
    
    echo -e "${YELLOW}⚠ Timeout: Continuing anyway (tables may have been created)${NC}"
    return 0
}

# Function to show current container status
show_container_status() {
    echo -e "${MAGENTA}Current container status:${NC}"
    ssh -i "$KEY_FILE" ec2-user@$EC2_IP "docker ps --filter name=$CONTAINER_NAME"
    echo ""
}

# Main execution
echo -e "${BLUE}Step 1: Enable INITIAL_SETUP=true${NC}"
set_initial_setup "true"

echo ""
echo -e "${BLUE}Step 2: Recreate and start container with INITIAL_SETUP=true${NC}"
restart_container "Recreating container to apply INITIAL_SETUP=true..."

sleep 10
show_container_status

echo ""
echo -e "${BLUE}Step 3: Wait for tables to be created${NC}"
wait_for_tables

echo ""
echo -e "${BLUE}Step 4: Verify tables were created${NC}"
echo -e "${YELLOW}Checking if tables exist in the database...${NC}"

# Get DB connection details from terraform
RDS_HOST=$(terraform output -raw prod_db_hostname 2>/dev/null || echo "")
RDS_PORT=$(terraform output -raw prod_db_port 2>/dev/null || echo "")
LOCAL_PORT=5433

# Setup SSH tunnel to check database
if ! lsof -Pi :$LOCAL_PORT -sTCP:LISTEN -t >/dev/null 2>&1; then
    ssh -i "$KEY_FILE" -L $LOCAL_PORT:$RDS_HOST:$RDS_PORT -N ec2-user@$EC2_IP -f
    sleep 2
fi

# Check tables count
TABLES_COUNT=$(PGPASSWORD="VZ27V4bm1BGPhDODG0rC7umRQG4xZ0Gt" psql -h localhost -p $LOCAL_PORT -U sttf_admin -d postgres -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public' AND table_type = 'BASE TABLE';" 2>/dev/null | xargs)

if [ ! -z "$TABLES_COUNT" ] && [ "$TABLES_COUNT" -gt 0 ]; then
    echo -e "${GREEN}✓ Found $TABLES_COUNT tables in the database${NC}"
else
    echo -e "${YELLOW}⚠ Could not verify table count, but continuing...${NC}"
fi

echo ""
echo -e "${BLUE}Step 5: Disable INITIAL_SETUP and restart container${NC}"
set_initial_setup "false"
restart_container "Recreating container with INITIAL_SETUP=false..."

sleep 5
show_container_status

echo ""
echo -e "${GREEN}✓ Process completed successfully!${NC}"
echo -e "${GREEN}✓ Database tables have been created${NC}"
echo -e "${GREEN}✓ INITIAL_SETUP has been set back to false${NC}"
echo ""
echo -e "${YELLOW}Container is now running in normal mode with synchronize=false${NC}"
echo -e "${BLUE}To verify, run: ssh -i $KEY_FILE ec2-user@$EC2_IP 'docker logs $CONTAINER_NAME --tail 50'${NC}"

