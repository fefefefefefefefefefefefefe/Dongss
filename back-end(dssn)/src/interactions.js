// src/interactions.js
import { Router } from 'express';
import { prisma } from './lib/prisma.js';
import { requireAuth as requireMe } from './mw.js'; // 별칭 그대로 써도 OK

const r = Router();

/* ---------- helpers ---------- */
function getPostId(req) {
  const pid = req.params.postId ?? req.body?.post_id;
  const n = Number(pid);
  return Number.isInteger(n) && n > 0 ? n : null;
}

async function ensurePost(postId) {
  const p = await prisma.post.findUnique({
    where: { id: postId },
    select: { id: true, user_id: true },
  });
  if (!p) throw Object.assign(new Error('post not found'), { status: 404 });
  return p;
}

// 각 관계 이름은 schema.prisma의 relation 이름에 맞춰 두세요.
// (아래는 예: post -> post_like / bookmark / repost / comment)
async function countsOf(postId) {
  const c = await prisma.post.findUnique({
    where: { id: postId },
    select: {
      _count: {
        select: {
          post_like: true,
          bookmark: true,
          repost: true,
          comment: true,
        },
      },
    },
  });
  return {
    likes: c?._count.post_like ?? 0,
    bookmarks: c?._count.bookmark ?? 0,
    reposts: c?._count.repost ?? 0,
    comments: c?._count.comment ?? 0,
  };
}

async function statusFor(userId, postId) {
  const [like, bm, rp, counts] = await Promise.all([
    prisma.post_like.findFirst({
      where: { user_id: userId, post_id: postId },
      select: { id: true },
    }),
    prisma.bookmark.findFirst({
      where: { user_id: userId, post_id: postId },
      select: { id: true },
    }),
    prisma.repost.findFirst({
      where: { user_id: userId, post_id: postId },
      select: { id: true },
    }),
    countsOf(postId),
  ]);

  return {
    post_id: postId,
    counts,
    viewer_has_liked: !!like,
    viewer_has_bookmarked: !!bm,
    viewer_has_reposted: !!rp,
  };
}

/* ---------- 8) 상태 조회 ---------- */
/** GET /interactions/:postId/status */
r.get('/interactions/:postId/status', requireMe, async (req, res) => {
  try {
    const me = req.userId ?? req.me ?? req.user?.id;
    const postId = getPostId(req);
    if (!postId) return res.status(400).json({ message: 'postId required' });
    await ensurePost(postId);
    const s = await statusFor(me, postId);
    return res.json(s);
  } catch (e) {
    return res
      .status(e?.status || 500)
      .json({ message: e?.message || 'error' });
  }
});

/* ---------- 7) 좋아요 토글 ---------- */
/** POST /like/:postId  또는  POST /likes  { post_id } */
r.post(['/like/:postId', '/likes'], requireMe, async (req, res, next) => {
  try {
    const me = req.userId ?? req.me ?? req.user?.id;
    const postId = getPostId(req);
    if (!postId) return res.status(400).json({ message: 'post_id required' });
    const post = await ensurePost(postId);

    const exist = await prisma.post_like.findFirst({
      where: { user_id: me, post_id: postId },
      select: { id: true },
    });

    if (exist) {
      // 해제
      await prisma.post_like.deleteMany({
        where: { user_id: me, post_id: postId },
      });
    } else {
      // 등록 (경합으로 인한 unique 에러는 무시)
      await prisma.post_like
        .create({ data: { user_id: me, post_id: postId } })
        .catch(() => {});
      // 알림 (자기글 제외, 실패 무시)
      if (post.user_id !== me) {
        prisma.notification
          .create({
            data: {
              user_id: post.user_id,
              type: 'like',
              is_read: false,
              source_user_id: me,
              related_post_id: postId,
            },
          })
          .catch(() => {});
      }
    }

    // 최신 상태 반환
    const s = await statusFor(me, postId);
    // 첫 등록이면 201, 아니면 200
    return res.status(exist ? 200 : 201).json(s);
  } catch (e) {
    // Unique 경합 등
    if (e?.code === 'P2002') {
      const s = await statusFor(
        req.userId ?? req.me ?? req.user?.id,
        getPostId(req)
      );
      return res.status(200).json(s);
    }
    next(e);
  }
});

/* ---- (선택) 북마크/리포스트 토글까지 함께 사용하려면 아래 유지 ---- */
r.post(
  ['/bookmark/:postId', '/bookmarks'],
  requireMe,
  async (req, res, next) => {
    try {
      const me = req.userId ?? req.me ?? req.user?.id;
      const postId = getPostId(req);
      if (!postId) return res.status(400).json({ message: 'post_id required' });
      await ensurePost(postId);

      const ex = await prisma.bookmark.findFirst({
        where: { user_id: me, post_id: postId },
      });
      if (ex) {
        await prisma.bookmark.deleteMany({
          where: { user_id: me, post_id: postId },
        });
      } else {
        await prisma.bookmark
          .create({ data: { user_id: me, post_id: postId } })
          .catch(() => {});
      }
      return res.json(await statusFor(me, postId));
    } catch (e) {
      next(e);
    }
  }
);

r.post(['/repost/:postId', '/reposts'], requireMe, async (req, res, next) => {
  try {
    const me = req.userId ?? req.me ?? req.user?.id;
    const postId = getPostId(req);
    if (!postId) return res.status(400).json({ message: 'post_id required' });
    const post = await ensurePost(postId);

    const quote =
      typeof req.body?.quote === 'string' && req.body.quote.trim()
        ? req.body.quote.trim()
        : null;

    const ex = await prisma.repost.findFirst({
      where: { user_id: me, post_id: postId },
    });
    if (ex) {
      await prisma.repost.deleteMany({
        where: { user_id: me, post_id: postId },
      });
    } else {
      await prisma.repost
        .create({ data: { user_id: me, post_id: postId, quote } })
        .catch(() => {});
      if (post.user_id !== me) {
        prisma.notification
          .create({
            data: {
              user_id: post.user_id,
              type: 'repost',
              is_read: false,
              source_user_id: me,
              related_post_id: postId,
            },
          })
          .catch(() => {});
      }
    }
    return res.json(await statusFor(me, postId));
  } catch (e) {
    next(e);
  }
});

export default r;
