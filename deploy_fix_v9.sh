#!/bin/bash

# 1️⃣ Navigate to Project Directory
echo "🔄 Switching to Project Directory..."
cd ~/yaasservice.io || exit

# 2️⃣ Install Dependencies
echo "📦 Installing Dependencies..."
rm -rf node_modules package-lock.json
npm install

# 3️⃣ Update `api/index.js`
echo "🚀 Updating API Handler..."
cat > api/index.js <<EOL
import express from 'express';
import serverless from 'serverless-http';

const app = express();
app.use(express.json());

const PORT = process.env.PORT || 8080;

// Health Check Route
app.get('/api/v1/health', (req, res) => {
  console.log('🌐 Health Check Invoked');
  try {
    res.status(200).json({ status: "YaaS Service is Running!" });
  } catch (error) {
    console.error('🔥 Error in health check:', error.message);
    res.status(500).json({ error: "Internal Server Error" });
  }
});

// Local development server
if (process.env.NODE_ENV === 'development') {
  app.listen(PORT, () => {
    console.log(\`🌐 Local server running at http://localhost:\${PORT}\`);
  });
}

// ✅ Correct ES Module export
export default serverless(app);
EOL
echo "✅ API handler updated successfully."

# 4️⃣ Stage, Commit, and Push Changes
echo "🔄 Staging Changes..."
git add .
git commit -m "Fix ES Modules, handler export, and Vercel routing configuration"
git push origin main

# 5️⃣ Deploy to Vercel
echo "🚀 Deploying to Vercel..."
vercel deploy --prod

# 6️⃣ Purge Cloudflare Cache (replace with your credentials)
echo "🚀 Purging Cloudflare Cache..."
curl -X POST "https://api.cloudflare.com/client/v4/zones/YOUR_ZONE_ID/purge_cache" \
     -H "X-Auth-Email: YOUR_CLOUDFLARE_EMAIL" \
     -H "X-Auth-Key: YOUR_CLOUDFLARE_API_KEY" \
     -H "Content-Type: application/json" \
     --data '{"purge_everything":true}'

# 7️⃣ Perform Health Check
echo "🌐 Performing Health Check..."
echo "Testing: https://yaasservice.io/api/v1/health"
curl -L https://yaasservice.io/api/v1/health
echo ""
echo "Testing: https://www.yaasservice.io/api/v1/health"
curl -L https://www.yaasservice.io/api/v1/health
echo ""

echo "✅ Deployment and Health Check Completed."
echo "💡 If there are issues, check the logs: vercel logs https://yaasservice.io/api/v1/health"

