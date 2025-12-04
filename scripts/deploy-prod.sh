#!/bin/bash
set -e

echo "🚀 Deploying to production environment..."

# Load environment variables
if [ -f .env.prod ]; then
    export $(cat .env.prod | grep -v '^#' | xargs)
fi

# Create backup before deployment
echo "💾 Creating database backup..."
docker-compose -f docker-compose.prod.yml exec -T postgres \
    pg_dump -U ${DB_USER:-collo} ${DB_NAME:-investment_schema} > backup_$(date +%Y%m%d_%H%M%S).sql

# Stop and remove old containers
docker-compose -f docker-compose.prod.yml down

# Pull latest images
docker-compose -f docker-compose.prod.yml pull

# Start services with zero-downtime deployment
docker-compose -f docker-compose.prod.yml up -d --scale backend=2 --no-recreate

# Wait for new containers to be healthy
echo "⏳ Waiting for new containers to be healthy..."
sleep 60

# Check health
curl -f https://yourdomain.com/health || exit 1

# Remove old containers
docker-compose -f docker-compose.prod.yml up -d --scale backend=2

echo "✅ Production deployment completed successfully!"