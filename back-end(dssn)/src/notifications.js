// /src/notifications.js
import { Router } from 'express';
import { prisma } from './lib/prisma.js';
import { requireMe } from './mw.js';
import { sseAttach, ssePush } from './lib/notifier.js';

const r = Router();

/** SSE 스트림: /notifications/stream */
r.get('/stream', requireMe, (req, res) => {
  res.setHeader('Content-Type', 'text/event-stream');
  res.setHeader('Cache-Control', 'no-cache');
  res.setHeader('Connection', 'keep-alive');
  res.flushHeaders?.();
  // 초기 핑
  res.write(`data: ${JSON.stringify({ kind: 'hello', ts: Date.now() })}\n\n`);
  sseAttach(req.me, res);
});

/** 목록: GET /notifications?limit=&cursor=&onlyUnread=0/1 */
r.get('/', requireMe, async (req, res, next) => {
  try {
    const limit = Math.min(50, Math.max(1, parseInt(req.query.limit) || 20));
    const cursor = req.query.cursor ? Number(req.query.cursor) : null;
    const onlyUnread = String(req.query.onlyUnread ?? '0') === '1';

    const where = {
      user_id: req.me,
      ...(onlyUnread ? { is_read: false } : {}),
    };
    const items = await prisma.notification.findMany({
      where,
      orderBy: { id: 'desc' },
      take: limit + 1,
      ...(cursor ? { cursor: { id: cursor }, skip: 1 } : {}),
      select: {
        id: true,
        type: true,
        message: true,
        is_read: true,
        created_at: true,
        source_user_id: true,
        related_post_id: true,
        related_comment_id: true,
        chat_message_id: true,
        chat_room_id: true,
      },
    });

    const nextCursor = items.length > limit ? items[limit].id : null;
    res.json({ items: items.slice(0, limit), nextCursor });
  } catch (e) {
    next(e);
  }
});

/** 뱃지: GET /notifications/unread-count */
r.get('/unread-count', requireMe, async (req, res, next) => {
  try {
    const count = await prisma.notification.count({
      where: { user_id: req.me, is_read: false },
    });
    res.json({ count });
  } catch (e) {
    next(e);
  }
});

/** 읽음: PATCH /notifications/read { ids:number[] } */
r.patch('/read', requireMe, async (req, res, next) => {
  try {
    const ids = Array.isArray(req.body?.ids)
      ? req.body.ids.map(Number).filter(Boolean)
      : [];
    if (!ids.length) return res.status(400).json({ error: 'ids required' });
    await prisma.notification.updateMany({
      where: { id: { in: ids }, user_id: req.me, is_read: false },
      data: { is_read: true },
    });
    const unread = await prisma.notification.count({
      where: { user_id: req.me, is_read: false },
    });
    res.json({ ok: true, unread });
  } catch (e) {
    next(e);
  }
});

/** 모두 읽음: POST /notifications/read-all */
r.post('/read-all', requireMe, async (req, res, next) => {
  try {
    await prisma.notification.updateMany({
      where: { user_id: req.me, is_read: false },
      data: { is_read: true },
    });
    res.json({ ok: true, unread: 0 });
  } catch (e) {
    next(e);
  }
});

export default r;

/* ────────── 외부에서 사용할 생성 헬퍼 ────────── */
export async function notifyAndPersist(targetUserId, payload) {
  const n = await prisma.notification.create({
    data: {
      user_id: targetUserId,
      type: payload.type,
      message: payload.message ?? null,
      source_user_id: payload.source_user_id ?? null,
      related_post_id: payload.related_post_id ?? null,
      related_comment_id: payload.related_comment_id ?? null,
      chat_message_id: payload.chat_message_id ?? null,
      chat_room_id: payload.chat_room_id ?? null,
    },
    select: {
      id: true,
      type: true,
      message: true,
      is_read: true,
      created_at: true,
      source_user_id: true,
      related_post_id: true,
      related_comment_id: true,
      chat_message_id: true,
      chat_room_id: true,
    },
  });

  // 실시간 푸시
  ssePush(targetUserId, { kind: 'notification', data: n });
  const unread = await prisma.notification.count({
    where: { user_id: targetUserId, is_read: false },
  });
  ssePush(targetUserId, { kind: 'unread', data: { count: unread } });

  return n;
}
