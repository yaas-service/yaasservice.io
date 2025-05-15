import express from 'express';
import serverless from 'serverless-http';

const app = express();
app.use(express.json());

const PORT = process.env.PORT || 8080;

// Health Check Route
app.get('/api/v1/health', (req, res) => {
  console.log('🌐 Health Check Invoked');
  try {
    res.status(200).json({ status: "YaaS Service is Running!" });
  } catch (error) {
    console.error('🔥 Error in health check:', error.message);
    res.status(500).json({ error: "Internal Server Error" });
  }
});

// Local development server
if (process.env.NODE_ENV === 'development') {
  app.listen(PORT, () => {
    console.log(`🌐 Local server running at http://localhost:${PORT}`);
  });
}

// ✅ Correct ES Module export
export default serverless(app);
