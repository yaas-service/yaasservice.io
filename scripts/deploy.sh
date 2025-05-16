#!/bin/bash

# ===============================
# YaaS Service Full Deployment Script
# Author: YaaS Service Team
# ===============================

# Variables
CLOUDFLARE_API_TOKEN="mxdkYG5J1HsVXR36FcXVcwf42f6k7EGkU7WAu0bC"
DOMAIN="yaasservice.io"
CF_ZONE_ID="a44048aba7521e90edbddbae88f94d89" # Retrieved from Cloudflare API
DOCKER_IMAGE="yaas_docker_deployment-yaas-service"
DOCKER_TAG="latest"
DOCKER_REGISTRY="localhost:5000"
IP_ADDRESS="76.76.21.21"

# Colors for readability
GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo -e "${GREEN}🔍 Fetching DNS Record ID...${NC}"
RECORD_ID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/${CF_ZONE_ID}/dns_records?type=A&name=${DOMAIN}" \
     -H "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}" \
     -H "Content-Type: application/json" | jq -r '.result[0].id')

if [ -z "$RECORD_ID" ]; then
    echo "DNS Record not found. Creating a new one..."
    RECORD_ID=$(curl -s -X POST "https://api.cloudflare.com/client/v4/zones/${CF_ZONE_ID}/dns_records" \
        -H "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}" \
        -H "Content-Type: application/json" \
        --data '{"type":"A","name":"yaasservice.io","content":"76.76.21.21","ttl":1,"proxied":false}' | jq -r '.result.id')
fi

echo -e "${GREEN}🌐 Cloudflare Record ID: ${RECORD_ID}${NC}"

# ===============================
# Docker Deployment
# ===============================

echo -e "${GREEN}🐳 Stopping and Pruning Docker containers...${NC}"
docker-compose down
docker system prune -af

echo -e "${GREEN}🚀 Building Docker Image...${NC}"
docker-compose build --no-cache

echo -e "${GREEN}🛰️ Tagging Docker Image...${NC}"
docker tag ${DOCKER_IMAGE}:${DOCKER_TAG} ${DOCKER_REGISTRY}/${DOCKER_IMAGE}:${DOCKER_TAG}

echo -e "${GREEN}📡 Pushing Docker Image to Local Registry...${NC}"
docker push ${DOCKER_REGISTRY}/${DOCKER_IMAGE}:${DOCKER_TAG}

echo -e "${GREEN}🌐 Starting Docker Compose...${NC}"
docker-compose up -d

# ===============================
# Cloudflare DNS Update
# ===============================
echo -e "${GREEN}🔄 Updating Cloudflare DNS Record...${NC}"
curl -X PUT "https://api.cloudflare.com/client/v4/zones/${CF_ZONE_ID}/dns_records/${RECORD_ID}" \
     -H "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}" \
     -H "Content-Type: application/json" \
     --data '{"type":"A","name":"yaasservice.io","content":"'${IP_ADDRESS}'","ttl":1,"proxied":false}'

echo -e "${GREEN}✅ Deployment Complete! YaaS Service is Live.${NC}"
echo -e "${GREEN}🌐 Visit: http://yaasservice.io${NC}"

