// server.js
// Minimaler Fastify-Server mit RAG (Retrieval-Augmented Generation) und Feedback-Loop.
// Voraussetzungen:
// - Node 18+
// - Installierte Abhängigkeiten: fastify, dotenv, better-sqlite3 (letzteres für memory.js)
// - Dateien: embeddings.js, memory.js (siehe Chatverlauf)
//
// Nutzungsablauf:
// 1) Setze OPENAI_API_KEY in deiner Shell bzw. in .env
// 2) npm run start
// 3) POST /chat  { user?, question }
// 4) POST /feedback { user?, question, answer }

import Fastify from "fastify";
import dotenv from "dotenv";
import { searchSimilar, remember } from "./memory.js";

dotenv.config();

const server = Fastify({ logger: true });

const OPENAI_KEY = process.env.OPENAI_API_KEY;
const OPENAI_MODEL = process.env.OPENAI_MODEL || "gpt-4o-mini";

if (!OPENAI_KEY) {
  server.log.warn("OPENAI_API_KEY is not set. Please set it in the environment or .env file.");
  // Note: we do not exit here to allow health checks; chat will fail with 500 if not set.
}

// --- Health route
server.get("/", async (req, reply) => {
  return reply.send({ status: "ok", message: "Server läuft. POST /chat verwenden." });
});

// --- Chat route (RAG integrated)
server.post("/chat", async (req, reply) => {
  try {
    const { user = "default", question } = req.body ?? {};
    if (!question || typeof question !== "string") {
      return reply.status(400).send({ error: "question required" });
    }

    // 1) retrieve similar memories (k=5)
    let context = "";
    try {
      const hits = await searchSimilar(question, 5);
      if (hits && hits.length) {
        // Build a compact context string
        context = hits
          .map((h) => `Q: ${h.question}\nA: ${h.answer}`)
          .join("\n\n");
      }
    } catch (err) {
      server.log.warn({ err }, "RAG search failed - continuing without context");
    }

    // 2) build system / user messages
    const systemMessage = context
      ? `Du erhältst folgenden Kontext (verwende ihn, wenn relevant):\n\n${context}\n\nSei kurz und präzise.`
      : `Du bist ein hilfreicher Assistent. Antworte kurz und präzise.`;

    if (!process.env.OPENAI_API_KEY) {
      server.log.error("OPENAI_API_KEY not found in environment");
      return reply.status(500).send({ error: "Missing OPENAI_API_KEY" });
    }

    // 3) Call OpenAI Chat Completions
    const resp = await fetch("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${process.env.OPENAI_API_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: OPENAI_MODEL,
        messages: [
          { role: "system", content: systemMessage },
          { role: "user", content: question },
        ],
        max_tokens: 800,
        temperature: 0.2,
      }),
    });

    if (!resp.ok) {
      const txt = await resp.text();
      server.log.error({ status: resp.status, body: txt }, "OpenAI error");
      return reply
        .status(502)
        .send({ error: "OpenAI API error", status: resp.status, detail: txt });
    }

    const j = await resp.json();
    const content =
      j.choices?.[0]?.message?.content ?? j.choices?.[0]?.text ?? JSON.stringify(j);

    // 4) Return answer + whether retrieved context was used
    return reply.send({ content, retrieved: !!context, raw: j });
  } catch (err) {
    server.log.error(err);
    return reply.status(500).send({ error: "server error" });
  }
});

// --- Feedback endpoint: save Q/A into memory
server.post("/feedback", async (req, reply) => {
  try {
    const { user = "default", question, answer } = req.body ?? {};
    if (!question || !answer) {
      return reply.status(400).send({ error: "question and answer required" });
    }

    await remember(user, question, answer);
    return reply.send({ ok: true });
  } catch (err) {
    server.log.error(err);
    return reply.status(500).send({ error: "could not save feedback" });
  }
});

// --- Start server
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
