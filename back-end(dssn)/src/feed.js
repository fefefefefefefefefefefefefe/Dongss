import { Router } from 'express';
import { prisma } from './lib/prisma.js';
import { requireMe } from './mw.js';             // ✅ 추가

const r = Router();
const HOME_COMMUNITY_ID = Number(process.env.HOME_COMMUNITY_ID || 1);

function parseCursor(req) {
  const limit = Math.min(50, parseInt(req.query.limit, 10) || 20);
  const cursor = req.query.cursor ? Number(req.query.cursor) : undefined;
  return { limit, cursor };
}

const postInclude = {
  user: { select: { id: true, username: true, nickname: true, profile_img: true, department: true } },
  post_file: { select: { id: true, file_url: true, is_thumbnail: true } },
  post_tag: { include: { tag: true } },
  _count: { select: { comment: true, post_like: true, bookmark: true, repost: true } },
};

async function decorateViewer(items, viewerId) {
  if (!items?.length) return items;
  const ids = items.map(p => p.id);
  let likeSet = new Set(), bmSet = new Set(), rpSet = new Set();
  if (viewerId) {
    const [likes, bms, rps] = await Promise.all([
      prisma.post_like.findMany({ where: { user_id: viewerId, post_id: { in: ids } }, select: { post_id: true } }),
      prisma.bookmark.findMany({ where: { user_id: viewerId, post_id: { in: ids } }, select: { post_id: true } }),
      prisma.repost.findMany({ where: { user_id: viewerId, post_id: { in: ids } }, select: { post_id: true } }),
    ]);
    likeSet = new Set(likes.map(x => x.post_id));
    bmSet   = new Set(bms.map(x => x.post_id));
    rpSet   = new Set(rps.map(x => x.post_id));
  }
  for (const it of items) {
    it.viewer_has_liked      = viewerId ? likeSet.has(it.id) : false;
    it.viewer_has_bookmarked = viewerId ? bmSet.has(it.id) : false;
    it.viewer_has_reposted   = viewerId ? rpSet.has(it.id) : false;
    const thumb = (it.post_file || []).find(f => f.is_thumbnail) || (it.post_file || [])[0];
    it.thumbnail_url = thumb?.file_url ?? null;
  }
  return items;
}

/* ===== 홈 피드 ===== */
// 로그인 사용자만 보게 하려면 requireMe 넣기 (원하면 제거 가능)
r.get('/home', requireMe, async (req, res) => {
  try {
    const me = req.me ?? req.userId;
    const { limit, cursor } = parseCursor(req);
    const where = { community_id: HOME_COMMUNITY_ID, is_deleted: false, is_blinded: false };

    const findArgs = { where, include: postInclude, orderBy: { id: 'desc' }, take: limit + 1 };
    if (cursor) Object.assign(findArgs, { cursor: { id: Number(cursor) }, skip: 1 });

    let items = await prisma.post.findMany(findArgs);
    let next_cursor = null;
    if (items.length > limit) next_cursor = items.pop().id;

    await decorateViewer(items, me);
    res.json({ items, next_cursor });
  } catch (e) {
    res.status(500).json({ ok: false, message: 'home feed failed', detail: String(e?.message || e) });
  }
});

/* ===== 홈 글쓰기 ===== */
r.post('/home', requireMe, async (req, res) => {  // ✅ 인증 필수
  try {
    const me = req.me ?? req.userId;              // ✅ middleware가 채워줌
    let { title, content, files, tags } = req.body || {};
    title = (title ?? '').trim();
    content = String(content ?? '').trim();
    if (!content) return res.status(400).json({ message: 'content required' });

    const created = await prisma.post.create({
      data: { user_id: me, community_id: HOME_COMMUNITY_ID, title: title || null, content, visibility: 'public' },
      select: { id: true },
    });

    if (Array.isArray(files) && files.length > 0) {
      const data = files.filter(f => f?.url).map((f, idx) => ({
        post_id: created.id, file_url: String(f.url), is_thumbnail: !!f.is_thumbnail || idx === 0,
      }));
      if (data.length) await prisma.post_file.createMany({ data });
    }

    if (Array.isArray(tags) && tags.length > 0) {
      const tagRows = await Promise.all(
        tags.map((name) => prisma.tag.upsert({ where: { name }, update: {}, create: { name }, select: { id: true } }))
      );
      if (tagRows.length) {
        await prisma.post_tag.createMany({
          data: tagRows.map(t => ({ post_id: created.id, tag_id: t.id })), skipDuplicates: true,
        });
      }
    }

    res.status(201).json({ id: created.id });
  } catch (e) {
    res.status(500).json({ ok: false, message: 'home post failed', detail: String(e?.message || e) });
  }
});

export default r;
