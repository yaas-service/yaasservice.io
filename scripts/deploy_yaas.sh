#!/bin/bash
# deploy_yaas.sh - YaaS Unified Deployment Script

# Colors for better output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Deploying YaaS Service${NC}"

# Deploy to Vercel
echo -e "${BLUE}🚀 Deploying to Vercel...${NC}"
vercel deploy --prod || { 
  echo -e "${RED}❌ Vercel deployment failed${NC}"
  exit 1
}

# Purge Cloudflare cache
echo -e "${BLUE}🧹 Purging Cloudflare cache...${NC}"
CLOUDFLARE_TOKEN="${CLOUDFLARE_TOKEN}"
CLOUDFLARE_ZONE_ID="${CLOUDFLARE_ZONE_ID}"

if [ -z "$CLOUDFLARE_TOKEN" ] || [ -z "$CLOUDFLARE_ZONE_ID" ]; then
  echo -e "${YELLOW}⚠️ Cloudflare credentials not set. Skipping cache purge.${NC}"
  echo -e "${YELLOW}⚠️ Set CLOUDFLARE_TOKEN and CLOUDFLARE_ZONE_ID environment variables.${NC}"
else
  curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$CLOUDFLARE_ZONE_ID/purge_cache" \
       -H "Authorization: Bearer $CLOUDFLARE_TOKEN" \
       -H "Content-Type: application/json" \
       --data '{"purge_everything":true}'
  echo -e "${GREEN}✅ Cloudflare cache purged${NC}"
fi

# Wait for deployment to propagate
echo -e "${BLUE}⏳ Waiting for deployment to propagate...${NC}"
sleep 10

# Verify deployment
echo -e "${BLUE}🔍 Verifying deployment...${NC}"
response=$(curl -s https://yaasservice.io/api/v1/health || echo "Timeout")
if [[ "$response" == *"Operational"* ]]; then
  echo -e "${GREEN}✅ Deployment successful!${NC}"
  echo -e "${GREEN}🌐 YaaS Service is now live at https://yaasservice.io${NC}"
else
  echo -e "${YELLOW}⚠️ Could not verify deployment${NC}"
  echo -e "Response: $response"
fi

echo -e "${BLUE}🎉 Deployment Complete!${NC}"
