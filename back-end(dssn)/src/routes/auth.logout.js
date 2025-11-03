import { Router } from 'express';
import { prisma } from '../lib/prisma.js';
import { requireMe } from '../mw.js';
import { hashToken } from '../lib/token-hash.js';

const r = Router();

/** POST /auth/logout – 현재 기기 로그아웃(해당 refresh 무효화) */
r.post('/logout', requireMe, async (req, res, next) => {
  try {
    const { refresh } = req.body ?? {};
    if (!refresh) return res.status(400).json({ error: 'refresh is required' });

    const th = hashToken(refresh);
    const rt = await prisma.refresh_token.findUnique({
      where: { token_hash: th },
    });

    // 정보 노출 방지: 소유자 불일치/없음이어도 성공처럼 응답
    if (rt && rt.user_id === req.me && !rt.revoked_at) {
      await prisma.refresh_token.update({
        where: { token_hash: th },
        data: { revoked_at: new Date() },
      });
    }
    return res.json({ ok: true });
  } catch (e) {
    next(e);
  }
});

/** POST /auth/logout/all – 모든 기기에서 로그아웃 */
r.post('/logout/all', requireMe, async (req, res, next) => {
  try {
    await prisma.refresh_token.updateMany({
      where: { user_id: req.me, revoked_at: null },
      data: { revoked_at: new Date() },
    });
    // 토큰 버전 증가 → 기존 access 토큰도 검증 시 무효화
    await prisma.user.update({
      where: { id: req.me },
      data: { token_version: { increment: 1 } },
    });
    return res.json({ ok: true });
  } catch (e) {
    next(e);
  }
});

export default r;
