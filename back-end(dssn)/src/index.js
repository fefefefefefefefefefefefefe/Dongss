// src/index.js
import 'dotenv/config';
import express from 'express';
import path from 'path';
import cors from 'cors';
import morgan from 'morgan';
import helmet from 'helmet';
import compression from 'compression';
import rateLimit from 'express-rate-limit';

import upload from './upload.js';
import { prisma } from './lib/prisma.js';

// 라우터들
import posts from './posts.js';
import feed from './feed.js';
import interactions from './interactions.js';
import comments from './comments.js';
import communities from './communities.js';
import notifications from './notifications.js';
import follows from './follows.js';
import chats from './chats.js';
import users from './routes/users.js';

import register from './routes/auth.register.js';
import login from './routes/auth.login.js';
import refresh from './routes/auth.refresh.js'; // 파일 위치 그대로라면 OK
import logout from './routes/auth.logout.js';
import verify from './routes/auth.verify.js';

import tagsTrending from './tags.trending.js';
import suggest from './suggest.js';
import search from './search.js';

const app = express();

/* ── 보안/성능 기본 미들웨어 ─────────────────────────────────────────── */
app.use(
  helmet({
    crossOriginResourcePolicy: { policy: 'cross-origin' },
  })
);
app.use(cors({ origin: true, credentials: true }));
app.use(express.json({ limit: '1mb' }));
app.use(compression());
app.use(morgan(process.env.NODE_ENV === 'production' ? 'combined' : 'dev'));

/* ── 레이트 리밋 ─────────────────────────────────────────────────────── */
const globalLimiter = rateLimit({
  windowMs: 60_000,
  max: 120,
  standardHeaders: true,
});
app.use(globalLimiter);

// 로그인 엔드포인트 전용 리밋 (라우터 마운트보다 먼저)
const loginLimiter = rateLimit({
  windowMs: 10 * 60_000,
  max: 50,
  standardHeaders: true,
});
app.use('/auth/login', loginLimiter);

/* ── 헬스/루트 ───────────────────────────────────────────────────────── */
app.get('/', (_req, res) =>
  res.json({ ok: true, service: 'DSSN API', ts: new Date().toISOString() })
);

app.get('/health', async (_req, res, next) => {
  try {
    const rows = await prisma.$queryRaw`SELECT NOW() as now`;
    res.json({ ok: true, dbTime: rows?.[0]?.now ?? null });
  } catch (e) {
    next(e);
  }
});

/* ── 라우트 마운트 ──────────────────────────────────────────────────── */
// 리소스 라우트
app.use('/posts', posts);
app.use('/feed', feed);
app.use('/comments', comments);
app.use('/communities', communities);
app.use('/follows', follows);
app.use('/notifications', notifications);
app.use('/tags', tagsTrending);
app.use('/suggest', suggest);
app.use('/users', users);
app.use('/search', search);

// 내부에서 절대경로(/likes, /reposts, /chats/...)를 선언한 라우터는 루트에
app.use('/', interactions);
app.use('/', chats);

// 인증 라우트 — **중요: 모두 '/auth'에만 마운트**
app.use('/auth', register); // 파일 안: r.post('/register', ...)
app.use('/auth', login); // 파일 안: r.post('/login', ...)
app.use('/auth', refresh); // 파일 안: r.post('/refresh', ...)
app.use('/auth', logout); // 파일 안: r.post('/logout'), r.post('/logout/all')
app.use('/auth', verify); // 파일 안: r.post('/verify-email'), r.post('/resend-code')

/* ── 정적/업로드 ────────────────────────────────────────────────────── */
app.use(
  '/static',
  express.static(path.resolve('uploads'), {
    fallthrough: true,
    immutable: true,
    maxAge: '30d',
  })
);
app.use('/upload', upload);

/* ── 404 핸들러 ──────────────────────────────────────────────────────── */
app.use((_req, res) => res.status(404).json({ message: 'Not Found' }));

/* ── 공통 에러 핸들러 ───────────────────────────────────────────────── */
app.use((err, req, res, next) => {
  console.error('[ERR]', err);
  if (res.headersSent) return next(err);

  const code = err?.code;
  if (code === 'P2002')
    return res
      .status(409)
      .json({ ok: false, code, message: 'unique constraint failed' });
  if (code === 'P2003')
    return res
      .status(400)
      .json({ ok: false, code, message: 'invalid reference (foreign key)' });
  if (code === 'P2025')
    return res
      .status(404)
      .json({ ok: false, code, message: 'record not found' });
  if (err?.type === 'entity.parse.failed')
    return res
      .status(400)
      .json({ ok: false, code: 'BAD_JSON', message: 'invalid JSON body' });

  return res.status(500).json({
    ok: false,
    code: 'INTERNAL',
    message: 'Internal error',
    detail:
      process.env.NODE_ENV !== 'production'
        ? err?.message || String(err)
        : undefined,
  });
});

/* ── 서버 시작/종료 ─────────────────────────────────────────────────── */
const PORT = Number(process.env.PORT || 3000);
const server = app.listen(PORT, () => {
  console.log(`✅ http://localhost:${PORT}`);
});

async function shutdown(sig) {
  console.log(`\n${sig} received. Shutting down...`);
  try {
    await prisma.$disconnect();
  } catch {}
  server.close(() => process.exit(0));
}
process.on('SIGINT', () => shutdown('SIGINT'));
process.on('SIGTERM', () => shutdown('SIGTERM'));
