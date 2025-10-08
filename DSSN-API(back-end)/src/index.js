import express from 'express';
import cors from 'cors';
import morgan from 'morgan';
import helmet from 'helmet';
import compression from 'compression';
import rateLimit from 'express-rate-limit';
import communities from './communities.js';
import follows from './follows.js';
import chats from './chats.js';
import users from './users.js';
import 'dotenv/config';

import posts from './posts.js';
import feed from './feed.js';
import interactions from './interactions.js';
import comments from './comments.js';
import { prisma } from './lib/prisma.js';

const app = express();

app.use(helmet());
app.use(compression());
app.use(rateLimit({ windowMs: 60_000, max: 120 }));

app.use(cors({ origin: true, credentials: true }));
app.use(express.json());
app.use(morgan('dev'));

app.get('/', (_req, res) =>
  res.json({ ok: true, service: 'DSSN API', ts: new Date().toISOString() })
);

app.get('/health', async (_req, res, next) => {
  try {
    const rows = await prisma.$queryRaw`SELECT NOW() as now`;
    res.json({ ok: true, dbTime: rows[0].now });
  } catch (e) {
    next(e);
  }
});

app.use('/posts', posts);
app.use('/feed', feed);
app.use('/', interactions); // /likes, /bookmarks, /reposts
app.use('/comments', comments);
app.use('/communities', communities);
app.use('/follows', follows);
app.use('/', chats);
app.use('/users', users);
app.use('/', interactions);

app.use((_req, res) => res.status(404).json({ message: 'Not Found' }));
app.use((err, _req, res, _next) => {
  console.error(err);
  res.status(500).json({
    message: 'Internal error',
    detail:
      process.env.NODE_ENV !== 'production'
        ? String(err.message || err)
        : undefined,
  });
});

const PORT = process.env.PORT || 3000;
const server = app.listen(PORT, () =>
  console.log(`✅ http://localhost:${PORT}`)
);

const shutdown = async (sig) => {
  console.log(`\n${sig} received. Shutting down...`);
  await prisma.$disconnect();
  server.close(() => process.exit(0));
};
process.on('SIGINT', () => shutdown('SIGINT'));
process.on('SIGTERM', () => shutdown('SIGTERM'));
