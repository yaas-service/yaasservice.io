#!/bin/bash
# deploy_fix_v11.sh - Production-Ready Deployment Script

# 1️⃣ Environment Configuration
CLOUDFLARE_ZONE_ID="a44048aba7521e90edbddbae88f94d89"
CLOUDFLARE_TOKEN="tU8_WGyIrFyI5zAJpxwcDTMMnbtE7VMtyHzDSpRh"

# 2️⃣ Navigate to Project Directory
echo "🔄 Switching to Project Directory..."
cd ~/yaasservice.io || exit

# 3️⃣ Install Dependencies
echo "📦 Installing Dependencies..."
npm install

# 4️⃣ Configure Vercel
echo "🔧 Configuring Vercel..."
cat > vercel.json <<EOL
{
  "version": 2,
  "functions": {
    "api/index.js": {
      "memory": 1024,
      "maxDuration": 15,
      "includeFiles": "config/**"
    }
  },
  "routes": [
    { "src": "/api/(.*)", "dest": "/api/index.js" },
    { "src": "/", "dest": "/public/index.html" }
  ],
  "env": {
    "JWT_SECRET": "JWT_SECRET",
    "API_KEY": "API_KEY",
    "EDGE_CONFIG": "EDGE_CONFIG",
    "ENABLE_PREMIUM": "true"
  }
}
EOL

# 5️⃣ Deploy
echo "🚀 Deploying to Production..."
vercel deploy --prod

# 6️⃣ Post-Deployment Cleanup
echo "🧹 Purging Cloudflare Cache..."
curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$CLOUDFLARE_ZONE_ID/purge_cache" \
  -H "Authorization: Bearer $CLOUDFLARE_TOKEN" \
  --data '{"purge_everything":true}'

# 7️⃣ Final Verification
echo "🔍 Performing Final Health Check..."
sleep 30 # Increased delay for deployment propagation

# Enhanced health check with error handling
response=$(curl -s -w "\n%{http_code}" https://yaasservice.io/api/v1/health)
status_code=$(echo "$response" | tail -n1)
content=$(echo "$response" | head -n -1)

if [ "$status_code" -eq 200 ]; then
  echo "✅ Health Check Successful:"
  echo "$content" | jq .
else
  echo "❌ Health Check Failed (Status: $status_code)"
  echo "Raw Response:"
  echo "$content"
fi

echo "🚀 Deployment Process Complete!"
