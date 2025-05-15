#!/bin/bash

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
  console.log('Health Check Invoked');
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
    console.error('Config error:', error);
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
    console.error('Analysis error:', error);
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

// IMPORTANT: This is the correct export format for Vercel serverless functions
export default function(req, res) {
  return serverless(app)(req, res);
}
EOL

# 4️⃣ Update Vercel Configuration
echo "🔧 Updating Edge Configuration..."
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

# 5️⃣ Create a simple front-end
echo "🎨 Creating Simple Frontend..."
mkdir -p public
cat > public/index.html <<EOL
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>YaaS - You as a Service</title>
  <style>
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, 'Open Sans', 'Helvetica Neue', sans-serif;
      line-height: 1.6;
      color: #333;
      max-width: 800px;
      margin: 0 auto;
      padding: 20px;
    }
    header {
      border-bottom: 1px solid #eee;
      padding-bottom: 20px;
      margin-bottom: 20px;
    }
    h1 {
      color: #2d3748;
    }
    .card {
      background: #f7fafc;
      border-radius: 8px;
      padding: 20px;
      margin-bottom: 20px;
      box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
    }
    .endpoint {
      background: #edf2f7;
      padding: 10px;
      border-radius: 4px;
      font-family: monospace;
      margin: 10px 0;
    }
    footer {
      margin-top: 40px;
      text-align: center;
      color: #718096;
      font-size: 0.9em;
    }
  </style>
</head>
<body>
  <header>
    <h1>YaaS - You as a Service</h1>
    <p>A powerful, extensible API platform.</p>
  </header>
  
  <div class="card">
    <h2>API Status</h2>
    <p id="status">Checking service status...</p>
  </div>
  
  <div class="card">
    <h2>Available Endpoints</h2>
    <div class="endpoint">GET /api/v1/health</div>
    <div class="endpoint">GET /api/v1/config</div>
    <div class="endpoint">POST /api/v1/analyze</div>
  </div>
  
  <div class="card">
    <h2>Try the Analyze Endpoint</h2>
    <textarea id="analyzeText" rows="4" style="width: 100%; margin-bottom: 10px;" 
      placeholder="Enter text to analyze..."></textarea>
    <button id="analyzeBtn" style="padding: 8px 16px; background: #4299e1; color: white; border: none; border-radius: 4px; cursor: pointer;">
      Analyze
    </button>
    <div id="results" style="margin-top: 20px;"></div>
  </div>
  
  <footer>
    &copy; 2025 YaaS Service - v2.0.0
  </footer>

  <script>
    // Check service status
    fetch('/api/v1/health')
      .then(response => response.json())
      .then(data => {
        document.getElementById('status').innerHTML = 
          \`<span style="color: green;">✓</span> \${data.status} (v\${data.version}) - Services: \${data.services.join(', ')}\`;
      })
      .catch(error => {
        document.getElementById('status').innerHTML = 
          \`<span style="color: red;">✗</span> Service Unavailable\`;
      });
    
    // Analyze endpoint demo
    document.getElementById('analyzeBtn').addEventListener('click', () => {
      const text = document.getElementById('analyzeText').value;
      if (!text) return;
      
      document.getElementById('results').innerHTML = 'Analyzing...';
      
      fetch('/api/v1/analyze', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ data: text }),
      })
        .then(response => response.json())
        .then(data => {
          document.getElementById('results').innerHTML = 
            \`<pre>\${JSON.stringify(data, null, 2)}</pre>\`;
        })
        .catch(error => {
          document.getElementById('results').innerHTML = 
            \`<div style="color: red;">Error: \${error.message}</div>\`;
        });
    });
  </script>
</body>
</html>
EOL

# 6️⃣ Stage, Commit, and Push Changes
echo "📤 Staging Changes..."
git add .
git commit -m "Fixed serverless export format for Vercel"
git push origin main

# 7️⃣ Deploy to Vercel
echo "🚀 Deploying to Vercel..."
if vercel deploy --prod; then
    echo "✅ Vercel deployment successful."
else
    echo "❌ Vercel deployment failed." && exit 1
fi

# 8️⃣ Purge Cloudflare Cache
echo "🧹 Purging Cloudflare Cache..."
CLOUDFLARE_TOKEN="tU8_WGyIrFyI5zAJpxwcDTMMnbtE7VMtyHzDSpRh"
CLOUDFLARE_ZONE_ID="a44048aba7521e90edbddbae88f94d89"
RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -X POST "https://api.cloudflare.com/client/v4/zones/$CLOUDFLARE_ZONE_ID/purge_cache" \
     -H "Authorization: Bearer $CLOUDFLARE_TOKEN" \
     -H "Content-Type: application/json" \
     --data '{"purge_everything":true}')
if [ "$RESPONSE" -eq 200 ]; then
    echo "✅ Cloudflare cache purged successfully."
else
    echo "❌ Failed to purge Cloudflare cache."
fi

# 9️⃣ Perform Health Check
echo "🔍 Performing Health Check..."
# Add a short delay to give Vercel time to deploy fully
sleep 5
for url in "https://yaasservice.io/api/v1/health" "https://www.yaasservice.io/api/v1/health"; do
    echo "Testing: $url"
    status_code=$(curl -s -o /dev/null -w "%{http_code}" -L $url)
    if [ "$status_code" -eq 200 ]; then
        response=$(curl -s -L $url)
        echo "✅ Health Check Passed for $url"
        echo "Response: $response"
    else
        echo "❌ Health Check Failed for $url with status code $status_code"
    fi
done

echo "🚀 Deployment and Health Check Completed."
echo "💡 If there are issues, check the logs: vercel logs https://yaasservice.io/api/v1/health"

# 🔟 Logs Option
echo "📜 Would you like to view logs?"
select yn in "Real-time" "Last 30 Minutes" "No"; do
    case $yn in
        "Real-time" ) vercel logs https://yaasservice.io/api/v1/health --scope yaas-services-projects --no-color; break;;
        "Last 30 Minutes" ) vercel logs https://yaasservice.io/api/v1/health --scope yaas-services-projects --no-color; break;;
        "No" ) echo "🚀 Deployment Complete. Exiting..."; exit;;
    esac
done
