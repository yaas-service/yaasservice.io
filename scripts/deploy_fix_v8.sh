#!/bin/bash

# 1️⃣ Navigate to Project Directory
echo "🔄 Switching to Project Directory..."
cd ~/yaasservice.io || exit

# 2️⃣ Install Dependencies
echo "📦 Installing Dependencies..."
rm -rf node_modules package-lock.json
npm install

# 3️⃣ Update API Handler
echo "🚀 Updating API Handler..."
cat > api/index.js <<EOL
import express from 'express';
import serverless from 'serverless-http';

const app = express();
app.use(express.json());

const PORT = process.env.PORT || 8080;

app.get('/api/v1/health', (req, res) => {
  console.log('🌐 Health Check Invoked');
  try {
    res.status(200).json({ status: "YaaS Service is Running!" });
  } catch (error) {
    console.error('🔥 Error in health check:', error.message);
    res.status(500).json({ error: "Internal Server Error" });
  }
});

if (process.env.NODE_ENV === 'development') {
  app.listen(PORT, () => {
    console.log(\`🌐 Local server running at http://localhost:\${PORT}\`);
  });
}

module.exports = app;
module.exports.handler = serverless(app);
EOL

# 4️⃣ Update Vercel Configuration
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
    { "src": "/api/(.*)", "dest": "/api/index.js" },
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

# 5️⃣ Stage, Commit, and Push Changes
echo "🔄 Staging Changes..."
git add .
git commit -m "Fix ES Modules, handler export, and Vercel routing configuration"
git push origin main

# 6️⃣ Deploy to Vercel
echo "🚀 Redeploying to Vercel..."
vercel deploy --prod

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

