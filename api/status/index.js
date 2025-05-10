export default function handler(req, res) {
    if (req.method === 'GET') {
        res.status(200).json({ status: "operational" });
    } else {
        res.status(404).json({ error: "Not Found" });
    }
}

