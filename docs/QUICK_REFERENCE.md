# Quick Reference: SSH Tunnel + Database Connection

## SSH Tunnel Settings (VS Code Database Client)
```
Enable: ON
Host: 63.180.45.110
Username: ec2-user
Auth: Key
Private Key Path: /home/amitn/.ssh/EC2Staging.pem
Port: 22
Connect Timeout: 5000ms
```

## Database Connection Settings
```
Host: localhost
Port: 5433
Database: sttf_api_prod
Username: sttf_admin
Password: [from Terraform variables]
```

## RDS Details (for reference)
```
RDS Endpoint: sttf-api-prod-db.czsuc4ms8v8w.eu-central-1.rds.amazonaws.com
RDS Port: 5432
EC2 Public IP: 63.180.45.110
SSH Key: EC2Staging.pem
```

## Steps:
1. Configure SSH tunnel with the settings above
2. Click "Connect" to establish the tunnel
3. Configure database connection with localhost:5433
4. Test the database connection
