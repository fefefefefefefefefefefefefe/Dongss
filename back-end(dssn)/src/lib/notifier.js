// /src/lib/notifier.js
// 유저별 SSE 구독자 관리 + 푸시
const clients = new Map(); // userId:number -> Set<Response>

export function sseAttach(userId, res) {
  const id = Number(userId);
  if (!clients.has(id)) clients.set(id, new Set());
  clients.get(id).add(res);

  res.on('close', () => {
    try {
      clients.get(id)?.delete(res);
      if (!clients.get(id)?.size) clients.delete(id);
    } catch {}
  });
}

export function ssePush(userId, event) {
  const set = clients.get(Number(userId));
  if (!set || set.size === 0) return 0;
  const payload = `data: ${JSON.stringify(event)}\n\n`;
  for (const res of set) {
    try {
      res.write(payload);
    } catch {}
  }
  return set.size;
}
