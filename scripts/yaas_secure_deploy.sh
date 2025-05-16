#!/bin/bash
# yaas_secure_deploy.sh - Corrected Deployment Script

# 1️⃣ Validate Environment Variables
echo "🔒 Validating tokens..."
if [[ -z "$VERCEL_TOKEN" || "$VERCEL_TOKEN" == *"-"* ]]; then
  echo "❌ Invalid Vercel Token:"
  echo "   - Get a valid token from https://vercel.com/account/tokens"
  echo "   - Token should look like: vf_xxxxxxxxxxxxxxxxxxxxxxxx"
  exit 1
fi

if [[ -z "$CLOUDFLARE_TOKEN" || "$CLOUDFLARE_TOKEN" != *"@"* ]]; then
  echo "❌ Invalid Cloudflare Token:"
  echo "   - Use Global API Key from https://dash.cloudflare.com/profile/api-tokens"
  echo "   - Format: <email>@<api_key>"
  exit 1
fi

# 2️⃣ Extract Cloudflare Credentials
CF_EMAIL="${CLOUDFLARE_TOKEN%%@*}"
CF_API_KEY="${CLOUDFLARE_TOKEN#*@}"

# 3️⃣ Deployment Process
echo "🚀 Deploying to Vercel..."
DEPLOY_OUTPUT=$(vercel deploy --prod --token "$VERCEL_TOKEN" 2>&1)
DEPLOY_URL=$(echo "$DEPLOY_OUTPUT" | grep -o 'https://[^ ]*\.vercel\.app')

if [[ -z "$DEPLOY_URL" ]]; then
  echo "❌ Deployment failed! Output:"
  echo "$DEPLOY_OUTPUT"
  exit 1
fi

echo "✅ Deployment URL: $DEPLOY_URL"

# 4️⃣ Post-Deploy Tests
echo "🔍 Testing Endpoints..."
curl_test() {
  local url="$1"
  local data="$2"
  echo "Testing $url"
  curl -s -X POST "$url" \
    -H "Content-Type: application/json" \
    -d "$data" | jq . || echo "Test failed"
}

# Health Check
curl -s "$DEPLOY_URL/api/v1/health" | jq

# Authentication Test
curl_test "$DEPLOY_URL/api/v1/auth/token" '{"apiKey":"673274006fb6b23dc18609e7beb4b1409cb157d373abc2322e5202b47604a2e2"}'

# 5️⃣ Cloudflare Cache Purge
echo "🧹 Purging Cloudflare Cache..."
curl -X POST "https://api.cloudflare.com/client/v4/zones/a44048aba7521e90edbddbae88f94d89/purge_cache" \
  -H "X-Auth-Email: $CF_EMAIL" \
  -H "X-Auth-Key: $CF_API_KEY" \
  -H "Content-Type: application/json" \
  --data '{"purge_everything":true}' | jq '.success'

# 6️⃣ Security Cleanup
unset VERCEL_TOKEN CLOUDFLARE_TOKEN CF_EMAIL CF_API_KEY

echo "✅ Deployment complete! Final URL: $DEPLOY_URL"
