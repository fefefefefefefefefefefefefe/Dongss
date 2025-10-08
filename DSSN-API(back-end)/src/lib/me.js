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
  // 2) 임시: x-user-id 헤더(개발용)
  const h = req.headers['x-user-id'];
  if (h && /^\d+$/.test(String(h))) return Number(h);
  return null;
}
