import { getMe } from './lib/me.js';

export function requireMe(req, res, next) {
  const me = getMe(req);
  if (!me)
    return res.status(401).json({ message: 'x-user-id header required' });
  req.me = me;
  next();
}

export function assertOwner(ownerId, me, res) {
  if (ownerId !== me) {
    res.status(403).json({ message: 'forbidden' });
    return false;
  }
  return true;
}

export const toInt = (v) => Number.parseInt(v, 10);
