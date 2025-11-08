// memory.js
import Database from 'better-sqlite3';
import { embedTexts } from './embeddings.js';

const db = new Database('memory.db');
db.exec(`
CREATE TABLE IF NOT EXISTS memories (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user TEXT NOT NULL,
  question TEXT NOT NULL,
  answer TEXT NOT NULL,
  embedding BLOB NOT NULL,
  createdAt TEXT NOT NULL
);
`);

// helper: cosine similarity
function cosine(a, b) {
  let dot = 0, na = 0, nb = 0;
  for (let i = 0; i < a.length; i++) {
    dot += a[i] * b[i];
    na += a[i] * a[i];
    nb += b[i] * b[i];
  }
  return dot / (Math.sqrt(na) * Math.sqrt(nb) + 1e-12);
}

function float32ToBuffer(arr) {
  return Buffer.from(new Float32Array(arr).buffer);
}

function bufferToFloat32Array(buf) {
  // buf is a Node Buffer; create Float32Array view
  return new Float32Array(buf.buffer, buf.byteOffset, buf.length / 4);
}

export async function remember(user, question, answer) {
  const [vec] = await embedTexts([`${question}\n\n${answer}`]);
  const buf = float32ToBuffer(vec);
  const stmt = db.prepare('INSERT INTO memories (user, question, answer, embedding, createdAt) VALUES (?, ?, ?, ?, ?)');
  stmt.run(user, question, answer, buf, new Date().toISOString());
}

export async function searchSimilar(query, k = 5) {
  const [qVec] = await embedTexts([query]);
  const rows = db.prepare('SELECT id, user, question, answer, embedding, createdAt FROM memories').all();
  const scored = rows.map(r => {
    const vec = bufferToFloat32Array(r.embedding);
    // convert typed array to plain array for cosine
    const vecArr = Array.from(vec);
    return { ...r, score: cosine(qVec, vecArr) };
  }).sort((a, b) => b.score - a.score);
  return scored.slice(0, k);
}
