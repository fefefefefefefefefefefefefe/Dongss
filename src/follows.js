import { Router } from 'express';
import { prisma } from './lib/prisma.js';
import { requireMe } from './mw.js';

const r = Router();

// 팔로우 토글
r.post('/toggle', requireMe, async (req, res, next) => {
  try {
    const me = req.me;
    const target = Number(req.body?.user_id);
    if (!Number.isFinite(target) || target === me)
      return res.status(400).json({ message: 'invalid user_id' });

    const key = {
      follower_id_following_id: { follower_id: me, following_id: target },
    };
    const exist = await prisma.follow
      .findUnique({ where: key })
      .catch(() => null);
    if (exist) {
      await prisma.follow.delete({ where: key });
      return res.json({ following: false });
    }
    await prisma.follow.create({
      data: { follower_id: me, following_id: target },
    });
    res.json({ following: true });
  } catch (e) {
    next(e);
  }
});

export default r;
