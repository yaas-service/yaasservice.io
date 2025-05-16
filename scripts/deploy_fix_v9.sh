#!/bin/bash

# 1️⃣ Navigate to Project Directory
echo "Switching to Project Directory..."
cd ~/yaasservice.io || exit

# 2️⃣ Install Dependencies
echo "Installing Dependencies..."
rm -rf node_modules package-lock.json
npm install

# 3️⃣ Update API Handler
echo "Updating API Handler..."
cat > api/index.js <<EOL
import express from 'express';
import serverless from 'serverless-http';

const app = express();
app.use(express.json());

const PORT = process.env.PORT || 8080;

app.get('/api/v1/health', (req, res) => {
  console.log('Health Check Invoked');
  try {
    res.status(200).json({ status: "YaaS Service is Running!" });
  } catch (error) {
    console.error('Error in health check:', error.message);
    res.status(500).json({ error: "Internal Server Error" });
  }
});

if (process.env.NODE_ENV === 'development') {
  app.listen(PORT, () => {
    console.log(`Local server running at http://localhost:${PORT}`);
  });
}

export default app;
export const handler = serverless(app);
EOL
echo "API handler updated successfully."

# 4️⃣ Update Vercel Configuration
echo "Updating Vercel Configuration..."
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
echo "Vercel configuration updated successfully."

# 5️⃣ Stage, Commit, and Push Changes
echo "Staging Changes..."
git add .
git commit -m "Fix ES Modules, handler export, and Vercel routing configuration"
git push origin main

# 6️⃣ Deploy to Vercel
echo "Deploying to Vercel..."
if vercel deploy --prod; then
    echo "Vercel deployment successful."
else
    echo "Vercel deployment failed." && exit 1
fi

# 7️⃣ Purge Cloudflare Cache
echo "Purging Cloudflare Cache..."
CLOUDFLARE_TOKEN="tU8_WGyIrFyI5zAJpxwcDTMMnbtE7VMtyHzDSpRh"
CLOUDFLARE_ZONE_ID="a44048aba7521e90edbddbae88f94d89"

RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -X POST "https://api.cloudflare.com/client/v4/zones/$CLOUDFLARE_ZONE_ID/purge_cache" \
     -H "Authorization: Bearer $CLOUDFLARE_TOKEN" \
     -H "Content-Type: application/json" \
     --data '{"purge_everything":true}')

if [ "$RESPONSE" -eq 200 ]; then
    echo "Cloudflare cache purged successfully."
else
    echo "Failed to purge Cloudflare cache."
fi

# 8️⃣ Perform Health Check
echo "Performing Health Check..."
for url in "https://yaasservice.io/api/v1/health" "https://www.yaasservice.io/api/v1/health"; do
    echo "Testing: $url"
    response=$(curl -s -o /dev/null -w "%{http_code}" -L $url)
    if [ "$response" -eq 200 ]; then
        echo "Health Check Passed for $url"
    else
        echo "Health Check Failed for $url with status code $response"
    fi
done

echo "Deployment and Health Check Completed."
echo "If there are issues, check the logs: vercel logs https://yaasservice.io/api/v1/health"

# 9️⃣ Logs Option
echo "Would you like to view logs?"
select yn in "Real-time" "Last 30 Minutes" "No"; do
    case $yn in
        "Real-time" ) vercel logs https://yaasservice.io/api/v1/health --scope yaas-services-projects --no-color; break;;
        "Last 30 Minutes" ) vercel logs https://yaasservice.io/api/v1/health --scope yaas-services-projects --since 30m --no-color; break;;
        "No" ) echo "Deployment Complete. Exiting..."; exit;;
    esac
done

