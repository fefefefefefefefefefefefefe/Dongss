export function getMe(req) {
  const v = req.headers['x-user-id'] ?? req.query.me;
  const id = Number(v);
  return Number.isFinite(id) && id > 0 ? id : null;
}
