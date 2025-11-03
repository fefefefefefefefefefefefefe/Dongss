import crypto from 'crypto';
export const hashToken = (t) =>
  crypto.createHash('sha256').update(String(t)).digest('hex');
