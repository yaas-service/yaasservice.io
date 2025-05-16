#!/bin/bash

# 1️⃣ Environment Configuration
CLOUDFLARE_ZONE_ID="a44048aba7521e90edbddbae88f94d89"
CLOUDFLARE_TOKEN="tU8_WGyIrFyI5zAJpxwcDTMMnbtE7VMtyHzDSpRh"

# 2️⃣ Navigate to Project Directory
echo "🔄 Switching to Project Directory..."
cd ~/yaasservice.io || exit

# 3️⃣ Install Production Dependencies
# ====================
echo "📦 Installing Production Dependencies..."
cat > package.json <<EOL
{
  "name": "yaasservice.io",
  "version": "2.2.0",
  "description": "Production-Ready YaaS Service Platform",
  "main": "api/index.js",
  "type": "module",
  "scripts": {
    "start": "node api/index.js",
    "test": "echo \"Error: no test specified\" && exit 1"
  },
  "dependencies": {
    "express": "^4.18.2",
    "serverless-http": "^3.1.0",
    "jsonwebtoken": "^9.0.2",
    "@vercel/edge-config": "^1.0.0",
    "cors": "^2.8.5",
    "express-rate-limit": "^6.8.0"
  }
}
EOL
rm -rf node_modules package-lock.json
npm install

# 4️⃣ Validate Environment Variables
# ====================
echo "🔎 Validating Environment Variables..."
if [[ -z "$JWT_SECRET" || -z "$API_KEY" || -z "$EDGE_CONFIG" ]]; then
  echo "❌ ERROR: One or more environment variables are missing!"
  echo "   - JWT_SECRET: $JWT_SECRET"
  echo "   - API_KEY: $API_KEY"
  echo "   - EDGE_CONFIG: $EDGE_CONFIG"
  exit 1
else
  echo "✅ Environment variables are properly configured."
fi

# 5️⃣ Deploy
# ====================
echo "🚀 Deploying to Production..."
vercel deploy --prod

# 6️⃣ Purge Cache
# ====================
echo "🧹 Purging Cloudflare Cache..."
curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$CLOUDFLARE_ZONE_ID/purge_cache" \
  -H "Authorization: Bearer $CLOUDFLARE_TOKEN" \
  --data '{"purge_everything":true}'

# 7️⃣ Final Health Check
# =====================
echo "🔍 Performing Final Health Check..."
sleep 20 # Allow deployment propagation
for url in "https://yaasservice.io/api/v1/health" "https://www.yaasservice.io/api/v1/health"; do
    echo "Testing: $url"
    status_code=$(curl -s -o /dev/null -w "%{http_code}" -L $url)
    if [ "$status_code" -eq 200 ]; then
        response=$(curl -s -L $url)
        echo "✅ Health Check Passed for $url"
        echo "Response: $response"
    else
        echo "❌ Health Check Failed for $url with status code $status_code"
        echo "⚠️ Attempting a quick restart..."
        vercel deploy --prod
        sleep 15
        status_code=$(curl -s -o /dev/null -w "%{http_code}" -L $url)
        if [ "$status_code" -eq 200 ]; then
            echo "✅ Recovery Successful for $url"
        else
            echo "❌ Recovery Failed. Please check logs."
        fi
    fi
done

# 8️⃣ Frontend Synchronization
# =====================
echo "🔄 Syncing Frontend with CDN..."
curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$CLOUDFLARE_ZONE_ID/purge_cache" \
  -H "Authorization: Bearer $CLOUDFLARE_TOKEN" \
  --data '{"purge_everything":true}'

# 9️⃣ Deployment Completion
# =====================
echo "🚀 Deployment and Health Check Completed."
echo "💡 If there are issues, check the logs: vercel logs https://yaasservice.io/api/v1/health"

