#!/bin/bash

# 1️⃣ Navigate to Project Directory
echo "🔄 Switching to Project Directory..."
cd ~/yaasservice.io || exit

# 2️⃣ Ensure Dependencies are Installed
echo "📦 Installing Dependencies..."
npm install express serverless-http

# 3️⃣ Update package.json for ES Modules
echo "🚀 Updating package.json..."
cat > package.json <<EOL
{
  "name": "yaasservice",
  "version": "1.0.0",
  "type": "module",
  "dependencies": {
    "express": "^4.18.2",
    "serverless-http": "^3.2.0"
  }
}
EOL

# 4️⃣ Update API Handler
echo "🚀 Updating API Handler..."
cat > api/index.js <<EOL
import express from 'express';
import serverless from 'serverless-http';

const app = express();
app.use(express.json());

app.get('/v1/health', (req, res) => {
  console.log('Health Check Invoked');
  res.status(200).json({ status: "YaaS Service is Running!" });
});

export const handler = serverless(app);
EOL

# 5️⃣ Update Vercel Configuration
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
    { "src": "/api/v1/health", "dest": "/api/index.js" },
    { "src": "/api/(.*)", "dest": "/api/index.js" }
  ]
}
EOL

# 6️⃣ Stage, Commit, and Push Changes
echo "🔄 Staging Changes..."
git add .
git commit -m "Fix ES modules, handler export, and routing"
git push origin main

# 7️⃣ Deploy to Vercel
echo "🚀 Deploying to Vercel..."
vercel deploy --prod

# 8️⃣ Perform Health Check
echo "🌐 Performing Health Check..."
echo "Testing: https://yaasservice.io/api/v1/health"
curl -L https://yaasservice.io/api/v1/health
echo ""
echo "Testing: https://www.yaasservice.io/api/v1/health"
curl -L https://www.yaasservice.io/api/v1/health
echo ""

echo "✅ Deployment and Health Check Completed."
echo "💡 If there are issues, check the logs: vercel logs https://yaasservice.io/api/v1/health --since=1h"
