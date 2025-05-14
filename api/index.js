import express from 'express';
const app = express();
const PORT = process.env.PORT || 8080;

app.use(express.json());

// Health Check Route
app.get('/api/v1/health', (req, res) => {
  console.log('Health Check Invoked');
  res.status(200).json({ status: "YaaS Service is Running!" });
});

// Vercel Serverless Function Handler
export default app;
