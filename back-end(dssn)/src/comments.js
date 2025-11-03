// /src/comments.js
import { Router } from 'express';
import { prisma } from './lib/prisma.js';
import { requireMe, optionalAuth } from './mw.js';
import { notifyAndPersist } from './notifications.js';

const r = Router();

function parsePage(req) {
  const limit = Math.min(100, parseInt(req.query.limit) || 20);
  const cursor = req.query.cursor ? Number(req.query.cursor) : undefined;
  return { limit, cursor };
}

/** 1) 루트 댓글 목록 */
r.get('/:postId', optionalAuth, async (req, res, next) => {
  try {
    const postId = Number(req.params.postId);
    if (!Number.isInteger(postId) || postId <= 0)
      return res.status(400).json({ message: 'invalid postId' });

    const { limit, cursor } = parsePage(req);
    const query = {
      where: { post_id: postId, parent_id: null },
      orderBy: { id: 'asc' },
      take: limit + 1,
      include: {
        user: {
          select: {
            id: true,
            username: true,
            nickname: true,
            profile_img: true,
          },
        },
        _count: { select: { comment: true, comment_like: true } },
      },
    };
    if (cursor) Object.assign(query, { cursor: { id: cursor }, skip: 1 });

    let items = await prisma.comment.findMany(query);
    let next_cursor = null;
    if (items.length > limit) {
      const last = items.pop();
      next_cursor = last.id;
    }

    const me = req.me ?? null;
    if (me && items.length) {
      const ids = items.map((c) => c.id);
      const likes = await prisma.comment_like.findMany({
        where: { user_id: me, comment_id: { in: ids } },
        select: { comment_id: true },
      });
      const set = new Set(likes.map((x) => x.comment_id));
      items.forEach((c) => (c.viewer_has_liked = set.has(c.id)));
    } else items.forEach((c) => (c.viewer_has_liked = false));

    res.json({ items, next_cursor });
  } catch (e) {
    next(e);
  }
});

/** 2) 대댓글 목록 */
r.get('/threads', optionalAuth, async (req, res, next) => {
  try {
    const postId = Number(req.query.post_id);
    const parentId = Number(req.query.parent_id);
    if (!postId || !parentId)
      return res.status(400).json({ message: 'post_id & parent_id required' });

    const { limit, cursor } = parsePage(req);
    const query = {
      where: { post_id: postId, parent_id: parentId },
      orderBy: { id: 'asc' },
      take: limit + 1,
      include: {
        user: {
          select: {
            id: true,
            username: true,
            nickname: true,
            profile_img: true,
          },
        },
        _count: { select: { comment_like: true } },
      },
    };
    if (cursor) Object.assign(query, { cursor: { id: cursor }, skip: 1 });

    let items = await prisma.comment.findMany(query);
    let next_cursor = null;
    if (items.length > limit) {
      const last = items.pop();
      next_cursor = last.id;
    }

    const me = req.me ?? null;
    if (me && items.length) {
      const ids = items.map((c) => c.id);
      const likes = await prisma.comment_like.findMany({
        where: { user_id: me, comment_id: { in: ids } },
        select: { comment_id: true },
      });
      const set = new Set(likes.map((x) => x.comment_id));
      items.forEach((c) => (c.viewer_has_liked = set.has(c.id)));
    } else items.forEach((c) => (c.viewer_has_liked = false));

    res.json({ items, next_cursor });
  } catch (e) {
    next(e);
  }
});

/** 3) 댓글 생성 */
r.post('/', requireMe, async (req, res, next) => {
  try {
    const me = req.me;
    const { post_id, content, parent_id } = req.body ?? {};
    if (!post_id || !content)
      return res.status(400).json({ message: 'post_id & content required' });

    const post = await prisma.post.findUnique({
      where: { id: Number(post_id) },
      select: { id: true, user_id: true },
    });
    if (!post) return res.status(404).json({ message: 'post not found' });

    if (parent_id) {
      const parent = await prisma.comment.findUnique({
        where: { id: Number(parent_id) },
        select: { id: true, post_id: true, user_id: true },
      });
      if (!parent || parent.post_id !== post.id)
        return res.status(400).json({ message: 'invalid parent_id' });
    }

    const c = await prisma.comment.create({
      data: {
        user_id: me,
        post_id: post.id,
        content: String(content).trim(),
        parent_id: parent_id ? Number(parent_id) : null,
      },
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

    // 알림(본인 제외)
    if (post.user_id !== me) {
      notifyAndPersist(post.user_id, {
        type: 'comment',
        source_user_id: me,
        related_post_id: post.id,
        related_comment_id: c.id,
      }).catch(() => {});
    }
    if (parent_id) {
      const parent = await prisma.comment.findUnique({
        where: { id: Number(parent_id) },
        select: { user_id: true },
      });
      if (parent && parent.user_id !== me && parent.user_id !== post.user_id) {
        notifyAndPersist(parent.user_id, {
          type: 'reply',
          source_user_id: me,
          related_post_id: post.id,
          related_comment_id: c.id,
        }).catch(() => {});
      }
    }

    res.status(201).json(c);
  } catch (e) {
    next(e);
  }
});

/** 4) 댓글 좋아요 토글 */
r.post('/:id/like', requireMe, async (req, res, next) => {
  try {
    const me = req.me;
    const id = Number(req.params.id);
    const cm = await prisma.comment.findUnique({
      where: { id },
      select: { id: true, user_id: true, post_id: true },
    });
    if (!cm) return res.status(404).json({ message: 'not found' });

    const ex = await prisma.comment_like.findFirst({
      where: { user_id: me, comment_id: id },
    });

    if (ex) {
      await prisma.comment_like.deleteMany({
        where: { user_id: me, comment_id: id },
      });
    } else {
      await prisma.comment_like.create({
        data: { user_id: me, comment_id: id },
      });
      if (cm.user_id !== me) {
        notifyAndPersist(cm.user_id, {
          type: 'comment_like',
          source_user_id: me,
          related_post_id: cm.post_id,
          related_comment_id: id,
        }).catch(() => {});
      }
    }

    const likes = await prisma.comment_like.count({
      where: { comment_id: id },
    });
    const liked = await prisma.comment_like.findFirst({
      where: { user_id: me, comment_id: id },
    });
    res.json({ comment_id: id, likes, viewer_has_liked: !!liked });
  } catch (e) {
    next(e);
  }
});

/** 5) 댓글 삭제(소프트) */
r.delete('/:id', requireMe, async (req, res, next) => {
  try {
    const id = Number(req.params.id || 0);
    if (!Number.isInteger(id) || id <= 0)
      return res.status(400).json({ message: 'invalid comment id' });

    const me = req.me;
    const c = await prisma.comment.findUnique({
      where: { id },
      select: { id: true, user_id: true, is_deleted: true },
    });
    if (!c) return res.status(404).json({ message: 'comment not found' });
    if (c.user_id !== me) return res.status(403).json({ message: 'forbidden' });
    if (c.is_deleted) return res.json({ ok: true, already_deleted: true });

    const updated = await prisma.comment.update({
      where: { id },
      data: { is_deleted: true, content: null },
      select: { id: true, is_deleted: true, content: true },
    });
    return res.json({ ok: true, comment: updated });
  } catch (e) {
    next(e);
  }
});

export default r;
