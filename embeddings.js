// embeddings.js
// ruft OpenAI Embeddings API auf (Node 18+ fetch global)
export async function embedTexts(texts) {
  if (!process.env.OPENAI_API_KEY) throw new Error('Missing OPENAI_API_KEY');
  const res = await fetch('https://api.openai.com/v1/embeddings', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${process.env.OPENAI_API_KEY}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      model: 'text-embedding-3-small',
      input: texts
    })
  });
  if (!res.ok) {
    const txt = await res.text();
    throw new Error(`Embeddings API error: ${res.status} ${txt}`);
  }
  const j = await res.json();
  return j.data.map(d => d.embedding);
}
