#!/bin/bash

# 1️⃣ Navigate to Project Directory
echo "🔄 Switching to Project Directory..."
cd ~/yaasservice.io || exit

# 2️⃣ Install Dependencies
echo "📦 Installing Dependencies..."
rm -rf node_modules package-lock.json
npm install

# 3️⃣ Update package.json
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

# 4️⃣ Update API Handler
echo "🚀 Updating API Handler..."
cat > api/index.js <<EOL
import express from 'express';
import serverless from 'serverless-http';

const app = express();
app.use(express.json());

// Health Check Route
app.get('/api/v1/health', (req, res) => {
  console.log('Health Check Invoked');
  try {
    res.status(200).json({ status: "YaaS Service is Running!" });
  } catch (error) {
    console.error('Error in health check:', error);
    res.status(500).json({ error: "Internal Server Error" });
  }
});

// Wrap express app in serverless-http and export the handler correctly
module.exports = app;
module.exports.handler = serverless(app);
EOL
echo "✅ API handler updated successfully."

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

# 6️⃣ Stage, Commit, and Push Changes
echo "🔄 Staging Changes..."
git add .
git commit -m "Fix ES Modules, handler export, and Vercel routing configuration"
git push origin main

# 7️⃣ Check Vercel Aliases and Remove Conflicts
echo "🔍 Checking Aliases and Removing Conflicts..."
vercel alias ls | grep 'yaasservice.io' | awk '{print $1}' | while read -r line ; do
    echo "Removing alias $line"
    vercel alias rm $line --yes
done

# 8️⃣ Re-add Domain to Vercel
echo "➕ Re-adding Domain to Vercel..."
vercel domains add yaasservice.io || echo "Domain already linked."
vercel domains add www.yaasservice.io || echo "Domain already linked."

# 9️⃣ Deploy to Vercel
echo "🚀 Deploying to Vercel..."
vercel deploy --prod

# 🔟 Perform Health Check
echo "🌐 Performing Health Check..."
echo "Testing: https://yaasservice.io/api/v1/health"
curl -L https://yaasservice.io/api/v1/health
echo ""
echo "Testing: https://www.yaasservice.io/api/v1/health"
curl -L https://www.yaasservice.io/api/v1/health
echo ""

echo "✅ Deployment and Health Check Completed."
echo "💡 If there are issues, check the logs: vercel logs https://yaasservice.io/api/v1/health"

