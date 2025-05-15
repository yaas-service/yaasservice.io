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

// ES Module Export
export const handler = serverless(app);
EOL
echo "✅ API handler updated successfully."

# 4️⃣ Update `vercel.json`
echo "🚀 Updating Vercel Configuration..."
cat > vercel.json <<EOL
{
  "version": 2,
  "functions": {
    "api/index.js": {
      "memory": 1024,
      "maxDuration": 60
    }
  },
  "routes": [
    { "src": "/api/v1/health", "dest": "api/index.js" },
    { "src": "/api/(.*)", "dest": "api/index.js" },
    { "src": "/", "dest": "/public/index.html" }
  ],
  "build": {
    "env": {
      "NODE_ENV": "production",
      "CLOUDFLARE_ANALYTICS": "3296fcb8f09c45098abb14a4bcf7821b"
    }
  }
}
EOL
echo "✅ Vercel configuration updated successfully."

# 5️⃣ Update `package.json`
echo "🚀 Updating package.json..."
cat > package.json <<EOL
{
  "name": "yaasservice.io",
  "version": "1.0.0",
  "description": "YaaS Service",
  "main": "api/index.js",
  "type": "module",
  "scripts": {
    "start": "node api/index.js",
    "test": "echo \"Error: no test specified\" && exit 1"
  },
  "dependencies": {
    "express": "^4.18.2",
    "serverless-http": "^3.1.0"
  }
}
EOL
echo "✅ package.json updated successfully."

# 6️⃣ Stage, Commit, and Push Changes
echo "🔄 Staging Changes..."
git add .
git commit -m "Fix ES Modules, handler export, and Vercel routing configuration"
git push origin main

# 7️⃣ Deploy to Vercel
echo "🚀 Deploying to Vercel..."
vercel deploy --prod

# 8️⃣ Purge Cloudflare Cache
echo "🚀 Purging Cloudflare Cache..."
curl -X POST "https://api.cloudflare.com/client/v4/zones/YOUR_ZONE_ID/purge_cache" \
     -H "X-Auth-Email: YOUR_CLOUDFLARE_EMAIL" \
     -H "X-Auth-Key: YOUR_CLOUDFLARE_API_KEY" \
     -H "Content-Type: application/json" \
     --data '{"purge_everything":true}'

# 9️⃣ Perform Health Check
echo "🌐 Performing Health Check..."
echo "Testing: https://yaasservice.io/api/v1/health"
curl -L https://yaasservice.io/api/v1/health
echo ""
echo "Testing: https://www.yaasservice.io/api/v1/health"
curl -L https://www.yaasservice.io/api/v1/health
echo ""

echo "✅ Deployment and Health Check Completed."
echo "💡 If there are issues, check the logs: vercel logs https://yaasservice.io/api/v1/health"

