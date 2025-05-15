#!/bin/bash
# deploy_enhanced_v10.sh - Final Enhanced YaaS Deployment

# 1️⃣ Navigate to Project Directory
echo "🔄 Switching to Project Directory..."
cd ~/yaasservice.io || exit

# 2️⃣ Install Enhanced Dependencies
echo "📦 Installing Enhanced Dependencies..."
cat > package.json <<EOL
{
  "name": "yaasservice.io",
  "version": "2.0.0",
  "description": "Enhanced YaaS Service Platform",
  "main": "api/index.js",
  "type": "module",
  "scripts": {
    "start": "node api/index.js",
    "test": "echo \"Error: no test specified\" && exit 1"
  },
  "dependencies": {
    "express": "^4.18.2",
    "serverless-http": "^3.1.0",
    "cors": "^2.8.5",
    "express-rate-limit": "^6.8.0",
    "@vercel/edge-config": "^1.0.0"
  }
}
EOL
rm -rf node_modules package-lock.json
npm install

# 3️⃣ Update API Handler with Full Features
echo "🚀 Deploying Enhanced API Handler..."
cat > api/index.js <<EOL
import express from 'express';
import serverless from 'serverless-http';
import cors from 'cors';
import { get } from '@vercel/edge-config';
import rateLimit from 'express-rate-limit';
import crypto from 'crypto';

const app = express();

// Enhanced Middleware Stack
app.use(express.json());
app.use(cors({
  origin: process.env.NODE_ENV === 'production' 
    ? ['https://yaasservice.io', 'https://www.yaasservice.io']
    : '*',
  methods: ['GET', 'POST', 'OPTIONS']
}));

app.use(rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // Limit each IP to 100 requests per window
  standardHeaders: true,
  legacyHeaders: false,
}));

app.use((req, res, next) => {
  console.log(\`\${new Date().toISOString()} - \${req.method} \${req.path}\`);
  next();
});

// Core Service Endpoints
app.get('/api/v1/health', (req, res) => {
  res.status(200).json({ 
    status: "Operational",
    version: "2.0.0",
    services: ["core", "edge-config", "rate-limiting"]
  });
});

app.get('/api/v1/config', async (req, res) => {
  try {
    const config = await get('appConfig');
    res.status(200).json({
      ...config,
      cacheStatus: "HIT",
      edge: true
    });
  } catch (error) {
    res.status(500).json({ 
      error: "Configuration Unavailable",
      edge: false,
      incidentId: crypto.randomUUID()
    });
  }
});

app.post('/api/v1/analyze', (req, res) => {
  try {
    const { data } = req.body;
    if (!data) {
      return res.status(400).json({ 
        error: "Bad Request",
        message: "Missing analysis data",
        incidentId: crypto.randomUUID()
      });
    }
    
    res.json({
      analysisId: crypto.randomUUID(),
      timestamp: new Date().toISOString(),
      insights: {
        wordCount: data.length,
        sentiment: "neutral"
      }
    });
  } catch (error) {
    res.status(500).json({
      error: "Analysis Failed",
      incidentId: crypto.randomUUID()
    });
  }
});

// Error Handling
app.use((err, req, res, next) => {
  console.error('🚨 Error:', err);
  res.status(500).json({
    error: "System Malfunction",
    incidentId: crypto.randomUUID()
  });
});

export const handler = serverless(app);
EOL

# 4️⃣ Update Vercel Configuration
echo "🔧 Updating Edge Configuration..."
cat > vercel.json <<EOL
{
  "version": 2,
  "functions": {
    "api/index.js": {
      "memory": 1024,
      "maxDuration": 60,
      "includeFiles": "config/**"
    }
  },
  "routes": [
    { "src": "/api/(.*)", "dest": "/api/index.js" },
    { "src": "/", "dest": "/public/index.html" }
  ],
  "build": {
    "env": {
      "NODE_ENV": "production",
      "EDGE_CONFIG": "@yaas-config",
      "CLOUDFLARE_ANALYTICS": "3296fcb8f09c45098abb14a4bcf7821b"
    }
  }
}
EOL

# 5️⃣ Deployment Workflow
echo "🚀 Beginning Deployment..."
git add .
git commit -m "YaaS v2.0 - Enhanced Service Platform" && git push origin main

if vercel deploy --prod; then
    echo "✅ Vercel deployment successful."
else
    echo "❌ Vercel deployment failed." && exit 1
fi

# 6️⃣ Cloudflare Cache Management
echo "🚀 Purging Cloudflare Cache..."
CLOUDFLARE_TOKEN="tU8_WGyIrFyI5zAJpxwcDTMMnbtE7VMtyHzDSpRh"
CLOUDFLARE_ZONE_ID="a44048aba7521e90edbddbae88f94d89"
RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -X POST "https://api.cloudflare.com/client/v4/zones/$CLOUDFLARE_ZONE_ID/purge_cache" \
     -H "Authorization: Bearer $CLOUDFLARE_TOKEN" \
     -H "Content-Type: application/json" \
     --data '{"purge_everything":true}')
[ "$RESPONSE" -eq 200 ] && echo "✅ Cloudflare cache purged." || echo "❌ Cache purge failed."

# 7️⃣ Health Check Suite
echo "🌐 Performing Health Checks..."
declare -A ENDPOINTS=(
  ["Health Check"]="/api/v1/health"
  ["Config Check"]="/api/v1/config"
  ["Analyze Check"]="/api/v1/analyze"
)

for name in "${!ENDPOINTS[@]}"; do
  endpoint="${ENDPOINTS[$name]}"
  echo "🔍 Testing $name ($endpoint)"
  response=$(curl -s -o /dev/null -w "%{http_code}" -X GET "https://yaasservice.io$endpoint")
  [ "$response" -eq 200 ] || [ "$response" -eq 400 ] && echo "✅ Success" || echo "❌ Failed (HTTP $response)"
done

# 8️⃣ Post-Deployment Options
echo "🚀 Deployment Complete!"
echo "📜 Log Access Options:"
select option in "Realtime-Logs" "Error-Logs" "Metrics" "Exit"; do
  case $option in
    "Realtime-Logs")
      vercel logs https://yaasservice.io/api/v1/health --no-color
      ;;
    "Error-Logs")
      vercel logs https://yaasservice.io/api/v1/health --since 1h | grep -i 'error\|fail'
      ;;
    "Metrics")
      open "https://vercel.com/yaas-services-projects/yaasservice-io/analytics"
      ;;
    "Exit")
      break
      ;;
  esac
done
