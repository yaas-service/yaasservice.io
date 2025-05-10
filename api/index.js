
export default function handler(req, res) {
    if (req.method === 'POST') {
        res.status(200).json({ response: "yes" });
    } else if (req.method === 'GET' && req.url === '/api/status') {
        res.status(200).json({ status: "operational" });
    } else {
        res.status(404).json({ error: "Not Found" });
    }
}
