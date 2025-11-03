// src/follows.js
import { Router } from 'express';
import { prisma } from './lib/prisma.js';
import { requireMe } from './mw.js';

const r = Router();

/**
 * POST /follows/toggle
 * body: { user_id: number }  // 또는 { target: number }도 허용
 * 헤더: Authorization: Bearer <token>
 */
r.post('/toggle', requireMe, async (req, res, next) => {
  try {
    const me = req.me ?? req.userId;

    // 1) 입력 파싱(user_id 또는 target 둘 다 허용)
    const raw = req.body?.user_id ?? req.body?.target;
    const target = Number(raw);

    if (!Number.isFinite(target) || target <= 0) {
      return res.status(400).json({ message: 'invalid user_id' });
    }
    if (target === me) {
      return res.status(400).json({ message: 'cannot follow yourself' });
    }

    // 2) 대상 유저 존재 확인
    const existsUser = await prisma.user.findUnique({
      where: { id: target },
      select: { id: true },
    });
    if (!existsUser) {
      return res.status(404).json({ message: 'user not found' });
    }

    // 3) 토글 (고유키: follower_id_following_id)
    const where = {
      follower_id_following_id: { follower_id: me, following_id: target },
    };

    const existing = await prisma.follow
      .findUnique({ where })
      .catch(() => null);

    if (existing) {
      await prisma.follow.delete({ where });
      return res.json({ following: false });
    }

    await prisma.follow.create({
      data: { follower_id: me, following_id: target },
    });

    // 4) 알림 생성(실패해도 토글 성공엔 영향 주지 않음)
    // target = 팔로우 당한 사람, me = 팔로우 한 사람
    prisma.notification
      .create({
        data: {
          user_id: target,
          type: 'follow',
          message: null,
          is_read: false,
          source_user_id: me,
        },
      })
      .catch(() => {
        /* noop: 알림 실패는 무시 */
      });

    return res.json({ following: true });
  } catch (e) {
    next(e);
  }
});

export default r;
