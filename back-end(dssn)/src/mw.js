// src/mw.js
import { prisma } from './lib/prisma.js';
import { verifyAccess } from './lib/jwt.js';

/** Authorization 헤더 또는 쿠키에서 토큰 추출 */
function extractToken(req) {
  const h = req.headers.authorization || '';
  if (h.startsWith('Bearer ')) return h.slice(7).trim();
  if (req.cookies?.access_token) return req.cookies.access_token;
  return null;
}

/** 공통: payload → req 컨텍스트 세팅 */
function setCtx(req, payload) {
  const id = Number(payload?.sub ?? payload?.id);
  req.user = { id, ver: payload?.ver ?? 0, sub: payload?.sub ?? payload?.id };
  req.userId = id;
  req.me = id;
}

/** 필수 인증: access 검증 + token_version 동기화 확인 */
export async function requireAuth(req, res, next) {
  const token = extractToken(req);
  if (!token) return res.status(401).json({ message: 'no token' });

  try {
    const payload = verifyAccess(token);

    // typ 필드가 있으면 access만 허용
    if (payload?.typ && payload.typ !== 'access') {
      return res.status(401).json({ message: 'invalid token type' });
    }

    const id = Number(payload?.sub ?? payload?.id);
    if (!id) return res.status(401).json({ message: 'invalid token subject' });

    // DB의 token_version과 비교 (logout/all 즉시 반영)
    const me = await prisma.user.findUnique({
      where: { id },
      select: { id: true, token_version: true },
    });
    if (!me) return res.status(401).json({ message: 'user not found' });
    if ((payload?.ver ?? 0) !== me.token_version) {
      return res.status(401).json({ message: 'token revoked' });
    }

    setCtx(req, payload);
    return next();
  } catch (e) {
    const name = e?.name || '';
    if (name === 'TokenExpiredError')
      return res.status(401).json({ message: 'token expired' });
    if (name === 'JsonWebTokenError')
      return res.status(401).json({ message: 'invalid token' });
    return res.status(401).json({ message: 'unauthorized' });
  }
}

/** 선택 인증: 있으면 검증/세팅, 실패·없음은 그냥 통과 */
export async function optionalAuth(req, res, next) {
  const token = extractToken(req);
  if (!token) return next();
  try {
    const payload = verifyAccess(token);
    if (payload?.typ && payload.typ !== 'access') return next();

    const id = Number(payload?.sub ?? payload?.id);
    if (!id) return next();

    // 조용한 ver 체크 (실패해도 통과하지만 컨텍스트는 세팅 안 함)
    const me = await prisma.user.findUnique({
      where: { id },
      select: { id: true, token_version: true },
    });
    if (!me) return next();
    if ((payload?.ver ?? 0) !== me.token_version) return next();

    setCtx(req, payload);
  } catch {
    // 무시하고 비인증 상태로 통과
  }
  return next();
}

/** 레거시 호환 */
export const requireMe = requireAuth;

/** 소유자 검증 헬퍼 */
export function assertOwner(resourceOwnerId, currentUserOrReq, res) {
  const current =
    typeof currentUserOrReq === 'number'
      ? currentUserOrReq
      : typeof currentUserOrReq?.me === 'number'
      ? currentUserOrReq.me
      : typeof currentUserOrReq?.userId === 'number'
      ? currentUserOrReq.userId
      : Number(currentUserOrReq?.user?.id);

  if (!current || Number(resourceOwnerId) !== Number(current)) {
    res.status(403).json({ message: 'forbidden: not the owner' });
    return false;
  }
  return true;
}
