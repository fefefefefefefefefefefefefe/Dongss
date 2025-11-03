// src/search.js
import { Router } from 'express';
import { prisma } from './lib/prisma.js';
import { optionalAuth } from './mw.js';

const r = Router();

/** 해시태그/멘션 파서 */
function parseQuery(q = '') {
  const raw = String(q || '').trim();
  const tags = Array.from(raw.matchAll(/#([A-Za-z0-9가-힣_]{1,50})/g)).map((m) => m[1]);
  const mentions = Array.from(raw.matchAll(/@([A-Za-z0-9_]{1,50})/g)).map((m) => m[1]);
  const cleaned = raw
    .replace(/#[^\s]+/g, ' ')
    .replace(/@[^\s]+/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
  return { raw, cleaned, tags, mentions };
}

/** MySQL: *_ci 컬레이션이면 기본적으로 case-insensitive */
const like = (s) => ({ contains: s });

/** 공통 페이지네이션 파라미터 */
const page = (req, def = 10, max = 50) => {
  const take = Math.min(max, Math.max(1, Number(req.query.limit) || def));
  const cursor = req.query.cursor ? Number(req.query.cursor) : null;
  return { take, cursor };
};

/* ===================== 통합 검색 ===================== */
/** GET /search?q=...&limit=10 */
r.get('/', optionalAuth, async (req, res, next) => {
  try {
    const q = String(req.query.q || '').slice(0, 120);
    if (!q) return res.status(400).json({ message: 'q required' });

    const { cleaned, tags, mentions } = parseQuery(q);
    const { take } = page(req, 6, 20);

    // Users
    const users = await prisma.user.findMany({
      where: mentions.length
        ? { OR: [{ username: { in: mentions } }, { nickname: { in: mentions } }] }
        : cleaned
        ? {
            OR: [
              { username: like(cleaned) },
              { nickname: like(cleaned) },
              { name: like(cleaned) },
              { department: like(cleaned) },
            ],
          }
        : undefined,
      take,
      orderBy: { id: 'asc' },
      select: {
        id: true,
        username: true,
        nickname: true,
        name: true,
        profile_img: true,
        department: true,
      },
    });

    // Communities
    const communitiesRaw = await prisma.community.findMany({
      where: cleaned ? { OR: [{ name: like(cleaned) }, { description: like(cleaned) }] } : undefined,
      take,
      orderBy: { id: 'desc' },
      select: {
        id: true,
        name: true,
        description: true,
        is_private: true,
        _count: { select: { posts: true, members: true } },
      },
    });
    const communities = communitiesRaw.map((c) => ({
      id: c.id,
      name: c.name,
      description: c.description,
      is_private: c.is_private,
      post_count: c._count.posts,
      member_count: c._count.members,
    }));

    // Posts
    let postsWhere = undefined;
    if (tags.length) {
      postsWhere = { post_tag: { some: { tag: { name: { in: tags } } } } };
    } else if (cleaned) {
      postsWhere = { OR: [{ title: like(cleaned) }, { content: like(cleaned) }] };
    }

    const posts = await prisma.post.findMany({
      where: postsWhere,
      take,
      orderBy: { id: 'desc' },
      include: {
        user: {
          select: {
            id: true,
            username: true,
            nickname: true,
            profile_img: true,
            department: true,
          },
        },
        post_file: true, // ✅ files → post_file
        post_tag: { include: { tag: true } }, // ✅ tags → post_tag
        _count: {
          select: { comment: true, post_like: true, bookmark: true, repost: true },
        },
      },
    });

    for (const p of posts) {
      const t =
        (p.post_file || []).find((f) => f.is_thumbnail) ||
        (p.post_file || [])[0];
      p.thumbnail_url = t?.file_url ?? null;
    }

    res.json({ query: q, parsed: { cleaned, tags, mentions }, users, communities, posts });
  } catch (e) {
    next(e);
  }
});

/* ============== 카테고리별 검색 (커서 안정화) ============== */

/** GET /search/users?q=...&limit=&cursor=  (asc, id > cursor) */
r.get('/users', optionalAuth, async (req, res, next) => {
  try {
    const q = String(req.query.q || '').trim();
    const { take, cursor } = page(req, 20, 50);

    const baseWhere = q
      ? {
          OR: [
            { username: like(q) },
            { nickname: like(q) },
            { name: like(q) },
            { department: like(q) },
          ],
        }
      : undefined;

    const where = cursor
      ? baseWhere
        ? { AND: [baseWhere, { id: { gt: cursor } }] }
        : { id: { gt: cursor } }
      : baseWhere;

    const items = await prisma.user.findMany({
      where,
      take,
      orderBy: { id: 'asc' },
      select: {
        id: true,
        username: true,
        nickname: true,
        name: true,
        profile_img: true,
        department: true,
      },
    });

    const next_cursor = items.length === take ? items[items.length - 1].id : null;
    res.json({ items, next_cursor });
  } catch (e) {
    next(e);
  }
});

/** GET /search/posts?q=키워드|#태그&limit=&cursor=  (desc, id < cursor) */
r.get('/posts', optionalAuth, async (req, res, next) => {
  try {
    const raw = String(req.query.q || '').trim();
    const { take, cursor } = page(req, 10, 50);
    const byTag = raw.startsWith('#') ? raw.slice(1) : null;

    const baseWhere = byTag
      ? { post_tag: { some: { tag: { name: byTag } } } } // ✅ tags → post_tag
      : raw
      ? { OR: [{ title: like(raw) }, { content: like(raw) }] }
      : undefined;

    const where = cursor
      ? baseWhere
        ? { AND: [baseWhere, { id: { lt: cursor } }] }
        : { id: { lt: cursor } }
      : baseWhere;

    const items = await prisma.post.findMany({
      where,
      take,
      orderBy: { id: 'desc' },
      include: {
        user: {
          select: {
            id: true,
            username: true,
            nickname: true,
            profile_img: true,
            department: true,
          },
        },
        post_file: true, // ✅
        post_tag: { include: { tag: true } }, // ✅
        _count: {
          select: { comment: true, post_like: true, bookmark: true, repost: true },
        },
      },
    });

    for (const p of items) {
      const t =
        (p.post_file || []).find((f) => f.is_thumbnail) ||
        (p.post_file || [])[0];
      p.thumbnail_url = t?.file_url ?? null;
    }

    const next_cursor = items.length === take ? items[items.length - 1].id : null;
    res.json({ items, next_cursor });
  } catch (e) {
    next(e);
  }
});

/** GET /search/tags?q=#키워드&limit=&cursor=  (asc, id > cursor) */
r.get('/tags', optionalAuth, async (req, res, next) => {
  try {
    const q = String(req.query.q || '').replace(/^#/, '').trim();
    const { take, cursor } = page(req, 20, 50);

    const baseWhere = q ? { name: like(q) } : undefined;
    const where = cursor
      ? baseWhere
        ? { AND: [baseWhere, { id: { gt: cursor } }] }
        : { id: { gt: cursor } }
      : baseWhere;

    const items = await prisma.tag.findMany({
      where,
      take,
      orderBy: { id: 'asc' },
      select: { id: true, name: true },
    });

    const next_cursor = items.length === take ? items[items.length - 1].id : null;
    res.json({ items, next_cursor });
  } catch (e) {
    next(e);
  }
});

export default r;
