// src/routes/users.js
import { Router } from 'express';
import { prisma } from '../lib/prisma.js';
import { requireMe } from '../mw.js'; // ✅ 통일

const r = Router();

/* ───────── 공통 ───────── */

const userOut = (u) => ({
  id: u.id,
  username: u.username,
  email: u.email,
  name: u.name,
  nickname: u.nickname,
  profile_img: u.profile_img,
  gender: u.gender,
  department: u.department,
  birthday: u.birthday,
  website: u.website,
  location: u.location,
  university: u.university,
  email_verified: u.email_verified,
  created_at: u.created_at,
});

const getMeId = (req) => req.me ?? req.userId; // ✅ 어떤 구현이든 대응

function parseCursor(req) {
  const limit = Math.min(50, parseInt(req.query.limit) || 20);
  const cursor = req.query.cursor ? Number(req.query.cursor) : undefined;
  return { limit, cursor };
}

const baseInclude = {
  user: {
    select: {
      id: true,
      username: true,
      nickname: true,
      profile_img: true,
      department: true,
    },
  },
  post_file: true,
  post_tag: { include: { tag: true } },
  _count: {
    select: { comment: true, post_like: true, bookmark: true, repost: true },
  },
};

async function decorateViewerFlagsAndThumb(items, me) {
  if (!items?.length) return items;
  const ids = items.map((i) => i.id);

  let likeSet = new Set();
  let bmSet = new Set();
  let rpSet = new Set();

  if (me) {
    const [likes, bms, rps] = await Promise.all([
      prisma.post_like.findMany({
        where: { user_id: me, post_id: { in: ids } },
        select: { post_id: true },
      }),
      prisma.bookmark.findMany({
        where: { user_id: me, post_id: { in: ids } },
        select: { post_id: true },
      }),
      prisma.repost.findMany({
        where: { user_id: me, post_id: { in: ids } },
        select: { post_id: true },
      }),
    ]);
    likeSet = new Set(likes.map((x) => x.post_id));
    bmSet = new Set(bms.map((x) => x.post_id));
    rpSet = new Set(rps.map((x) => x.post_id));
  }

  for (const it of items) {
    it.viewer_has_liked = me ? likeSet.has(it.id) : false;
    it.viewer_has_bookmarked = me ? bmSet.has(it.id) : false;
    it.viewer_has_reposted = me ? rpSet.has(it.id) : false;
    const thumb =
      (it.post_file || []).find((f) => f.is_thumbnail) ||
      (it.post_file || [])[0];
    it.thumbnail_url = thumb?.file_url ?? null;
  }
  return items;
}

/* ───────── 내 프로필 조회/수정 ───────── */

/** GET /users/me */
r.get('/me', requireMe, async (req, res, next) => {
  try {
    const meId = getMeId(req);
    const me = await prisma.user.findUnique({
      where: { id: meId },
      select: {
        id: true,
        username: true,
        email: true,
        name: true,
        nickname: true,
        profile_img: true,
        gender: true,
        department: true,
        birthday: true,
        website: true,
        location: true,
        university: true,
        email_verified: true,
        created_at: true,
      },
    });
    res.json({ user: me && userOut(me) });
  } catch (e) {
    next(e);
  }
});

/** PATCH /users/me */
r.patch('/me', requireMe, async (req, res, next) => {
  try {
    const meId = getMeId(req);
    const {
      nickname,
      bio,
      profile_img,
      gender,
      department,
      birthday,
      website,
      location,
    } = req.body ?? {};

    const updated = await prisma.user.update({
      where: { id: meId },
      data: {
        nickname: nickname ?? undefined,
        bio: bio ?? undefined,
        profile_img: profile_img ?? undefined,
        gender: gender ?? undefined,
        department: department ?? undefined,
        birthday: birthday ? new Date(birthday) : undefined,
        website: website ?? undefined,
        location: location ?? undefined,
      },
      select: {
        id: true,
        username: true,
        email: true,
        name: true,
        nickname: true,
        profile_img: true,
        bio: true,
        gender: true,
        department: true,
        birthday: true,
        website: true,
        location: true,
        university: true,
        email_verified: true,
        created_at: true,
      },
    });
    res.json({ user: userOut(updated) });
  } catch (e) {
    if (e?.code === 'P2002')
      return res.status(409).json({ message: 'nickname already taken' });
    next(e);
  }
});

/* ───────── 마이페이지 탭: 작성/좋아요/저장/댓글 (커서) ───────── */

async function listBy(where, req, res, next) {
  try {
    const { limit, cursor } = parseCursor(req);
    const query = {
      where,
      take: limit + 1,
      orderBy: { id: 'desc' },
      include: baseInclude,
    };
    if (cursor) Object.assign(query, { cursor: { id: cursor }, skip: 1 });

    let items = await prisma.post.findMany(query);
    let next_cursor = null;
    if (items.length > limit) {
      const last = items.pop();
      next_cursor = last.id;
    }
    await decorateViewerFlagsAndThumb(items, getMeId(req));
    res.json({ items, next_cursor });
  } catch (e) {
    next(e);
  }
}

/** GET /users/:id/posts */
r.get('/:id/posts', (req, res, next) => {
  const uid = Number(req.params.id);
  if (!Number.isInteger(uid) || uid <= 0)
    return res.status(400).json({ message: 'invalid id' });
  return listBy({ user_id: uid }, req, res, next);
});

/** GET /users/:id/likes */
r.get('/:id/likes', (req, res, next) => {
  const uid = Number(req.params.id);
  if (!Number.isInteger(uid) || uid <= 0)
    return res.status(400).json({ message: 'invalid id' });
  return listBy({ post_like: { some: { user_id: uid } } }, req, res, next);
});

/** GET /users/:id/bookmarks */
r.get('/:id/bookmarks', (req, res, next) => {
  const uid = Number(req.params.id);
  if (!Number.isInteger(uid) || uid <= 0)
    return res.status(400).json({ message: 'invalid id' });
  return listBy({ bookmark: { some: { user_id: uid } } }, req, res, next);
});

/** GET /users/:id/comments */
r.get('/:id/comments', (req, res, next) => {
  const uid = Number(req.params.id);
  if (!Number.isInteger(uid) || uid <= 0)
    return res.status(400).json({ message: 'invalid id' });
  return listBy({ comment: { some: { user_id: uid } } }, req, res, next);
});

/* ───────── /me 별칭 ───────── */
r.get('/me/posts', requireMe, (req, res, next) => {
  req.params.id = String(getMeId(req));
  return r._router.handle(req, res, next);
});
r.get('/me/likes', requireMe, (req, res, next) => {
  req.params.id = String(getMeId(req));
  return r._router.handle(req, res, next);
});
r.get('/me/bookmarks', requireMe, (req, res, next) => {
  req.params.id = String(getMeId(req));
  return r._router.handle(req, res, next);
});
r.get('/me/comments', requireMe, (req, res, next) => {
  req.params.id = String(getMeId(req));
  return r._router.handle(req, res, next);
});

/* ───────── 추천 유저 ───────── */
r.get('/suggest', requireMe, async (req, res, next) => {
  try {
    const me = getMeId(req);
    const limit = Math.min(50, parseInt(req.query.limit) || 20);

    const meUser = await prisma.user.findUnique({
      where: { id: me },
      select: { department: true, university: true },
    });
    const myDept = meUser?.department ?? null;
    const myUniv = meUser?.university ?? '동서울대학교';

    const following = await prisma.follow.findMany({
      where: { follower_id: me },
      select: { following_id: true },
    });
    const followingIds = new Set(following.map((f) => f.following_id));

    const [sameDept, sameUniv, recent] = await Promise.all([
      prisma.user.findMany({
        where: {
          id: { not: me },
          department: myDept ?? undefined,
          university: myUniv,
        },
        orderBy: { id: 'desc' },
        take: limit * 2,
        select: {
          id: true,
          username: true,
          nickname: true,
          profile_img: true,
          department: true,
        },
      }),
      prisma.user.findMany({
        where: {
          id: { not: me },
          university: myUniv,
          department: myDept ? { not: myDept } : undefined,
        },
        orderBy: { id: 'desc' },
        take: limit * 2,
        select: {
          id: true,
          username: true,
          nickname: true,
          profile_img: true,
          department: true,
        },
      }),
      prisma.user.findMany({
        where: { id: { not: me } },
        orderBy: { id: 'desc' },
        take: limit * 2,
        select: {
          id: true,
          username: true,
          nickname: true,
          profile_img: true,
          department: true,
        },
      }),
    ]);

    const merged = [...sameDept, ...sameUniv, ...recent];
    const seen = new Set();
    const items = [];
    for (const u of merged) {
      if (followingIds.has(u.id)) continue;
      if (seen.has(u.id)) continue;
      seen.add(u.id);
      items.push(u);
      if (items.length >= limit) break;
    }

    return res.json({ items });
  } catch (e) {
    next(e);
  }
});

/* ───────── 공개 프로필 ───────── */

r.get('/:id', async (req, res, next) => {
  try {
    const id = Number(req.params.id);
    if (!Number.isInteger(id) || id <= 0)
      return res.status(400).json({ message: 'invalid id' });
    const user = await prisma.user.findUnique({
      where: { id },
      select: {
        id: true,
        username: true,
        nickname: true,
        profile_img: true,
        bio: true,
        department: true,
      },
    });
    if (!user) return res.status(404).json({ message: 'not found' });
    res.json({ user });
  } catch (e) {
    next(e);
  }
});

export default r;
