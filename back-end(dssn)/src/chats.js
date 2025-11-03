// /src/chats.js
import { Router } from 'express';
import { prisma } from './lib/prisma.js';
import { requireMe } from './mw.js';
import { notifyAndPersist } from './notifications.js';

const r = Router();

/* ─────────────────────────────
 * 공통 헬퍼
 * ───────────────────────────── */
async function activeMembers(roomId) {
  return prisma.chat_room_user.findMany({
    where: { chatroom_id: roomId, left_at: null },
    select: { user_id: true },
  });
}
async function isMember(userId, roomId) {
  const m = await prisma.chat_room_user.findFirst({
    where: { chatroom_id: roomId, user_id: userId, left_at: null },
    select: { id: true },
  });
  return !!m;
}
function toRoomDTO(room, includeMembers = false) {
  return {
    id: room.id,
    title: room.title ?? null,
    is_group: !!room.is_group,
    lastMessage: room.messages?.[0] ?? null,
    created_at: room.created_at,
    ...(includeMembers
      ? { members: room.users?.map((u) => u.user) ?? [] }
      : {}),
  };
}

/* ─────────────────────────────
 * 공통: 내 채팅방 목록 (혼합)
 * ───────────────────────────── */
r.get('/chats', requireMe, async (req, res, next) => {
  try {
    const links = await prisma.chat_room_user.findMany({
      where: { user_id: req.me, left_at: null },
      orderBy: { id: 'desc' },
      include: {
        room: {
          include: {
            messages: {
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
            users: {
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
    const items = links.map((ln) => toRoomDTO(ln.room, true));
    res.json({ items });
  } catch (e) {
    next(e);
  }
});

/* ─────────────────────────────
 * DM(1:1) 전용: 목록
 *  - DB 관계 필터: room.is_group = false
 *  - 활성 멤버 2명만 최종 필터
 * ───────────────────────────── */
r.get('/chats/dm', requireMe, async (req, res, next) => {
  try {
    const links = await prisma.chat_room_user.findMany({
      where: {
        user_id: req.me,
        left_at: null,
        room: { is_group: false }, // ✅ include 안이 아니라 여기에서 필터
      },
      orderBy: { id: 'desc' },
      include: {
        room: {
          include: {
            users: {
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
                user_id: true,
              },
            },
            messages: {
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
          },
        },
      },
    });

    const items = links
      .filter((ln) => ln.room && (ln.room.users?.length ?? 0) === 2)
      .map((ln) => toRoomDTO(ln.room, true));

    res.json({ items });
  } catch (e) {
    next(e);
  }
});

/* ─────────────────────────────
 * 그룹 전용: 목록
 *  - DB 관계 필터: room.is_group = true
 * ───────────────────────────── */
r.get('/chats/groups', requireMe, async (req, res, next) => {
  try {
    const links = await prisma.chat_room_user.findMany({
      where: {
        user_id: req.me,
        left_at: null,
        room: { is_group: true }, // ✅ DB에서 바로 그룹만
      },
      orderBy: { id: 'desc' },
      include: {
        room: {
          include: {
            users: {
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
                user_id: true,
              },
            },
            messages: {
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
          },
        },
      },
    });

    const items = links.map((ln) => toRoomDTO(ln.room, true));
    res.json({ items });
  } catch (e) {
    next(e);
  }
});

/* ─────────────────────────────
 * DM(1:1) 전용: 생성 or 찾기
 *  - 기존 DM(둘만 활성) 있으면 그대로 반환
 *  - 없으면 생성
 * ───────────────────────────── */
r.post('/chats/dm/:otherUserId', requireMe, async (req, res, next) => {
  try {
    const me = req.me;
    const otherId = Number(req.params.otherUserId);
    if (!otherId || otherId === me)
      return res.status(400).json({ message: 'invalid other user' });

    const myLinks = await prisma.chat_room_user.findMany({
      where: { user_id: me, left_at: null },
      select: { chatroom_id: true },
    });
    const myRoomIds = myLinks.map((x) => x.chatroom_id);

    if (myRoomIds.length > 0) {
      const candidates = await prisma.chat_room.findMany({
        where: { id: { in: myRoomIds }, is_group: false },
        include: {
          users: { where: { left_at: null }, select: { user_id: true } },
          messages: {
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
        },
      });

      const existing = candidates.find((rm) => {
        const ids = new Set(rm.users.map((u) => u.user_id));
        return ids.has(me) && ids.has(otherId) && ids.size === 2;
      });
      if (existing) return res.json(toRoomDTO(existing, false));
    }

    const created = await prisma.$transaction(async (tx) => {
      const room = await tx.chat_room.create({
        data: { title: null, is_group: false },
      });
      await tx.chat_room_user.createMany({
        data: [
          { chatroom_id: room.id, user_id: me },
          { chatroom_id: room.id, user_id: otherId },
        ],
      });
      return room;
    });

    res.status(201).json(created);
  } catch (e) {
    next(e);
  }
});

/* ─────────────────────────────
 * 그룹 전용: 생성
 *  - body { title, user_ids:number[] }
 *  - 최소 3인(나 + 2명)
 * ───────────────────────────── */
r.post('/chats/groups', requireMe, async (req, res, next) => {
  try {
    const { title, user_ids = [] } = req.body ?? {};
    const me = req.me;
    const uniqueMemberIds = Array.from(
      new Set([me, ...user_ids.map(Number)])
    ).filter(Boolean);

    if (uniqueMemberIds.length < 3) {
      return res
        .status(400)
        .json({
          message:
            'need at least 3 members for group (use /chats/dm/:otherUserId for 1:1)',
        });
    }

    const room = await prisma.$transaction(async (tx) => {
      const created = await tx.chat_room.create({
        data: { title: title ?? null, is_group: true },
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

/* ─────────────────────────────
 * 메시지 보내기 (DM/그룹 공용)
 * ───────────────────────────── */
r.post('/chats/:roomId/messages', requireMe, async (req, res, next) => {
  try {
    const roomId = Number(req.params.roomId);
    const { message, file_url } = req.body ?? {};
    if (!message && !file_url)
      return res.status(400).json({ message: 'message or file_url required' });

    if (!(await isMember(req.me, roomId)))
      return res.status(403).json({ message: 'not a member' });

    const created = await prisma.chat_message.create({
      data: {
        chatroom_id: roomId,
        sender_id: req.me,
        message: message ?? null,
        file_url: file_url ?? null,
      },
    });

    // 같은 방의 다른 멤버에게 알림
    const members = await activeMembers(roomId);
    for (const { user_id } of members) {
      if (user_id === req.me) continue;
      notifyAndPersist(user_id, {
        type: 'chat',
        source_user_id: req.me,
        chat_message_id: created.id,
        chat_room_id: roomId,
      }).catch(() => {});
    }

    res.status(201).json(created);
  } catch (e) {
    next(e);
  }
});

/* ─────────────────────────────
 * 방 메시지 목록 (최신→과거, cursor)
 * ───────────────────────────── */
r.get('/chats/:roomId/messages', requireMe, async (req, res, next) => {
  try {
    const roomId = Number(req.params.roomId);
    const limit = Math.min(100, parseInt(req.query.limit) || 30);
    const cursor = req.query.cursor ? Number(req.query.cursor) : null;

    if (!(await isMember(req.me, roomId)))
      return res.status(403).json({ message: 'not a member' });

    const items = await prisma.chat_message.findMany({
      where: { chatroom_id: roomId },
      orderBy: { id: 'desc' },
      take: limit + 1,
      ...(cursor ? { cursor: { id: cursor }, skip: 1 } : {}),
      include: {
        user: {
          select: {
            id: true,
            username: true,
            nickname: true,
            profile_img: true,
          },
        },
      },
    });

    const nextCursor = items.length > limit ? items[limit].id : null;
    res.json({ items: items.slice(0, limit), nextCursor });
  } catch (e) {
    next(e);
  }
});

/* ─────────────────────────────
 * 초대 (그룹만 허용)
 * ───────────────────────────── */
r.post('/chats/:roomId/invite', requireMe, async (req, res, next) => {
  try {
    const roomId = Number(req.params.roomId);
    const room = await prisma.chat_room.findUnique({
      where: { id: roomId },
      select: { is_group: true },
    });
    if (!room) return res.status(404).json({ message: 'room not found' });
    if (!room.is_group)
      return res.status(400).json({ message: 'cannot invite to DM room' });

    if (!(await isMember(req.me, roomId)))
      return res.status(403).json({ message: 'not a member' });

    const { user_ids = [] } = req.body ?? {};
    const targetIds = Array.from(new Set(user_ids.map(Number).filter(Boolean)));
    if (!targetIds.length)
      return res.status(400).json({ message: 'user_ids required' });

    const exists = await prisma.chat_room_user.findMany({
      where: { chatroom_id: roomId, user_id: { in: targetIds } },
      select: { user_id: true },
    });
    const existSet = new Set(exists.map((e) => e.user_id));
    const toAdd = targetIds
      .filter((u) => !existSet.has(u))
      .map((u) => ({ chatroom_id: roomId, user_id: u }));

    if (toAdd.length) await prisma.chat_room_user.createMany({ data: toAdd });

    res.json({ invited: toAdd.map((d) => d.user_id) });
  } catch (e) {
    next(e);
  }
});

/* ─────────────────────────────
 * 방 나가기 (DM/그룹 공용)
 * ───────────────────────────── */
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
