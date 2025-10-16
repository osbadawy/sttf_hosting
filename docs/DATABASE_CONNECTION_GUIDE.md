# Database Connection Guide for VS Code Database Client JDBC Plugin

This guide explains how to connect to your RDS PostgreSQL database using the Database Client JDBC plugin in VS Code through an SSH tunnel.

## Prerequisites

1. **Database Client JDBC Plugin**: Install the "Database Client JDBC" extension in VS Code
2. **SSH Key**: Ensure you have the correct SSH key file for your EC2 instance
3. **Terraform Applied**: Make sure your Terraform configuration has been applied

## Step 1: Get Your Database Connection Details

First, get the necessary information from your Terraform outputs:

```bash
cd /home/amitn/cov/sttf_hosting
terraform output
```

You'll need:
- `prod_instance_public_ip`: Your EC2 instance's public IP
- `prod_db_host`: Your RDS endpoint
- `prod_db_port`: Your RDS port (should be 5432)
- `prod_db_name`: Your database name (sttf_api_prod)

## Step 2: Create SSH Tunnel

### Option A: Use the Provided Script (Recommended)

```bash
./connect-to-rds.sh
```

This script will:
- Automatically get the connection details from Terraform
- Create an SSH tunnel from localhost:5433 to your RDS instance
- Display the connection information

### Option B: Manual SSH Tunnel

If you prefer to create the tunnel manually:

```bash
ssh -i ~/.ssh/YOUR_KEY_PAIR.pem -L 5433:RDS_ENDPOINT:5432 ec2-user@EC2_PUBLIC_IP
```

Replace:
- `YOUR_KEY_PAIR.pem` with your actual SSH key filename
- `RDS_ENDPOINT` with your RDS endpoint from Terraform output
- `EC2_PUBLIC_IP` with your EC2 public IP from Terraform output

## Step 3: Configure Database Client in VS Code

1. **Open Database Client**: In VS Code, open the Database Client panel (usually in the sidebar)

2. **Add New Connection**: Click the "+" button to add a new connection

3. **Select Database Type**: Choose "PostgreSQL"

4. **Configure Connection**:
   - **Host**: `localhost`
   - **Port**: `5433` (or whatever local port you used)
   - **Database**: `sttf_api_prod`
   - **Username**: `sttf_admin`
   - **Password**: [Your database password from Terraform variables]

5. **Test Connection**: Click "Test Connection" to verify everything works

6. **Save Connection**: Give your connection a name and save it

## Step 4: Connect and Use

Once the SSH tunnel is established and the connection is configured:

1. **Start the SSH tunnel** (if not already running):
   ```bash
   ./connect-to-rds.sh
   ```

2. **Connect in VS Code**: Click on your saved connection in the Database Client panel

3. **Browse your database**: You can now explore tables, run queries, and manage your database

## Important Notes

### Security
- The SSH tunnel encrypts your database connection
- Your RDS instance remains private and only accessible through the EC2 instance
- Always use strong passwords and keep your SSH keys secure

### Troubleshooting

**Connection Refused**:
- Ensure the SSH tunnel is running
- Check that the EC2 instance is running
- Verify your SSH key has the correct permissions: `chmod 600 ~/.ssh/YOUR_KEY.pem`

**Authentication Failed**:
- Verify the database username and password
- Check that the database name is correct

**Port Already in Use**:
- The script will warn you if port 5433 is already in use
- You can kill the existing process: `kill $(lsof -ti:5433)`
- Or modify the script to use a different port

**Terraform Outputs Not Found**:
- Make sure you're in the correct directory (`/home/amitn/cov/sttf_hosting`)
- Ensure Terraform has been applied: `terraform apply`

### Alternative Ports

If port 5433 conflicts with your local setup, you can modify the script to use a different port:

```bash
# Edit the script and change LOCAL_PORT=5433 to LOCAL_PORT=5434 (or any available port)
# Then update your VS Code connection to use the new port
```

## Connection String Reference

For reference, here's the connection string format:
```
postgresql://sttf_admin:PASSWORD@localhost:5433/sttf_api_prod
```

## Stopping the Tunnel

To stop the SSH tunnel, press `Ctrl+C` in the terminal where the tunnel is running, or find the process and kill it:

```bash
# Find the process
ps aux | grep ssh

# Kill the specific tunnel process
kill <process_id>
```

## Next Steps

Once connected, you can:
- Browse your database schema
- Run SQL queries
- Export/import data
- Monitor database performance
- Manage users and permissions

Happy database exploring! 🚀
