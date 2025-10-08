import { Router } from 'express';
import { prisma } from './lib/prisma.js';
import { getMe } from './lib/me.js';

const r = Router();

r.get('/:postId', async (req, res, next) => {
  try {
    const postId = Number(req.params.postId);
    const items = await prisma.comment.findMany({
      where: { post_id: postId, parent_id: null },
      orderBy: { id: 'asc' },
      include: {
        user: {
          select: {
            id: true,
            username: true,
            nickname: true,
            profile_img: true,
          },
        },
        _count: { select: { comment: true } }, // 자기참조 하위 개수 (필드명 다르면 수정)
      },
    });
    res.json(items);
  } catch (e) {
    next(e);
  }
});

r.post('/', async (req, res, next) => {
  try {
    const me = getMe(req);
    if (!me) return res.status(401).json({ message: 'x-user-id required' });
    const { post_id, content, parent_id } = req.body;
    if (!post_id || !content)
      return res.status(400).json({ message: 'post_id & content required' });

    const c = await prisma.comment.create({
      data: { user_id: me, post_id, content, parent_id: parent_id ?? null },
    });
    res.status(201).json(c);
  } catch (e) {
    next(e);
  }
});

export default r;
