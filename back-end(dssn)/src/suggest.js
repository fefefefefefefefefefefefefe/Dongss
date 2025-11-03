import { Router } from 'express';
import { prisma } from './lib/prisma.js';
import { requireMe } from './mw.js';

const r = Router();

/**
 * GET /suggest/users?limit=12
 * - 아직 내가 팔로우하지 않은 유저들
 * - 같은 학과 우선, 그 다음 최신 가입 순
 */
r.get('/users', requireMe, async (req, res, next) => {
  try {
    const me = req.me;
    const limit = Math.min(50, parseInt(req.query.limit) || 12);

    const meUser = await prisma.user.findUnique({
      where: { id: me },
      select: { department: true },
    });
    const myDept = meUser?.department ?? null;

    // 이미 팔로우한 사람 제외
    const following = await prisma.follow.findMany({
      where: { follower_id: me },
      select: { following_id: true },
    });
    const blockIds = new Set([me, ...following.map((f) => f.following_id)]);

    // 후보 집합: 같은 학과 N*3개 + 타학과 N*3개 뽑아서 JS에서 안정 정렬
    const sameDept = await prisma.user.findMany({
      where: { department: myDept, NOT: { id: { in: Array.from(blockIds) } } },
      orderBy: { id: 'desc' },
      take: limit * 3,
      select: {
        id: true,
        username: true,
        nickname: true,
        profile_img: true,
        department: true,
      },
    });
    const others = await prisma.user.findMany({
      where: {
        department: { not: myDept },
        NOT: { id: { in: Array.from(blockIds) } },
      },
      orderBy: { id: 'desc' },
      take: limit * 3,
      select: {
        id: true,
        username: true,
        nickname: true,
        profile_img: true,
        department: true,
      },
    });

    // 같은 학과 우선으로 합치고 중복 제거
    const map = new Map();
    for (const u of [...sameDept, ...others]) map.set(u.id, u);
    const items = Array.from(map.values()).slice(0, limit);

    res.json({ items });
  } catch (e) {
    next(e);
  }
});

export default r;
