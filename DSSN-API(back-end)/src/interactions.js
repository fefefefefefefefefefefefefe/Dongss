// 상호작용(좋아요/북마크/리포스트) 토글
import { Router } from 'express';
import { prisma } from './lib/prisma.js';
import { getMe } from './lib/me.js';

const r = Router();

/** 좋아요 토글 */
r.post('/likes', async (req, res, next) => {
  try {
    const me = getMe(req);
    if (!me) return res.status(401).json({ message: 'x-user-id required' });

    const { post_id } = req.body;
    if (!post_id) return res.status(400).json({ message: 'post_id required' });

    // 이미 눌렀으면 삭제
    const ex = await prisma.post_like
      .findUnique({
        where: { post_id_user_id: { post_id, user_id: me } },
      })
      .catch(() => null);

    if (ex) {
      await prisma.post_like.delete({
        where: { post_id_user_id: { post_id, user_id: me } },
      });
      return res.json({ liked: false });
    }

    // 없으면 생성 (중복 클릭 시 P2002 무시)
    await prisma.post_like
      .create({ data: { post_id, user_id: me } })
      .catch((e) => {
        if (e?.code !== 'P2002') throw e;
      });
    res.json({ liked: true });
  } catch (e) {
    next(e);
  }
});

/** 북마크 토글 */
r.post('/bookmarks', async (req, res, next) => {
  try {
    const me = getMe(req);
    if (!me) return res.status(401).json({ message: 'x-user-id required' });

    const { post_id } = req.body;
    if (!post_id) return res.status(400).json({ message: 'post_id required' });

    const ex = await prisma.bookmark
      .findUnique({
        where: { user_id_post_id: { user_id: me, post_id } },
      })
      .catch(() => null);

    if (ex) {
      await prisma.bookmark.delete({
        where: { user_id_post_id: { user_id: me, post_id } },
      });
      return res.json({ bookmarked: false });
    }

    await prisma.bookmark
      .create({ data: { user_id: me, post_id } })
      .catch((e) => {
        if (e?.code !== 'P2002') throw e;
      });
    res.json({ bookmarked: true });
  } catch (e) {
    next(e);
  }
});

/** 리포스트 토글 (+ quote) */
r.post('/reposts', async (req, res, next) => {
  try {
    const me = getMe(req);
    if (!me) return res.status(401).json({ message: 'x-user-id required' });

    const { post_id, quote } = req.body;
    if (!post_id) return res.status(400).json({ message: 'post_id required' });

    const ex = await prisma.repost
      .findUnique({
        where: { user_id_post_id: { user_id: me, post_id } },
      })
      .catch(() => null);

    if (ex) {
      await prisma.repost.delete({
        where: { user_id_post_id: { user_id: me, post_id } },
      });
      return res.json({ reposted: false });
    }

    await prisma.repost
      .create({ data: { user_id: me, post_id, quote: quote ?? null } })
      .catch((e) => {
        if (e?.code !== 'P2002') throw e;
      });
    res.json({ reposted: true });
  } catch (e) {
    next(e);
  }
});

export default r;
