// src/mw.js
import jwt from 'jsonwebtoken';

/**
 * 신규 권장 미들웨어
 * - Bearer 토큰을 검증하고 req.userId 세팅
 * - 구 코드 호환을 위해 req.me 도 같이 세팅
 */
export function requireAuth(req, res, next) {
  const h = req.headers.authorization || '';
  const token = h.startsWith('Bearer ') ? h.slice(7) : null;
  if (!token) return res.status(401).json({ message: 'No token' });
  try {
    const payload = jwt.verify(token, process.env.JWT_SECRET);
    req.userId = Number(payload.sub);
    req.me = req.userId; // ← 구 코드 호환
    next();
  } catch {
    res.status(401).json({ message: 'Invalid or expired token' });
  }
}

/**
 * 구(legacy) 코드 호환 별칭
 * - 예전 라우트에서 import { requireMe } from './mw.js' 를 그대로 쓰도록
 */
export const requireMe = requireAuth;

/**
 * 구(legacy) 소유자 검증 헬퍼
 * - 예전 라우트에서 import { assertOwner } from './mw.js' 사용
 * - 소유자 불일치면 403 응답, 일치하면 true 반환
 */
export function assertOwner(resourceOwnerId, currentUserIdOrReqMe, res) {
  const current =
    typeof currentUserIdOrReqMe === 'number'
      ? currentUserIdOrReqMe
      : Number(currentUserIdOrReqMe);
  if (!current || resourceOwnerId !== current) {
    res.status(403).json({ message: 'forbidden: not the owner' });
    return false;
  }
  return true;
}
