import { Router } from 'express';
import bcrypt from 'bcryptjs';
import { prisma } from '../lib/prisma.js';
import { signAccess, signRefresh } from '../lib/jwt.js';
import { hashToken } from '../lib/token-hash.js';

const r = Router();

/**
 * POST /auth/login
 * body: { usernameOrEmail, password }
 * res : { user, access, refresh }
 */
r.post('/login', async (req, res, next) => {
  try {
    const { usernameOrEmail, password } = req.body ?? {};
    if (!usernameOrEmail || !password) {
      return res
        .status(400)
        .json({ error: 'usernameOrEmail and password are required' });
    }

    const idOrEmail = String(usernameOrEmail).trim();
    const u = await prisma.user.findFirst({
      where: {
        OR: [
          { username: idOrEmail },
          { email: idOrEmail.toLowerCase() }, // 이메일 소문자 정규화
        ],
      },
    });
    if (!u) return res.status(401).json({ error: 'Invalid credentials' });

    const ok = await bcrypt.compare(String(password), u.password);
    if (!ok) return res.status(401).json({ error: 'Invalid credentials' });

    // 액세스/리프레시 발급
    const access = signAccess(u);
    const refresh = signRefresh(u);

    // refresh 저장(해시) + 만료
    const now = Date.now();
    const ttlMs = parseTtlMs(process.env.JWT_REFRESH_TTL ?? '14d');
    await prisma.refresh_token.create({
      data: {
        user_id: u.id,
        token_hash: hashToken(refresh),
        expires_at: new Date(now + ttlMs),
      },
    });

    return res.json({ user: stripUser(u), access, refresh });
  } catch (e) {
    next(e);
  }
});

function stripUser(u) {
  if (!u) return u;
  const { password, ...rest } = u;
  return rest;
}

// '15m' | '1h' | '7d' → ms
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
