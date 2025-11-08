/*
 server.js - minimaler Fastify Chat-Server (Node >=18)
 Verwende .env mit OPENAI_API_KEY=sk-... (NICHT ins Repo committen)
*/
import Fastify from "fastify";
import dotenv from "dotenv";

dotenv.config();

const server = Fastify({ logger: true });
// Health / root route
server.get('/', async (req, reply) => {
  return reply.send({ status: "ok", message: "Server läuft. POST /chat verwenden." });
});

const OPENAI_KEY = process.env.OPENAI_API_KEY;
const OPENAI_MODEL = process.env.OPENAI_MODEL || "gpt-4o-mini";

if (!OPENAI_KEY) {
  server.log.error("Missing OPENAI_API_KEY in environment (.env).");
  process.exit(1);
}

// Body parser

// POST /chat
// Body: { user?: string, question: string }
server.post("/chat", async (req, reply) => {
  try {
    const { user = "default", question } = req.body ?? {};
    if (!question || typeof question !== "string") {
      return reply.status(400).send({ error: "question required" });
    }

    const resp = await fetch("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${OPENAI_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: OPENAI_MODEL,
        messages: [
          { role: "system", content: "You are a helpful, concise assistant." },
          { role: "user", content: question }
        ],
        max_tokens: 800,
        temperature: 0.2
      })
    });

    if (!resp.ok) {
      const txt = await resp.text();
      server.log.error({ status: resp.status, body: txt }, "OpenAI error");
      return reply.status(502).send({ error: "OpenAI API error", status: resp.status, detail: txt });
    }

    const j = await resp.json();
    const content = j.choices?.[0]?.message?.content ?? j.choices?.[0]?.text ?? JSON.stringify(j);
    return reply.send({ content, raw: j });
  } catch (err) {
    server.log.error(err);
    return reply.status(500).send({ error: "server error" });
  }
});

const start = async () => {
  try {
    await server.listen({ port: 8787, host: "0.0.0.0" });
    server.log.info("Server listening on http://localhost:8787");
  } catch (err) {
    server.log.error(err);
    process.exit(1);
  }
};

start();


















