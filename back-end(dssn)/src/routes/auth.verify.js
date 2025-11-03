import { Router } from 'express';
import { prisma } from '../lib/prisma.js';

const r = Router();
const code6 = () => Math.floor(100000 + Math.random() * 900000).toString();

/** POST /auth/resend-code  { email }  */
r.post('/resend-code', async (req, res, next) => {
  try {
    const email = String(req.body?.email ?? '')
      .trim()
      .toLowerCase();
    if (!email) return res.status(400).json({ message: 'email required' });

    const user = await prisma.user.findUnique({ where: { email } });
    if (!user) return res.status(404).json({ message: 'user not found' });

    const code = code6();
    const expires = new Date(Date.now() + 15 * 60 * 1000);

    await prisma.emailVerification.create({
      data: {
        email,
        code,
        purpose: 'signup',
        expiresAt: expires,
        userId: user.id,
      },
    });

    // 개발 편의: 코드도 응답(운영에선 메일 발송만)
    res.json({ ok: true, code, expiresAt: expires.toISOString() });
  } catch (e) {
    next(e);
  }
});

/** POST /auth/verify-email  { email, code } */
r.post('/verify-email', async (req, res, next) => {
  try {
    const email = String(req.body?.email ?? '')
      .trim()
      .toLowerCase();
    const code = String(req.body?.code ?? '').trim();
    if (!email || !code)
      return res.status(400).json({ message: 'email and code required' });

    const rec = await prisma.emailVerification.findFirst({
      where: {
        email,
        code,
        purpose: 'signup',
        consumedAt: null,
        expiresAt: { gt: new Date() },
      },
    });
    if (!rec)
      return res.status(400).json({ message: 'invalid or expired code' });

    await prisma.$transaction(async (tx) => {
      await tx.emailVerification.update({
        where: { id: rec.id },
        data: { consumedAt: new Date() },
      });
      if (rec.userId) {
        await tx.user.update({
          where: { id: rec.userId },
          data: { email_verified: true },
        });
      }
    });

    res.json({ ok: true, email_verified: true });
  } catch (e) {
    next(e);
  }
});

export default r;
