import { Router } from 'express';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { prisma } from '../lib/prisma.js';

const r = Router();
const signToken = (uid) =>
  jwt.sign({ sub: uid }, process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_EXPIRES || '7d',
  });

/** POST /auth/login  (username 또는 email + password) */
r.post('/', async (req, res, next) => {
  try {
    const username = (req.body?.username ?? '').trim();
    const email = (req.body?.email ?? '').trim().toLowerCase();
    const password = String(req.body?.password ?? '');

    if ((!username && !email) || !password)
      return res
        .status(400)
        .json({ message: 'username or email, and password required' });

    const user = await prisma.user.findFirst({
      where: {
        OR: [
          username ? { username } : undefined,
          email ? { email } : undefined,
        ].filter(Boolean),
      },
    });
    if (!user) return res.status(401).json({ message: 'invalid credentials' });

    const ok = await bcrypt.compare(password, user.password);
    if (!ok) return res.status(401).json({ message: 'invalid credentials' });

    const token = signToken(user.id);
    res.json({
      token,
      user: {
        id: user.id,
        username: user.username,
        email: user.email,
        nickname: user.nickname,
        email_verified: user.email_verified,
      },
    });
  } catch (e) {
    next(e);
  }
});

export default r;
