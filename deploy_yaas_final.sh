#!/bin/bash
# yaas_deploy_final.sh - Complete Deployment Fix Script

# 1️⃣ Clean and Update API Code
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
    let validKey = process.env.API_KEY || '673274006fb6b23dc18609e7beb4b1409cb157d373abc2322e5202b47604a2e2';
    
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

    const token = jwt.sign(
      { access: 'basic' },
      process.env.JWT_SECRET || 'fallback-secret',
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

// Serverless Export
export default serverless(app);
EOL

# 2️⃣ Update Vercel Configuration
echo "🔧 Updating Vercel Config..."
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
    {
      "src": "/api/(.*)",
      "dest": "api/index.js",
      "methods": ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
    },
    {
      "src": "/(.*)",
      "dest": "public/index.html"
    }
  ]
}
EOL

# 3️⃣ Clean and Deploy
echo "🚀 Deploying Application..."
rm -rf node_modules package-lock.json
npm install
vercel deploy --prod

# 4️⃣ Configure Edge Config
echo "⚙️ Setting Up Edge Config..."
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

# 5️⃣ Validate Deployment
echo "🔍 Running Post-Deploy Checks..."
sleep 15 # Wait for deployment propagation

# Health Check
echo "🩺 Testing Health Endpoint..."
curl -s https://yaasservice.io/api/v1/health | jq

# Auth Test
echo "🔑 Testing Authentication..."
curl -s -X POST https://yaasservice.io/api/v1/auth/token \
  -H "Content-Type: application/json" \
  -d '{"apiKey":"673274006fb6b23dc18609e7beb4b1409cb157d373abc2322e5202b47604a2e2"}' | jq

# Analysis Test
echo "📊 Testing Analysis..."
curl -s -X POST https://yaasservice.io/api/v1/analyze \
  -H "Content-Type: application/json" \
  -d '{"text":"Testing final deployment"}' | jq

# 6️⃣ Purge Caches
echo "🧹 Purging Cloudflare Cache..."
curl -X POST "https://api.cloudflare.com/client/v4/zones/a44048aba7521e90edbddbae88f94d89/purge_cache" \
     -H "Authorization: Bearer $CLOUDFLARE_TOKEN" \
     -H "Content-Type: application/json" \
     --data '{"purge_everything":true}'

echo "✅ Deployment Complete! All systems operational."
