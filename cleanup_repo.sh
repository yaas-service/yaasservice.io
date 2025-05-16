#!/bin/bash
# cleanup_repo.sh - YaaS Repository Cleanup

# Colors for better output
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}🧹 Starting YaaS Repository Cleanup${NC}"

# 1. Create standard directory structure
echo -e "\n${BLUE}Creating standard directory structure...${NC}"

mkdir -p api
mkdir -p public
mkdir -p scripts
mkdir -p docs
mkdir -p config

# 2. Move files to appropriate directories
echo -e "\n${BLUE}Organizing files...${NC}"

# Move API files
find . -maxdepth 1 -name "*.js" -not -path "*/\.*" -exec mv {} api/ \; 2>/dev/null
echo -e "${GREEN}✅ API files organized${NC}"

# Move scripts
find . -maxdepth 1 -name "*.sh" -not -name "cleanup_repo.sh" -not -name "security_audit.sh" -exec mv {} scripts/ \; 2>/dev/null
echo -e "${GREEN}✅ Scripts organized${NC}"

# Move HTML files
find . -maxdepth 1 -name "*.html" -exec mv {} public/ \; 2>/dev/null
echo -e "${GREEN}✅ Public files organized${NC}"

# Move Markdown files to docs
find . -maxdepth 1 -name "*.md" -not -name "README.md" -exec mv {} docs/ \; 2>/dev/null
echo -e "${GREEN}✅ Documentation files organized${NC}"

# 3. Create README.md if doesn't exist
if [ ! -f "README.md" ]; then
  echo -e "\n${BLUE}Creating README.md...${NC}"
  
  cat > README.md <<EOL
# YaaS - You as a Service

A powerful serverless API platform for text analysis.

## Features

- Sentiment analysis of text
- Simple API with clean endpoints
- Serverless architecture on Vercel

## API Endpoints

- \`GET /api/v1/health\` - Check service status
- \`POST /api/v1/analyze\` - Analyze text sentiment

## Getting Started

1. Clone the repository
2. Install dependencies: \`npm install\`
3. Run locally: \`npm run dev\`
4. Deploy: \`./scripts/deploy_yaas.sh\`

## Testing

Run the test suite: \`./scripts/test_yaas.sh\`

## License

MIT
EOL

  echo -e "${GREEN}✅ Created README.md${NC}"
fi

# 4. Create package.json if needed
if [ ! -f "package.json" ]; then
  echo -e "\n${BLUE}Creating package.json...${NC}"
  
  cat > package.json <<EOL
{
  "name": "yaasservice",
  "version": "2.4.0",
  "description": "You as a Service - Text Analysis API",
  "main": "api/index.js",
  "type": "module",
  "scripts": {
    "start": "node api/index.js",
    "dev": "nodemon api/index.js",
    "test": "echo \"Error: no test specified\" && exit 1",
    "deploy": "./scripts/deploy_yaas.sh",
    "security": "./scripts/security_audit.sh"
  },
  "dependencies": {
    "jsonwebtoken": "^9.0.2",
    "@vercel/edge-config": "^1.0.0"
  },
  "devDependencies": {
    "nodemon": "^2.0.22"
  }
}
EOL

  echo -e "${GREEN}✅ Created package.json${NC}"
fi

# 5. Clean up old deployment scripts and versions
echo -e "\n${BLUE}Cleaning up old deployment files...${NC}"

# Create a single, unified deployment script
cat > scripts/deploy_yaas.sh <<EOL
#!/bin/bash
# deploy_yaas.sh - YaaS Unified Deployment Script

# Colors for better output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "\${BLUE}🚀 Deploying YaaS Service\${NC}"

# Deploy to Vercel
echo -e "\${BLUE}🚀 Deploying to Vercel...\${NC}"
vercel deploy --prod || { 
  echo -e "\${RED}❌ Vercel deployment failed\${NC}"
  exit 1
}

# Purge Cloudflare cache
echo -e "\${BLUE}🧹 Purging Cloudflare cache...\${NC}"
CLOUDFLARE_TOKEN="\${CLOUDFLARE_TOKEN}"
CLOUDFLARE_ZONE_ID="\${CLOUDFLARE_ZONE_ID}"

if [ -z "\$CLOUDFLARE_TOKEN" ] || [ -z "\$CLOUDFLARE_ZONE_ID" ]; then
  echo -e "\${YELLOW}⚠️ Cloudflare credentials not set. Skipping cache purge.\${NC}"
  echo -e "\${YELLOW}⚠️ Set CLOUDFLARE_TOKEN and CLOUDFLARE_ZONE_ID environment variables.\${NC}"
else
  curl -s -X POST "https://api.cloudflare.com/client/v4/zones/\$CLOUDFLARE_ZONE_ID/purge_cache" \\
       -H "Authorization: Bearer \$CLOUDFLARE_TOKEN" \\
       -H "Content-Type: application/json" \\
       --data '{"purge_everything":true}'
  echo -e "\${GREEN}✅ Cloudflare cache purged\${NC}"
fi

# Wait for deployment to propagate
echo -e "\${BLUE}⏳ Waiting for deployment to propagate...\${NC}"
sleep 10

# Verify deployment
echo -e "\${BLUE}🔍 Verifying deployment...\${NC}"
response=\$(curl -s https://yaasservice.io/api/v1/health || echo "Timeout")
if [[ "\$response" == *"Operational"* ]]; then
  echo -e "\${GREEN}✅ Deployment successful!\${NC}"
  echo -e "\${GREEN}🌐 YaaS Service is now live at https://yaasservice.io\${NC}"
else
  echo -e "\${YELLOW}⚠️ Could not verify deployment\${NC}"
  echo -e "Response: \$response"
fi

echo -e "\${BLUE}🎉 Deployment Complete!\${NC}"
EOL

chmod +x scripts/deploy_yaas.sh

# Move test script
mv test_yaas.sh scripts/test_yaas.sh 2>/dev/null
chmod +x scripts/test_yaas.sh 2>/dev/null

# Move enhancement script
mv enhance_yaas.sh scripts/enhance_yaas.sh 2>/dev/null
chmod +x scripts/enhance_yaas.sh 2>/dev/null

# Move security audit script
mv security_audit.sh scripts/security_audit.sh 2>/dev/null
chmod +x scripts/security_audit.sh 2>/dev/null

echo -e "${GREEN}✅ Deployment scripts unified and organized${NC}"

# 6. Create .env.example file
echo -e "\n${BLUE}Creating .env.example file...${NC}"

cat > .env.example <<EOL
# Environment Configuration
NODE_ENV=development

# Secrets (Do not commit actual secrets to git)
JWT_SECRET=your-jwt-secret-here
API_KEY=your-api-key-here

# Vercel Edge Config
EDGE_CONFIG=your-edge-config-url-here

# Cloudflare (for cache purging)
CLOUDFLARE_TOKEN=your-cloudflare-token-here
CLOUDFLARE_ZONE_ID=your-cloudflare-zone-id-here

# Feature Flags
ENABLE_PREMIUM=true
EOL

echo -e "${GREEN}✅ Created .env.example file${NC}"

# 7. Clean up temporary and unnecessary files
echo -e "\n${BLUE}Cleaning up temporary files...${NC}"

# List of files to remove
CLEANUP_FILES=(
  "deploy_fix_v10.sh"
  "deploy_fix_v11.sh"
  "deploy_fix_v12.sh"
  "yaas_secure_deploy.sh"
  "yaas_secure_deploy1.sh"
  "yaas_secure_deploy2.sh"
  "conectdeploy.sh"
  "deploy_yaas_final.sh"
)

for file in "${CLEANUP_FILES[@]}"; do
  if [ -f "$file" ]; then
    rm "$file"
    echo -e "${GREEN}✅ Removed $file${NC}"
  fi
done

# Remove any .bak files or other temporary files
find . -name "*.bak" -delete
find . -name "*~" -delete
find . -name ".DS_Store" -delete

echo -e "\n${BLUE}📋 Repository Cleanup Summary${NC}"
echo -e "- Created standardized directory structure"
echo -e "- Organized files by type and purpose"
echo -e "- Created/updated README.md and package.json"
echo -e "- Unified deployment scripts"
echo -e "- Created .env.example for environment management"
echo -e "- Cleaned up temporary and unnecessary files"

echo -e "\n${BLUE}🧹 Repository Cleanup Complete${NC}"
