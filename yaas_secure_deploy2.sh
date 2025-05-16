#!/bin/bash
# yaas_secure_deploy2.sh - Enhanced YaaS Deployment with Better Error Handling

# Colors for better output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Starting YaaS Service Deployment${NC}"

# 1️⃣ Navigate to project directory
echo -e "${BLUE}📁 Switching to project directory...${NC}"
cd ~/yaasservice.io || { echo -e "${RED}❌ Failed to switch directory${NC}"; exit 1; }

# 2️⃣ Fetch latest changes from remote
echo -e "${BLUE}🔄 Synchronizing with remote repository...${NC}"
git fetch origin
git pull --rebase origin main || { 
    echo -e "${YELLOW}⚠️ Merge conflicts detected, stashing local changes and pulling...${NC}"
    git stash
    git pull origin main
    git stash pop || echo -e "${YELLOW}⚠️ Stash pop failed, local changes may need manual merge${NC}"
}

# 3️⃣ Read Edge Config from environment
echo -e "${BLUE}🔧 Setting up Edge Config...${NC}"
if [ -f ".env" ]; then
    EDGE_CONFIG=$(grep EDGE_CONFIG .env | cut -d= -f2)
    echo -e "${GREEN}✅ Edge Config found in .env file${NC}"
else
    echo -e "${YELLOW}⚠️ .env file not found, creating one...${NC}"
    cat > .env <<EOL
NODE_ENV=development
JWT_SECRET=your-secure-jwt-secret-key
API_KEY=673274006fb6b23dc18609e7beb4b1409cb157d373abc2322e5202b47604a2e2
EDGE_CONFIG=https://edge-config.vercel.com/ecfg_gveuibvpzuj4zxspyq137vjdfjoq?token=c8172981-b544-4dc3-aa19-81d19f9cbf69
ENABLE_PREMIUM=true
EOL
    EDGE_CONFIG="https://edge-config.vercel.com/ecfg_gveuibvpzuj4zxspyq137vjdfjoq?token=c8172981-b544-4dc3-aa19-81d19f9cbf69"
    echo -e "${GREEN}✅ Created .env file with default values${NC}"
fi

# 4️⃣ Set up Edge Config values
if [[ $EDGE_CONFIG == *"token="* ]]; then
    TOKEN=$(echo $EDGE_CONFIG | grep -o "token=[^&]*" | cut -d= -f2)
    echo -e "${GREEN}✅ Setting API key in Edge Config...${NC}"
    curl -s -X POST "https://edge-config.vercel.com/items?token=$TOKEN" \
         -H "Content-Type: application/json" \
         -d '{
            "items": [
              {
                "key": "PROD_API_KEY",
                "value": "673274006fb6b23dc18609e7beb4b1409cb157d373abc2322e5202b47604a2e2"
              },
              {
                "key": "appConfig",
                "value": {
                  "name": "YaaS Service",
                  "version": "2.3.0",
                  "features": {
                    "analysis": true,
                    "authentication": true
                  }
                }
              }
            ]
          }'
    echo -e "${GREEN}✅ Edge Config setup complete${NC}"
else
    echo -e "${YELLOW}⚠️ Edge Config URL is invalid or missing token parameter${NC}"
fi

# 5️⃣ Update package.json with latest dependencies
echo -e "${BLUE}📦 Updating dependencies...${NC}"
cat > package.json <<EOL
{
  "name": "yaasservice.io",
  "version": "2.3.2",
  "description": "Production-Ready YaaS Service Platform",
  "main": "api/index.js",
  "type": "module",
  "scripts": {
    "start": "node api/index.js",
    "dev": "nodemon api/index.js",
    "test": "echo \"Error: no test specified\" && exit 1"
  },
  "dependencies": {
    "express": "^4.18.2",
    "serverless-http": "^3.2.0",
    "jsonwebtoken": "^9.0.2",
    "@vercel/edge-config": "^1.0.0",
    "cors": "^2.8.5"
  },
  "devDependencies": {
    "nodemon": "^2.0.22"
  }
}
EOL

# 6️⃣ Install dependencies
echo -e "${BLUE}📦 Installing dependencies...${NC}"
npm install

# 7️⃣ Create simplified serverless API
echo -e "${BLUE}🔐 Creating simplified serverless API...${NC}"
mkdir -p api
cat > api/index.js <<EOL
// YaaS Service API - v2.3.2
// Simple serverless implementation optimized for Vercel

// Helper function for CORS headers
function setCorsHeaders(res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
}

// Simple sentiment analysis function
function analyzeSentiment(text) {
  const positiveWords = ['good', 'great', 'excellent', 'awesome', 'love', 'happy'];
  const negativeWords = ['bad', 'terrible', 'awful', 'hate', 'sad'];
  
  const words = text.toLowerCase().split(/\s+/);
  let positiveCount = 0;
  let negativeCount = 0;
  
  words.forEach(word => {
    if (positiveWords.includes(word)) positiveCount++;
    if (negativeWords.includes(word)) negativeCount++;
  });
  
  let sentiment = 'neutral';
  if (positiveCount > negativeCount) sentiment = 'positive';
  if (negativeCount > positiveCount) sentiment = 'negative';
  
  return {
    sentiment,
    stats: {
      wordCount: words.length,
      positiveWords: positiveCount,
      negativeWords: negativeCount
    }
  };
}

// Main serverless handler
export default async function handler(req, res) {
  // Set CORS headers for all responses
  setCorsHeaders(res);
  
  // Handle preflight requests
  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }
  
  // Parse the URL path
  const url = new URL(req.url, \`https://\${req.headers.host || 'localhost'}\`);
  const path = url.pathname;
  
  // Health Check Endpoint
  if (path === '/api/v1/health' && req.method === 'GET') {
    return res.status(200).json({
      status: "Operational",
      version: "2.3.2",
      services: ["analysis", "health"]
    });
  }
  
  // Text Analysis Endpoint
  if (path === '/api/v1/analyze' && req.method === 'POST') {
    try {
      // Read request body
      const buffers = [];
      for await (const chunk of req) {
        buffers.push(chunk);
      }
      const data = Buffer.concat(buffers).toString();
      const { text } = JSON.parse(data);
      
      if (!text) {
        return res.status(400).json({ error: "Missing text parameter" });
      }
      
      // Generate analysis
      const analysis = analyzeSentiment(text);
      
      return res.status(200).json({
        analysisId: Date.now().toString(36),
        timestamp: new Date().toISOString(),
        textLength: text.length,
        analysis
      });
    } catch (error) {
      return res.status(500).json({ 
        error: "Analysis failed",
        message: error.message
      });
    }
  }
  
  // Default response for other API routes
  if (path.startsWith('/api/')) {
    return res.status(404).json({ 
      error: "Endpoint not found",
      availableEndpoints: [
        "/api/v1/health",
        "/api/v1/analyze"
      ]
    });
  }
  
  // Default static file handler
  return res.status(200).json({ message: "YaaS API is running" });
}
EOL

# 8️⃣ Create Vercel configuration
echo -e "${BLUE}🔧 Creating Vercel configuration...${NC}"
cat > vercel.json <<EOL
{
  "version": 2,
  "routes": [
    { "src": "/api/(.*)", "dest": "/api/index.js" },
    { "src": "/", "dest": "/public/index.html" }
  ],
  "functions": {
    "api/index.js": {
      "memory": 1024,
      "maxDuration": 5
    }
  }
}
EOL

# 9️⃣ Create simplified frontend
echo -e "${BLUE}🎨 Creating simplified frontend...${NC}"
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
      font-family: -apple-system, system-ui, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
      max-width: 800px;
      margin: 0 auto;
      padding: 20px;
      line-height: 1.6;
    }
    .card {
      background: #f8f9fa;
      border-radius: 8px;
      padding: 20px;
      margin-bottom: 20px;
      box-shadow: 0 2px 4px rgba(0,0,0,0.1);
    }
    h1 {
      color: #3949ab;
    }
    h2 {
      color: #455a64;
    }
    .status {
      padding: 10px;
      border-radius: 4px;
      margin-bottom: 20px;
    }
    .online {
      background-color: #e8f5e9;
      color: #2e7d32;
    }
    .offline {
      background-color: #ffebee;
      color: #c62828;
    }
    textarea {
      width: 100%;
      height: 100px;
      margin-bottom: 10px;
      padding: 8px;
      border: 1px solid #ddd;
      border-radius: 4px;
    }
    button {
      background: #3949ab;
      color: white;
      border: none;
      padding: 10px 15px;
      border-radius: 4px;
      cursor: pointer;
    }
    button:hover {
      background: #303f9f;
    }
    pre {
      background: #f5f5f5;
      padding: 10px;
      border-radius: 4px;
      overflow-x: auto;
    }
    footer {
      margin-top: 40px;
      text-align: center;
      color: #78909c;
      font-size: 0.9em;
    }
  </style>
</head>
<body>
  <h1>YaaS - You as a Service</h1>
  <div id="status" class="status">Checking service status...</div>
  
  <div class="card">
    <h2>Text Analysis</h2>
    <p>Enter some text to analyze the sentiment:</p>
    <textarea id="analyzeText" placeholder="Enter text to analyze..."></textarea>
    <button id="analyzeBtn">Analyze</button>
    <div id="result" style="margin-top: 20px;"></div>
  </div>
  
  <div class="card">
    <h2>API Documentation</h2>
    <p>Available endpoints:</p>
    <ul>
      <li><strong>GET /api/v1/health</strong> - Check service status</li>
      <li><strong>POST /api/v1/analyze</strong> - Analyze text sentiment</li>
    </ul>
    <p>Example API usage:</p>
    <pre>
fetch('/api/v1/analyze', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    text: 'I really like the YaaS service!'
  })
})
.then(response => response.json())
.then(data => console.log(data));</pre>
  </div>
  
  <footer>
    &copy; 2025 YaaS Service - v2.3.2
  </footer>

  <script>
    // Check service status
    fetch('/api/v1/health')
      .then(response => response.json())
      .then(data => {
        const statusElement = document.getElementById('status');
        statusElement.textContent = \`Status: \${data.status} (v\${data.version})\`;
        statusElement.className = 'status online';
      })
      .catch(error => {
        const statusElement = document.getElementById('status');
        statusElement.textContent = 'Status: Offline';
        statusElement.className = 'status offline';
      });
    
    // Setup analyze button
    document.getElementById('analyzeBtn').addEventListener('click', () => {
      const text = document.getElementById('analyzeText').value;
      if (!text) {
        alert('Please enter some text to analyze');
        return;
      }
      
      const resultElement = document.getElementById('result');
      resultElement.innerHTML = 'Analyzing...';
      
      fetch('/api/v1/analyze', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({ text })
      })
        .then(response => response.json())
        .then(data => {
          resultElement.innerHTML = \`
            <h3>Analysis Results:</h3>
            <pre>\${JSON.stringify(data, null, 2)}</pre>
          \`;
        })
        .catch(error => {
          resultElement.innerHTML = \`<p style="color: red;">Error: \${error.message}</p>\`;
        });
    });
  </script>
</body>
</html>
EOL

# 10️⃣ Commit changes
echo -e "${BLUE}📝 Committing changes...${NC}"
git add .
git commit -m "Simplified YaaS service for reliable production deployment v2.3.2" || echo -e "${YELLOW}⚠️ Nothing to commit${NC}"

# 11️⃣ Push changes with force if needed
echo -e "${BLUE}🚀 Pushing to GitHub...${NC}"
git push origin main || {
    echo -e "${YELLOW}⚠️ Push failed, trying force push...${NC}"
    read -p "Force push may overwrite remote changes. Continue? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        git push -f origin main
    else
        echo -e "${YELLOW}⚠️ Push skipped, continuing with deployment...${NC}"
    fi
}

# 12️⃣ Deploy to Vercel
echo -e "${BLUE}🚀 Deploying to Vercel...${NC}"
vercel deploy --prod || { echo -e "${RED}❌ Vercel deployment failed${NC}"; exit 1; }

# 13️⃣ Purge Cloudflare cache
echo -e "${BLUE}🧹 Purging Cloudflare cache...${NC}"
CLOUDFLARE_TOKEN="tU8_WGyIrFyI5zAJpxwcDTMMnbtE7VMtyHzDSpRh"
CLOUDFLARE_ZONE_ID="a44048aba7521e90edbddbae88f94d89"

curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$CLOUDFLARE_ZONE_ID/purge_cache" \
     -H "Authorization: Bearer $CLOUDFLARE_TOKEN" \
     -H "Content-Type: application/json" \
     --data '{"purge_everything":true}'

# 14️⃣ Wait for deployment to propagate with progressively longer retries
echo -e "${BLUE}⏳ Waiting for deployment to propagate...${NC}"
MAX_RETRIES=5
for ((i=1; i<=MAX_RETRIES; i++)); do
    sleep $((i * 5))  # Progressive waiting: 5s, 10s, 15s, etc.
    echo -e "${BLUE}🔍 Verification attempt $i of $MAX_RETRIES...${NC}"
    
    response=$(curl -s --max-time 10 https://yaasservice.io/api/v1/health || echo "Timeout")
    if [[ "$response" == *"Operational"* ]]; then
        echo -e "${GREEN}✅ Deployment successful!${NC}"
        echo -e "${GREEN}🌐 YaaS Service v2.3.2 is now live at https://yaasservice.io${NC}"
        break
    elif [[ "$response" == "Timeout" ]]; then
        echo -e "${YELLOW}⚠️ Request timed out, retrying...${NC}"
    else
        echo -e "${YELLOW}⚠️ Service not yet available, retrying...${NC}"
        echo -e "Response: $response"
    fi
    
    if [[ $i == $MAX_RETRIES ]]; then
        echo -e "${YELLOW}⚠️ Could not verify deployment after $MAX_RETRIES attempts${NC}"
        echo -e "${YELLOW}⚠️ Manual verification recommended${NC}"
    fi
done

echo -e "${BLUE}📋 Deployment summary:${NC}"
echo -e "  Version: 2.3.2"
echo -e "  API URL: https://yaasservice.io/api/v1"
echo -e "  Frontend: https://yaasservice.io"
echo -e "  Documentation: https://yaasservice.io"
echo -e "${GREEN}🎉 Deployment completed!${NC}"
