// src/communities.js
import { Router } from 'express';
import { prisma } from './lib/prisma.js';
import { requireMe } from './mw.js';

const r = Router();

/* ============================================================
 * 카테고리(라벨)
 * ============================================================ */
export const COMMUNITY_CATEGORIES = {
  free: '자유게시판',
  qna:  '질문게시판',
  info: '정보공유 게시판',
};
const CAT_KEYS = Object.keys(COMMUNITY_CATEGORIES); // ['free','qna','info']

/* ============================================================
 * 유틸
 * ============================================================ */
const N = (v) => (v === undefined ? undefined : Number(v));
function parseCursor(req) {
  const limit  = Math.min(50, parseInt(req.query.limit) || 20);
  const cursor = req.query.cursor ? Number(req.query.cursor) : undefined;
  return { limit, cursor };
}
async function isMember(userId, communityId) {
  if (!userId || !communityId) return false;
  const m = await prisma.community_member.findFirst({
    where: { user_id: userId, community_id: communityId },
    select: { user_id: true },
  });
  return !!m;
}

const baseInclude = {
  user: {
    select: { id: true, username: true, nickname: true, profile_img: true, department: true },
  },
  post_file: true,
  post_tag: { include: { tag: true } },
  _count: { select: { comment: true, post_like: true, bookmark: true, repost: true } },
};

async function decoratePosts(items, me) {
  if (!items?.length) return items;
  const ids = items.map(i => i.id);

  let likeSet = new Set(), bmSet = new Set(), rpSet = new Set();
  if (me) {
    const [likes, bms, rps] = await Promise.all([
      prisma.post_like.findMany({ where: { user_id: me, post_id: { in: ids } }, select: { post_id: true } }),
      prisma.bookmark.findMany({ where: { user_id: me, post_id: { in: ids } }, select: { post_id: true } }),
      prisma.repost.findMany({ where: { user_id: me, post_id: { in: ids } }, select: { post_id: true } }),
    ]);
    likeSet = new Set(likes.map(x => x.post_id));
    bmSet   = new Set(bms.map(x => x.post_id));
    rpSet   = new Set(rps.map(x => x.post_id));
  }

  for (const it of items) {
    it.viewer_has_liked      = me ? likeSet.has(it.id) : false;
    it.viewer_has_bookmarked = me ? bmSet.has(it.id) : false;
    it.viewer_has_reposted   = me ? rpSet.has(it.id) : false;

    const thumb = (it.post_file || []).find(f => f.is_thumbnail) || (it.post_file || [])[0];
    it.thumbnail_url = thumb?.file_url ?? null;
  }
  return items;
}

/* ============================================================
 * 0) 카테고리(탭) 목록
 * GET /communities/categories
 * ============================================================ */
r.get('/categories', requireMe, (_req, res) => {
  res.json({ items: CAT_KEYS.map(k => ({ key: k, name: COMMUNITY_CATEGORIES[k] })) });
});

/* ============================================================
 * 1) 커뮤니티 목록
 * GET /communities?limit=20
 * ============================================================ */
r.get('/', requireMe, async (req, res, next) => {
  try {
    const limit = Math.min(100, parseInt(req.query.limit) || 20);
    const items = await prisma.community.findMany({
      take: limit,
      orderBy: { id: 'asc' },
      select: { id: true, name: true, description: true, is_private: true },
    });
    res.json({ items });
  } catch (e) { next(e); }
});

/* ============================================================
 * 2) 커뮤니티 가입/탈퇴 (private일 때만 실의미)
 * ============================================================ */
// POST /communities/:id/join
r.post('/:id/join', requireMe, async (req, res, next) => {
  try {
    const me  = req.me ?? req.userId;
    const cid = Number(req.params.id);
    if (!Number.isInteger(cid) || cid <= 0) return res.status(400).json({ message: 'invalid id' });

    await prisma.community_member.upsert({
      where: { uq_cmember: { community_id: cid, user_id: me } },
      update: {},
      create: { community_id: cid, user_id: me, role: 'MEMBER' },
    });
    res.json({ ok: true });
  } catch (e) { next(e); }
});

// POST /communities/:id/leave
r.post('/:id/leave', requireMe, async (req, res, next) => {
  try {
    const me  = req.me ?? req.userId;
    const cid = Number(req.params.id);
    if (!Number.isInteger(cid) || cid <= 0) return res.status(400).json({ message: 'invalid id' });

    await prisma.community_member.delete({
      where: { uq_cmember: { community_id: cid, user_id: me } },
    }).catch(() => {});
    res.json({ ok: true });
  } catch (e) { next(e); }
});

/* ============================================================
 * 3) 커뮤니티 피드 (무한스크롤)
 * GET /communities/:id/feed?category=free|qna|info&limit=10&cursor=25
 *  - private이면 멤버만 조회 가능 / public이면 누구나(로그인만)
 * ============================================================ */
r.get('/:id/feed', requireMe, async (req, res, next) => {
  try {
    const me  = req.me ?? req.userId;
    const cid = Number(req.params.id);
    if (!Number.isInteger(cid) || cid <= 0) return res.status(400).json({ message: 'invalid id' });

    let category = String(req.query.category || 'free').trim();
    if (!CAT_KEYS.includes(category)) category = 'free';

    const cm = await prisma.community.findUnique({
      where: { id: cid },
      select: { id: true, is_private: true },
    });
    if (!cm) return res.status(404).json({ message: 'not found' });

    if (cm.is_private && !(await isMember(me, cid))) {
      return res.status(403).json({ message: 'private' });
    }

    const { limit, cursor } = parseCursor(req);
    const findArgs = {
      where: { community_id: cid, is_deleted: false, category },
      include: baseInclude,
      orderBy: { id: 'desc' },
      take: limit + 1,
    };
    if (cursor) Object.assign(findArgs, { cursor: { id: cursor }, skip: 1 });

    let items = await prisma.post.findMany(findArgs);
    let next_cursor = null;
    if (items.length > limit) {
      const last = items.pop();
      next_cursor = last.id;
    }
    await decoratePosts(items, me);
    res.json({ items, next_cursor });
  } catch (e) { next(e); }
});

/* ============================================================
 * 4) 커뮤니티 글 작성
 * POST /communities/:id/posts
 * body: { title?, content, category?, files?: [{url, is_thumbnail?}] }
 *  - public 커뮤니티: 가입 필요 없음(로그인만)
 *  - private 커뮤니티: 멤버만 작성 가능
 *  - id→카테고리 자동매핑(2=free, 3=qna, 4=info) + 수동 category 허용
 * ============================================================ */
r.post('/:id/posts', requireMe, async (req, res, next) => {
  try {
    const me  = req.me ?? req.userId;
    const cid = Number(req.params.id);
    if (!Number.isInteger(cid) || cid <= 0) return res.status(400).json({ message: 'invalid id' });

    const comm = await prisma.community.findUnique({
      where: { id: cid },
      select: { id: true, is_private: true },
    });
    if (!comm) return res.status(404).json({ message: 'not found' });

    // private이면 멤버십 필요, public이면 통과
    if (comm.is_private && !(await isMember(me, cid))) {
      return res.status(403).json({ message: 'join required' });
    }

    let { title, content, category, files } = req.body ?? {};
    title   = (title ?? '').trim();
    content = String(content ?? '').trim();

    // id 기반 카테고리 자동 매핑(원하면 body.category로 덮어쓰기 가능)
    const idToCat = { 2: 'free', 3: 'qna', 4: 'info' };
    const autoCat = idToCat[cid] || 'free';
    category = String((category ?? autoCat)).trim();
    if (!CAT_KEYS.includes(category)) category = 'free';

    if (!content) return res.status(400).json({ message: 'content required' });

    const created = await prisma.post.create({
      data: {
        user_id: me,
        community_id: cid,
        category,
        title: title || null,
        content,
      },
      select: { id: true },
    });

    if (Array.isArray(files) && files.length > 0) {
      const data = files
        .filter(f => f?.url)
        .map((f, idx) => ({
          post_id: created.id,
          file_url: String(f.url),
          is_thumbnail: !!f.is_thumbnail || idx === 0,
        }));
      if (data.length) await prisma.post_file.createMany({ data });
    }

    res.status(201).json({ id: created.id });
  } catch (e) { next(e); }
});

/* ============================================================
 * 5) 글 삭제(작성자/관리자) — 소프트 삭제
 * DELETE /communities/:id/posts/:postId
 * ============================================================ */
r.delete('/:id/posts/:postId', requireMe, async (req, res, next) => {
  try {
    const me  = req.me ?? req.userId;
    const cid = Number(req.params.id);
    const pid = Number(req.params.postId);

    const post = await prisma.post.findUnique({
      where: { id: pid },
      select: { id: true, user_id: true, community_id: true, is_deleted: true },
    });
    if (!post || post.community_id !== cid) return res.status(404).json({ message: 'not found' });
    if (post.is_deleted) return res.json({ ok: true });

    const cm = await prisma.community_member.findFirst({
      where: { community_id: cid, user_id: me },
      select: { role: true },
    });
    const isAdmin = cm?.role === 'ADMIN';
    if (!(isAdmin || post.user_id === me)) return res.status(403).json({ message: 'forbidden' });

    await prisma.post.update({ where: { id: pid }, data: { is_deleted: true } });
    res.json({ ok: true });
  } catch (e) { next(e); }
});

export default r;
