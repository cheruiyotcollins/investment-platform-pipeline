#!/bin/bash
set -e

echo "🚀 Deploying to staging environment..."

# Load environment variables
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

# Stop and remove old containers
docker-compose -f docker-compose.staging.yml down

# Pull latest images
docker-compose -f docker-compose.staging.yml pull

# Start services
docker-compose -f docker-compose.staging.yml up -d

# Wait for services to start
echo "⏳ Waiting for services to start..."
sleep 30

# Run health checks
echo "🏥 Running health checks..."
docker-compose -f docker-compose.staging.yml ps
curl -f http://localhost:9002/actuator/health || exit 1
curl -f http://localhost:8080 || exit 1

echo "✅ Staging deployment completed successfully!"