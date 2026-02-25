export default async function handler(req, res) {
  const { url } = req.query;
  if (!url) return res.status(400).json({ error: 'Falta o parâmetro URL' });

  try {
    const targetUrl = decodeURIComponent(url);
    
    // Na Vercel, o corpo (body) já vem disponível em req.body
    // Se for um objeto, transformamos de volta em string para enviar para a ZN Digital
    let bodyData = "";
    if (typeof req.body === 'object') {
      bodyData = new URLSearchParams(req.body).toString();
    } else {
      bodyData = req.body;
    }

    const response = await fetch(targetUrl, {
      method: 'POST',
      headers: { 
        'Content-Type': 'application/x-www-form-urlencoded',
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0'
      },
      body: bodyData
    });

    const data = await response.json();

    // Headers para evitar erros de CORS no navegador
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
    
    return res.status(200).json(data);
  } catch (err) {
    // Se a API retornar erro ou não for JSON, capturamos aqui
    return res.status(500).json({ error: 'Erro no Proxy: ' + err.message });
  }
}
