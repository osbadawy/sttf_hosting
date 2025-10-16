# ECR Credential Helper for Watchtower

This directory contains the necessary files to set up AWS ECR authentication for Watchtower using the official credential helper approach.

## Files

- `Dockerfile` - Builds the AWS ECR credential helper (`docker-credential-ecr-login`)
- `setup-ecr-helper.sh` - Script to build and configure the ECR credential helper
- `docker-compose-watchtower.yml` - Docker Compose configuration for Watchtower with ECR support

## How it Works

The ECR credential helper automatically handles AWS ECR authentication by:

1. **Building the Helper**: Creates a Docker image with the `docker-credential-ecr-login` binary
2. **Storing in Volume**: Places the credential helper binary in a Docker volume named `helper`
3. **Configuring Docker**: Sets up Docker config to use the ECR credential helper
4. **Mounting in Watchtower**: Watchtower container mounts the credential helper and config

## Automatic Setup

The ECR credential helper is automatically set up during EC2 instance initialization via the user data scripts:

- `user_data_prod.sh` - Sets up ECR credential helper for production
- `user_data_staging.sh` - Sets up ECR credential helper for staging

## Manual Setup

If you need to set up the ECR credential helper manually:

```bash
# Run the setup script
./setup-ecr-helper.sh

# Start Watchtower with ECR support
docker-compose -f docker-compose-watchtower.yml up -d
```

## Testing

Test the setup by manually triggering Watchtower:

```bash
docker-compose -f docker-compose-watchtower.yml run --rm watchtower sttf-api-prod --run-once
```

You should see no "no basic auth credentials" errors if the setup is working correctly.

## Troubleshooting

If you encounter authentication issues:

1. Check that the `helper` volume exists: `docker volume ls | grep helper`
2. Verify the Docker config: `cat /home/ec2-user/.docker/config.json`
3. Check Watchtower logs: `docker logs watchtower-prod-ecr`

## References

- [Watchtower Private Registries Documentation](https://containrrr.dev/watchtower/private-registries/#credential_helpers)
- [AWS ECR Credential Helper](https://github.com/awslabs/amazon-ecr-credential-helper)
