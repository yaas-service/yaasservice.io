#!/bin/bash
# yaas_deploy_fix.sh - Final Deployment Fix Script

# 1️⃣ Environment Setup
echo "🔧 Setting up environment variables..."
cat > .env <<EOL
NODE_ENV=production
PORT=3000
JWT_SECRET=your-secure-jwt-secret-key
API_KEY=673274006fb6b23dc18609e7beb4b1409cb157d373abc2322e5202b47604a2e2
EDGE_CONFIG=https://edge-config.vercel.com/ecfg_gveuibvpzuj4zxspyq137vjdfjoq?token=c8172981-b544-4dc3-aa19-81d19f9cbf69
ENABLE_PREMIUM=true
EOL

# 2️⃣ Update Edge Config
echo "⚙️  Configuring Edge Config..."
curl -X PATCH "https://api.vercel.com/v1/edge-config/ecfg_gveuibvpzuj4zxspyq137vjdfjoq/items" \
  -H "Authorization: Bearer $VERCEL_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "items": [
      {
        "operation": "upsert",
        "key": "PROD_API_KEY",
        "value": "673274006fb6b23dc18609e7beb4b1409cb157d373abc2322e5202b47604a2e2"
      }
    ]
  }'

# 3️⃣ Update API Code
echo "🚀 Updating API Implementation..."
cat > api/index.js <<EOL
import express from 'express';
import serverless from 'serverless-http';
import cors from 'cors';
import jwt from 'jsonwebtoken';
import rateLimit from 'express-rate-limit';
import { get } from '@vercel/edge-config';
import dotenv from 'dotenv';

// Initialize environment
dotenv.config();

// Constants
const PORT = process.env.PORT || 3000;
const FALLBACK_API_KEY = '673274006fb6b23dc18609e7beb4b1409cb157d373abc2322e5202b47604a2e2';
const FALLBACK_JWT_SECRET = 'fallback-secret-for-development';

// Create Express app
const app = express();

// Middleware
app.use(cors({
  origin: ['https://yaasservice.io', 'http://localhost:3000'],
  methods: ['GET', 'POST', 'OPTIONS']
}));
app.use(express.json());

// Rate Limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 100,
  validate: { trustProxy: true }
});
app.use(limiter);

// Health Check
app.get('/api/v1/health', (req, res) => {
  res.status(200).json({
    status: "Operational",
    version: "2.3.0",
    environment: process.env.NODE_ENV
  });
});

// Authentication Endpoint
app.post('/api/v1/auth/token', async (req, res) => {
  const { apiKey } = req.body;
  
  try {
    // Get valid API key
    let validKey = process.env.API_KEY || FALLBACK_API_KEY;
    
    if (process.env.EDGE_CONFIG) {
      try {
        const edgeKey = await get('PROD_API_KEY');
        if (edgeKey) validKey = edgeKey;
      } catch (error) {
        console.log('⚠️ Using local API key due to Edge Config error');
      }
    }

    if (!apiKey || apiKey !== validKey) {
      return res.status(401).json({ error: "Invalid API Key" });
    }

    // Generate JWT
    const token = jwt.sign(
      { access: 'basic' },
      process.env.JWT_SECRET || FALLBACK_JWT_SECRET,
      { expiresIn: '1h' }
    );

    res.json({ token, expiresIn: '1h' });

  } catch (error) {
    console.error('Authentication error:', error);
    res.status(500).json({ error: "Internal Server Error" });
  }
});

// Analysis Endpoint
app.post('/api/v1/analyze', (req, res) => {
  const { text } = req.body;
  
  if (!text) {
    return res.status(400).json({ error: "Missing text parameter" });
  }
  
  res.json({
    analysisId: Date.now().toString(36),
    textLength: text.length,
    timestamp: new Date().toISOString()
  });
});

// Local Development Server
if (process.env.NODE_ENV !== 'production') {
  app.listen(PORT, () => {
    console.log(\`🚀 Server running on port \${PORT}\`);
  });
}

// Export for Vercel
export const handler = serverless(app);
EOL

# 4️⃣ Update Vercel Config
echo "🔧 Updating Vercel Configuration..."
cat > vercel.json <<EOL
{
  "version": 2,
  "builds": [
    {
      "src": "api/index.js",
      "use": "@vercel/node"
    }
  ],
  "routes": [
    { "src": "/api/(.*)", "dest": "api/index.js" },
    { "src": "/(.*)", "dest": "public/index.html" }
  ]
}
EOL

# 5️⃣ Cleanup and Deployment
echo "🚀 Deploying Updates..."
rm -rf node_modules package-lock.json
npm install
vercel deploy --prod

# 6️⃣ Post-Deploy Checks
echo "🔍 Running Post-Deploy Checks..."
sleep 15 # Wait for deployment to stabilize

# Health Check
echo "🩺 Performing Health Check..."
curl -s https://yaasservice.io/api/v1/health | jq

# Token Generation Test
echo "🔑 Testing Token Generation..."
curl -s -X POST https://yaasservice.io/api/v1/auth/token \
  -H "Content-Type: application/json" \
  -d '{"apiKey":"673274006fb6b23dc18609e7beb4b1409cb157d373abc2322e5202b47604a2e2"}' | jq

# Analysis Test
echo "🔍 Testing Analysis Endpoint..."
curl -s -X POST https://yaasservice.io/api/v1/analyze \
  -H "Content-Type: application/json" \
  -d '{"text":"Testing YaaS Service Analyze API"}' | jq

echo "✅ Deployment Complete!"
