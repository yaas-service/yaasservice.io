#!/bin/bash

# ================================================
# YaaS Service Deployment Fix Script
# Author: Isaac Thor
# Description: Fixes the serverless configuration,
# deploys to Vercel, and performs health check
# ================================================

echo "🔄 Switching to Project Directory..."
cd ~/yaasservice.io || exit

echo "🚀 Updating API Handler..."
# Update API handler (api/index.js)
cat > api/index.js <<EOL
import express from 'express';
import serverless from 'serverless-http';

const app = express();
app.use(express.json());

// Health Check Route
app.get('/health', (req, res) => {
  console.log('Health Check Invoked');
  res.status(200).json({ status: "YaaS Service is Running!" });
});

// Export the serverless handler directly
module.exports = serverless(app);
EOL

echo "✅ API handler updated successfully."

echo "🚀 Updating Vercel Configuration..."
# Update Vercel configuration (vercel.json)
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
  ]
}
EOL

echo "✅ Vercel configuration updated successfully."

echo "🔄 Staging Changes..."
git add .
git commit -m "Fix handler and Vercel routing configuration"
git push origin main

echo "🚀 Deploying to Vercel..."
vercel deploy --prod

echo "✅ Deployment complete."

# Perform Health Check
echo "🌐 Performing Health Check..."
echo "Testing: https://yaasservice.io/api/v1/health"
curl -L https://yaasservice.io/api/v1/health
echo ""

echo "Testing: https://www.yaasservice.io/api/v1/health"
curl -L https://www.yaasservice.io/api/v1/health
echo ""

echo "✅ Deployment and Health Check Completed."
echo "💡 If there are issues, check the logs: vercel logs https://yaasservice.io/api/v1/health --since=1h"

