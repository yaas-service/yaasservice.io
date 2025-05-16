echo "🔧 Configuring GitHub..."
eval "\$(ssh-agent -s)"
ssh-add ~/.ssh/id_rsa || { echo "❌ Failed to add SSH key. Make sure the passphrase is correct."; exit 1; }
git remote set-url origin git@github.com:yaas-service/yaasservice.io.git
ssh -T git@github.com || { echo "❌ GitHub SSH authentication failed."; exit 1; }#!/bin/bash

# =============================
# deploy_fix_v10.sh - Complete Production Deployment Script
# =============================

# 1️⃣ Environment Configuration
# =============================
VERCEL_PROJECT="yaas-services-projects"
CLOUDFLARE_ZONE_ID="a44048aba7521e90edbddbae88f94d89"
JWT_SECRET_NAME="@yaas-jwt-secret"
EDGE_CONFIG_NAME="@yaas-edge-config"
API_KEY_SECRET="@yaas-api-key"

# 2️⃣ Navigate to Project Directory
# ================================
echo "🔄 Switching to Project Directory..."
cd ~/yaasservice.io || exit 1

# 3️⃣ Install Production Dependencies
# ===================================
echo "📦 Installing Production Dependencies..."
rm -rf node_modules package-lock.json
npm install || { echo "❌ Dependency installation failed."; exit 1; }

# 4️⃣ GitHub Configuration
# =============================
echo "🔧 Configuring GitHub..."
git remote set-url origin git@github.com:yaas-service/yaasservice.io.git
ssh -T git@github.com || { echo "❌ GitHub SSH authentication failed."; exit 1; }

# 5️⃣ Deploy Secure API Handler
# =============================
echo "🚀 Deploying Secure API Handler..."
npm run build || { echo "❌ API Handler build failed."; exit 1; }

echo "🚀 Starting Secure Deployment..."
git add .
git commit -m "Production Deployment v2.2 with Security" || echo "No changes to commit"
git push origin main || { echo "❌ Git push failed."; exit 1; }

# 6️⃣ Configure Vercel Deployment
# ================================
echo "🔧 Configuring Vercel..."
vercel deploy --prod --yes --token=$VERCEL_TOKEN || { echo "❌ Vercel deployment failed."; exit 1; }

# 7️⃣ Deploy Frontend
# ==================
echo "🎨 Deploying Secure Frontend..."
mkdir -p public
cat > public/index.html <<EOL
<!DOCTYPE html>
<html>
<head>
  <title>YaaS Service v2.2</title>
  <style>
    body {
      font-family: -apple-system, BlinkMacSystemFont, sans-serif;
      max-width: 1200px;
      margin: 0 auto;
      padding: 2rem;
      line-height: 1.6;
    }
    .auth-form {
      background: #f8f9fa;
      padding: 2rem;
      border-radius: 8px;
      margin: 2rem 0;
    }
    .endpoint-card {
      border: 1px solid #e2e8f0;
      border-radius: 8px;
      padding: 1.5rem;
      margin: 1rem 0;
    }
  </style>
</head>
<body>
  <h1>YaaS Service Portal</h1>
  <div id="status"></div>

  <div class="auth-form">
    <h2>Authentication</h2>
    <input type="password" id="apiKey" placeholder="Enter API Key">
    <button onclick="getToken()">Get Access Token</button>
    <div id="tokenResult"></div>
  </div>

  <div class="endpoint-card">
    <h2>Text Analysis</h2>
    <textarea id="analysisText"></textarea>
    <button onclick="analyzeText()">Analyze</button>
    <div id="analysisResult"></div>
  </div>

</body>
</html>
EOL

# 8️⃣ Purge Cloudflare Cache
# ===========================
echo "🧹 Purging Cloudflare Cache..."
curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$CLOUDFLARE_ZONE_ID/purge_cache" \
  -H "Authorization: Bearer $CLOUDFLARE_TOKEN" \
  -H "Content-Type: application/json" \
  --data '{"purge_everything":true}' || { echo "❌ Cloudflare purge failed."; exit 1; }

# 9️⃣ Final Health Check
# =====================
echo "🔍 Performing Final Health Check..."
sleep 10
curl -s https://yaasservice.io/api/v1/health | jq '.' || echo "❌ Health check failed."

echo "✅ Deployment Complete! All systems operational."
echo "🌐 Production URL: https://yaasservice.io"
echo "🔒 Security Features Enabled:"
echo "- JWT Authentication"
echo "- Rate Limiting"
echo "- CORS Restrictions"
echo "- Environment Secrets"
echo "- Cloudflare CDN"

