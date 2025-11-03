import jwt from 'jsonwebtoken';

const ACCESS_SECRET = process.env.JWT_ACCESS_SECRET ?? 'access-secret';
const REFRESH_SECRET = process.env.JWT_REFRESH_SECRET ?? 'refresh-secret';
const ACCESS_TTL = process.env.JWT_ACCESS_TTL ?? '15m'; // 예: 15m
const REFRESH_TTL = process.env.JWT_REFRESH_TTL ?? '14d'; // 예: 14d

export function signAccess(user) {
  return jwt.sign({ sub: user.id, ver: user.token_version }, ACCESS_SECRET, {
    expiresIn: ACCESS_TTL,
  });
}
export function signRefresh(user) {
  return jwt.sign({ sub: user.id, ver: user.token_version }, REFRESH_SECRET, {
    expiresIn: REFRESH_TTL,
  });
}
export function verifyAccess(token) {
  return jwt.verify(token, ACCESS_SECRET);
}
export function verifyRefresh(token) {
  return jwt.verify(token, REFRESH_SECRET);
}
