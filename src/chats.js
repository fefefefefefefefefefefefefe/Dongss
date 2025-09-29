import { Router } from 'express';
import { prisma } from './lib/prisma.js';
import { requireMe, toInt } from './mw.js';

const r = Router();

// 방 만들기 (me + members 추가)
r.post('/', requireMe, async (req, res, next) => {
  try {
    const name = req.body?.name ?? null;
    const is_group = req.body?.is_group ? 1 : 0;
    const members = Array.isArray(req.body?.members)
      ? req.body.members.map(toInt).filter(Boolean)
      : [];
    const all = Array.from(new Set([req.me, ...members]));

    const room = await prisma.$transaction(async (tx) => {
      const cr = await tx.chat_room.create({ data: { name, is_group } });
      await tx.chat_room_user.createMany({
        data: all.map((uid) => ({ chatroom_id: cr.id, user_id: uid })),
      });
      return cr;
    });
    res.status(201).json(room);
  } catch (e) {
    next(e);
  }
});

// 내 방 목록
r.get('/', requireMe, async (req, res, next) => {
  try {
    const rows = await prisma.chat_room_user.findMany({
      where: { user_id: req.me },
      include: { chat_room: true },
    });
    res.json(rows.map((r) => r.chat_room));
  } catch (e) {
    next(e);
  }
});

// 방에 초대
r.post('/:roomId/invite', requireMe, async (req, res, next) => {
  try {
    const roomId = Number(req.params.roomId);
    const targets = Array.isArray(req.body?.user_ids)
      ? req.body.user_ids.map(toInt).filter(Boolean)
      : [];
    if (!targets.length) return res.json({ added: 0 });

    // 내가 그 방에 있어야 초대 가능
    const meIn = await prisma.chat_room_user.findFirst({
      where: { chatroom_id: roomId, user_id: req.me },
    });
    if (!meIn) return res.status(403).json({ message: 'not a member' });

    const existing = await prisma.chat_room_user.findMany({
      where: { chatroom_id: roomId, user_id: { in: targets } },
      select: { user_id: true },
    });
    const exists = new Set(existing.map((x) => x.user_id));
    const todo = targets.filter((uid) => !exists.has(uid));
    if (!todo.length) return res.json({ added: 0 });

    const r1 = await prisma.chat_room_user.createMany({
      data: todo.map((uid) => ({ chatroom_id: roomId, user_id: uid })),
    });
    res.json({ added: r1.count });
  } catch (e) {
    next(e);
  }
});

// 나가기
r.post('/:roomId/leave', requireMe, async (req, res, next) => {
  try {
    const roomId = Number(req.params.roomId);
    await prisma.chat_room_user.deleteMany({
      where: { chatroom_id: roomId, user_id: req.me },
    });
    res.json({ ok: true });
  } catch (e) {
    next(e);
  }
});

// 메시지 전송
r.post('/:roomId/messages', requireMe, async (req, res, next) => {
  try {
    const roomId = Number(req.params.roomId);
    const meIn = await prisma.chat_room_user.findFirst({
      where: { chatroom_id: roomId, user_id: req.me },
    });
    if (!meIn) return res.status(403).json({ message: 'not a member' });

    const message = req.body?.message ?? null;
    const file_url = req.body?.file_url ?? null;
    if (!message && !file_url)
      return res.status(400).json({ message: 'message or file_url required' });

    const msg = await prisma.chat_message.create({
      data: { chatroom_id: roomId, sender_id: req.me, message, file_url },
    });
    res.status(201).json(msg);
  } catch (e) {
    next(e);
  }
});

// 메시지 히스토리
r.get('/:roomId/messages', requireMe, async (req, res, next) => {
  try {
    const roomId = Number(req.params.roomId);
    const take = Math.min(100, Number(req.query.limit) || 50);
    const beforeId = req.query.before ? Number(req.query.before) : undefined;

    const where = {
      chatroom_id: roomId,
      ...(beforeId ? { id: { lt: beforeId } } : {}),
    };
    const items = await prisma.chat_message.findMany({
      where,
      take,
      orderBy: { id: 'desc' },
    });
    res.json({
      items,
      nextCursor: items.length ? items[items.length - 1].id : null,
    });
  } catch (e) {
    next(e);
  }
});

export default r;
