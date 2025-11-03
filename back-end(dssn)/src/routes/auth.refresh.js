import { Router } from 'express';
import { prisma } from '../lib/prisma.js';
import { verifyRefresh, signAccess, signRefresh } from '../lib/jwt.js';
import { hashToken } from '../lib/token-hash.js';

const r = Router();

/**
 * POST /auth/refresh
 * body: { refresh }
 * res : { user, access, refresh }
 */
r.post('/refresh', async (req, res, next) => {
  try {
    const { refresh } = req.body ?? {};
    if (!refresh) return res.status(400).json({ error: 'refresh is required' });

    let payload;
    try {
      payload = verifyRefresh(refresh);
    } catch {
      return res.status(401).json({ error: 'Invalid refresh' });
    }

    // DB에서 존재/무효/만료 확인
    const th = hashToken(refresh);
    const db = await prisma.refresh_token.findUnique({
      where: { token_hash: th },
    });
    if (!db || db.revoked_at || db.expires_at < new Date()) {
      return res.status(401).json({ error: 'Invalid refresh' });
    }

    // 사용자·버전 확인
    const u = await prisma.user.findUnique({ where: { id: payload.sub } });
    if (!u || u.token_version !== payload.ver) {
      return res.status(401).json({ error: 'Invalid refresh' });
    }

    // 새 토큰 발급 & 회전
    const newAccess = signAccess(u);
    const newRefresh = signRefresh(u);

    const now = Date.now();
    const ttlMs = parseTtlMs(process.env.JWT_REFRESH_TTL ?? '14d');

    await prisma.$transaction([
      prisma.refresh_token.update({
        where: { token_hash: th },
        data: { revoked_at: new Date(), replaced_by: hashToken(newRefresh) },
      }),
      prisma.refresh_token.create({
        data: {
          user_id: u.id,
          token_hash: hashToken(newRefresh),
          expires_at: new Date(now + ttlMs),
        },
      }),
    ]);

    return res.json({
      user: stripUser(u),
      access: newAccess,
      refresh: newRefresh,
    });
  } catch (e) {
    next(e);
  }
});

function stripUser(u) {
  const { password, ...rest } = u;
  return rest;
}
function parseTtlMs(ttl) {
  const m = String(ttl).match(/^(\d+)([smhd])$/i);
  if (!m) return 14 * 24 * 60 * 60 * 1000;
  const n = Number(m[1]);
  const unit = m[2].toLowerCase();
  return (
    n *
    (unit === 's'
      ? 1_000
      : unit === 'm'
      ? 60_000
      : unit === 'h'
      ? 3_600_000
      : 86_400_000)
  );
}

export default r;
