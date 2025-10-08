import { Router } from 'express';
import { prisma } from './lib/prisma.js';
import { getMe } from './lib/me.js';

const r = Router();
const requireMe = (req, res, next) => {
  const me = getMe(req);
  if (!me) return res.status(401).json({ message: 'x-user-id required' });
  req.me = me;
  next();
};

// 내가 속한 채팅방 목록 (최근 메시지 1개 포함)
r.get('/chats', requireMe, async (req, res, next) => {
  try {
    const rooms = await prisma.chat_room_user.findMany({
      where: { user_id: req.me, left_at: null },
      orderBy: { id: 'desc' },
      include: {
        chat_room: {
          include: {
            chat_message: {
              take: 1,
              orderBy: { id: 'desc' },
              select: {
                id: true,
                message: true,
                file_url: true,
                created_at: true,
                sender_id: true,
              },
            },
            chat_room_user: {
              where: { left_at: null },
              select: {
                user: {
                  select: {
                    id: true,
                    username: true,
                    nickname: true,
                    profile_img: true,
                  },
                },
              },
            },
          },
        },
      },
    });

    const items = rooms.map((r) => ({
      id: r.chat_room.id,
      name: r.chat_room.name,
      is_group: r.chat_room.is_group ?? 0,
      members: r.chat_room.chat_room_user.map((m) => m.user),
      lastMessage: r.chat_room.chat_message[0] ?? null,
      created_at: r.chat_room.created_at,
    }));

    res.json({ items });
  } catch (e) {
    next(e);
  }
});

// 방 생성 (DM/그룹 공용) : body { name?, user_ids: number[] }
r.post('/chats', requireMe, async (req, res, next) => {
  try {
    const { name, user_ids = [] } = req.body;
    const uniqueMemberIds = Array.from(new Set([req.me, ...user_ids])).map(
      Number
    );
    if (uniqueMemberIds.length < 2)
      return res.status(400).json({ message: 'need at least 2 members' });

    const room = await prisma.$transaction(async (tx) => {
      const created = await tx.chat_room.create({
        data: {
          name: name ?? null,
          is_group: uniqueMemberIds.length > 2 ? 1 : 0,
        },
      });

      await tx.chat_room_user.createMany({
        data: uniqueMemberIds.map((uid) => ({
          chatroom_id: created.id,
          user_id: uid,
        })),
      });

      return created;
    });

    res.status(201).json(room);
  } catch (e) {
    next(e);
  }
});

// 방에 메시지 보내기 : params.roomId, body { message?, file_url? }
r.post('/chats/:roomId/messages', requireMe, async (req, res, next) => {
  try {
    const roomId = Number(req.params.roomId);
    const { message, file_url } = req.body;
    if (!message && !file_url)
      return res.status(400).json({ message: 'message or file_url required' });

    const membership = await prisma.chat_room_user.findFirst({
      where: { chatroom_id: roomId, user_id: req.me, left_at: null },
    });
    if (!membership) return res.status(403).json({ message: 'not a member' });

    const created = await prisma.chat_message.create({
      data: {
        chatroom_id: roomId,
        sender_id: req.me,
        message: message ?? null,
        file_url: file_url ?? null,
      },
    });

    res.status(201).json(created);
  } catch (e) {
    next(e);
  }
});

// 방 메시지 목록 : query page/limit
r.get('/chats/:roomId/messages', requireMe, async (req, res, next) => {
  try {
    const roomId = Number(req.params.roomId);
    const page = Math.max(1, parseInt(req.query.page) || 1);
    const limit = Math.min(100, parseInt(req.query.limit) || 30);
    const skip = (page - 1) * limit;

    const membership = await prisma.chat_room_user.findFirst({
      where: { chatroom_id: roomId, user_id: req.me, left_at: null },
    });
    if (!membership) return res.status(403).json({ message: 'not a member' });

    const [items, total] = await Promise.all([
      prisma.chat_message.findMany({
        where: { chatroom_id: roomId },
        orderBy: { id: 'desc' }, // 최신부터
        take: limit,
        skip,
        include: {
          sender: {
            select: {
              id: true,
              username: true,
              nickname: true,
              profile_img: true,
            },
          },
        },
      }),
      prisma.chat_message.count({ where: { chatroom_id: roomId } }),
    ]);

    res.json({ page, limit, total, items });
  } catch (e) {
    next(e);
  }
});

// 초대 : body { user_ids: number[] }
r.post('/chats/:roomId/invite', requireMe, async (req, res, next) => {
  try {
    const roomId = Number(req.params.roomId);
    const { user_ids = [] } = req.body;
    if (!user_ids.length)
      return res.status(400).json({ message: 'user_ids required' });

    const meMember = await prisma.chat_room_user.findFirst({
      where: { chatroom_id: roomId, user_id: req.me, left_at: null },
    });
    if (!meMember) return res.status(403).json({ message: 'not a member' });

    const exists = await prisma.chat_room_user.findMany({
      where: { chatroom_id: roomId, user_id: { in: user_ids } },
    });
    const existSet = new Set(exists.map((e) => e.user_id));
    const toAdd = user_ids
      .filter((u) => !existSet.has(u))
      .map((u) => ({ chatroom_id: roomId, user_id: u }));

    if (toAdd.length) await prisma.chat_room_user.createMany({ data: toAdd });

    res.json({ invited: toAdd.map((d) => d.user_id) });
  } catch (e) {
    next(e);
  }
});

// 방 나가기
r.post('/chats/:roomId/leave', requireMe, async (req, res, next) => {
  try {
    const roomId = Number(req.params.roomId);
    await prisma.chat_room_user.updateMany({
      where: { chatroom_id: roomId, user_id: req.me, left_at: null },
      data: { left_at: new Date() },
    });
    res.json({ left: true });
  } catch (e) {
    next(e);
  }
});

export default r;
