
module.exports = (req, res) => {
  if (req.method === 'POST') {
    console.log("Received request:", req.body);
    res.status(200).json({ response: "yes" });
  } else if (req.method === 'GET' && req.url === '/status') {
    res.status(200).json({ status: "operational" });
  } else {
    res.status(404).json({ error: "Not Found" });
  }
};

