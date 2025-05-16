#!/bin/bash
# yaas_deploy.sh - Production YaaS Deployment

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

# 2️⃣ Initialize Edge Config with API key
echo -e "${BLUE}🔧 Setting up Edge Config...${NC}"
EDGE_CONFIG_URL=$(grep EDGE_CONFIG .env | cut -d= -f2)
if [ -z "$EDGE_CONFIG_URL" ]; then
    echo -e "${YELLOW}⚠️ Edge Config URL not found in .env file${NC}"
else
    TOKEN=$(echo $EDGE_CONFIG_URL | grep -o "token=[^&]*" | cut -d= -f2)
    if [ -n "$TOKEN" ]; then
        echo -e "${GREEN}➡️ Setting API key in Edge Config...${NC}"
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
        echo -e "${YELLOW}⚠️ Could not extract token from Edge Config URL${NC}"
    fi
fi

# 3️⃣ Increment version number
echo -e "${BLUE}📦 Updating version number...${NC}"
VERSION=$(grep '"version":' package.json | cut -d'"' -f4)
IFS='.' read -ra VERSION_PARTS <<< "$VERSION"
PATCH=$((VERSION_PARTS[2] + 1))
NEW_VERSION="${VERSION_PARTS[0]}.${VERSION_PARTS[1]}.$PATCH"
sed -i '' "s/\"version\": \"$VERSION\"/\"version\": \"$NEW_VERSION\"/" package.json
echo -e "${GREEN}✅ Updated version to $NEW_VERSION${NC}"

# 4️⃣ Create production-optimized API handler
echo -e "${BLUE}🔐 Creating production API handler...${NC}"
mkdir -p api
cat > api/index.js <<EOL
import express from 'express';
import serverless from 'serverless-http';
import cors from 'cors';
import jwt from 'jsonwebtoken';
import rateLimit from 'express-rate-limit';
import { get } from '@vercel/edge-config';

const app = express();

// Security middleware
app.use(cors({
  origin: [
    'https://yaasservice.io',
    'https://www.yaasservice.io',
    'https://*.vercel.app'
  ],
  methods: ['GET', 'POST', 'OPTIONS']
}));

app.use(express.json());

// Rate limiting for production
app.use(rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 100,
  keyGenerator: (req) => req.headers['x-real-ip'] || req.headers['x-forwarded-for'] || req.ip,
  standardHeaders: true,
  legacyHeaders: false
}));

// Sentiment analysis function
function analyzeSentiment(text) {
  const positiveWords = ['good', 'great', 'excellent', 'awesome', 'amazing', 'love', 'happy', 'like', 'enjoy'];
  const negativeWords = ['bad', 'terrible', 'awful', 'hate', 'dislike', 'poor', 'sad', 'angry', 'disastrous'];
  
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
  
  const confidence = Math.min(1, Math.abs(positiveCount - negativeCount) / Math.max(words.length / 10, 1));
  
  return {
    sentiment,
    confidence: parseFloat(confidence.toFixed(2)),
    stats: {
      wordCount: words.length,
      positiveWords: positiveCount,
      negativeWords: negativeCount
    }
  };
}

// Health check endpoint
app.get('/api/v1/health', (req, res) => {
  console.log('Health check hit');
  res.status(200).json({ 
    status: "Operational",
    version: "$NEW_VERSION",
    environment: process.env.NODE_ENV || 'production'
  });
});

// Token generation endpoint
app.post('/api/v1/auth/token', async (req, res) => {
  console.log('Token request received');
  const { apiKey } = req.body;
  
  if (!apiKey) {
    return res.status(400).json({ error: "API key is required" });
  }
  
  try {
    // Get the API key from Edge Config
    const validKey = await get('PROD_API_KEY');
    
    if (apiKey !== validKey) {
      return res.status(401).json({ error: "Invalid API key" });
    }
    
    // Create JWT token
    const token = jwt.sign({
      access: 'api',
      premium: true,
      iat: Math.floor(Date.now() / 1000),
      exp: Math.floor(Date.now() / 1000) + (60 * 60) // 1 hour
    }, process.env.JWT_SECRET);
    
    res.json({
      token,
      expiresIn: '1h',
      tokenType: 'Bearer'
    });
    
  } catch (error) {
    console.error('Error in token generation:', error);
    res.status(500).json({ error: "Internal server error" });
  }
});

// Text analysis endpoint
app.post('/api/v1/analyze', (req, res) => {
  console.log('Analyze request received');
  const { text } = req.body;
  
  if (!text) {
    return res.status(400).json({ error: "Text is required" });
  }
  
  // Check for premium features
  let isPremium = false;
  const authHeader = req.headers.authorization;
  
  if (authHeader && authHeader.startsWith('Bearer ')) {
    try {
      const token = authHeader.split(' ')[1];
      const decoded = jwt.verify(token, process.env.JWT_SECRET);
      isPremium = decoded.premium === true;
    } catch (err) {
      // Continue with basic analysis if token is invalid
    }
  }
  
  // Perform sentiment analysis
  const analysis = analyzeSentiment(text);
  
  // Add premium features if applicable
  if (isPremium) {
    analysis.premium = {
      keyPhrases: text.split(/[.!?]/).filter(s => s.trim().length > 10).map(s => s.trim()).slice(0, 3),
      languageDetection: 'en',
      readabilityScore: Math.min(100, Math.max(0, 50 + text.length / 20))
    };
  }
  
  // Generate unique ID
  const analysisId = Date.now().toString(36) + Math.random().toString(36).substring(2, 8);
  
  res.json({
    analysisId,
    timestamp: new Date().toISOString(),
    premium: isPremium,
    textLength: text.length,
    analysis
  });
});

// Create serverless handler
const handler = serverless(app);

// Export for Vercel
export default async function(req, res) {
  return handler(req, res);
}
EOL

# 5️⃣ Commit changes to Git
echo -e "${BLUE}📝 Committing changes...${NC}"
git add .
git commit -m "Production deployment v$NEW_VERSION" || echo -e "${YELLOW}⚠️ Nothing to commit${NC}"
git push origin main || echo -e "${YELLOW}⚠️ Push failed, continuing...${NC}"

# 6️⃣ Deploy to Vercel
echo -e "${BLUE}🚀 Deploying to Vercel...${NC}"
vercel deploy --prod || { echo -e "${RED}❌ Vercel deployment failed${NC}"; exit 1; }

# 7️⃣ Purge Cloudflare cache
echo -e "${BLUE}🧹 Purging Cloudflare cache...${NC}"
CLOUDFLARE_TOKEN="tU8_WGyIrFyI5zAJpxwcDTMMnbtE7VMtyHzDSpRh"
CLOUDFLARE_ZONE_ID="a44048aba7521e90edbddbae88f94d89"

curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$CLOUDFLARE_ZONE_ID/purge_cache" \
     -H "Authorization: Bearer $CLOUDFLARE_TOKEN" \
     -H "Content-Type: application/json" \
     --data '{"purge_everything":true}'

# 8️⃣ Wait for deployment to propagate
echo -e "${BLUE}⏳ Waiting for deployment to propagate...${NC}"
sleep 15

# 9️⃣ Verify deployment
echo -e "${BLUE}🔍 Verifying deployment...${NC}"
response=$(curl -s https://yaasservice.io/api/v1/health)
if [[ "$response" == *"Operational"* ]]; then
    echo -e "${GREEN}✅ Deployment successful!${NC}"
    echo -e "${GREEN}🌐 YaaS Service v$NEW_VERSION is now live at https://yaasservice.io${NC}"
else
    echo -e "${RED}❌ Deployment verification failed!${NC}"
    echo -e "Response: $response"
fi

echo -e "${BLUE}📋 Deployment summary:${NC}"
echo -e "  Version: $NEW_VERSION"
echo -e "  API URL: https://yaasservice.io/api/v1"
echo -e "  Frontend: https://yaasservice.io"
echo -e "  Documentation: https://yaasservice.io/#docs"
echo -e "${GREEN}🎉 Deployment completed!${NC}"
