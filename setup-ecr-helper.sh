#!/bin/bash

# Script to set up ECR credential helper for Watchtower
# This script builds the ECR credential helper and creates the necessary Docker volume

set -e

echo "🔧 Setting up ECR credential helper for Watchtower..."

# Create helper volume
docker volume create helper
echo "✅ Created helper volume"

# Build ECR credential helper image
echo "🏗️ Building ECR credential helper..."
docker build -f ecr-credential-helper/Dockerfile -t aws-ecr-dock-cred-helper ecr-credential-helper/

# Build the credential helper command and store it in the volume
echo "📦 Building credential helper command..."
docker run -d --rm --name aws-cred-helper --volume helper:/go/bin aws-ecr-dock-cred-helper

# Wait for the build to complete
sleep 5

# Clean up the build container
docker stop aws-cred-helper 2>/dev/null || true

echo "✅ ECR credential helper setup complete!"
