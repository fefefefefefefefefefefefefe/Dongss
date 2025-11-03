// src/lib/me.js
import jwt from 'jsonwebtoken';

export function getMe(req) {
  // 1) Bearer 토큰 우선
  const auth = req.headers.authorization || '';
  const token = auth.startsWith('Bearer ') ? auth.slice(7) : null;
  if (token) {
    try {
      const payload = jwt.verify(token, process.env.JWT_SECRET);
      return Number(payload.sub);
    } catch (_) {
      /* ignore */
    }
  }
}
