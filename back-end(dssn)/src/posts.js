// 게시글 라우트 (목록/생성/수정/삭제 + 상세)

import { Router } from 'express';
import { prisma } from './lib/prisma.js';
import { extractTags } from './lib/tags.js';
import { requireMe, assertOwner } from './mw.js';

const r = Router();

/* 공통 */
function parsePage(req) {
  const limit = Math.min(50, parseInt(req.query.limit) || 20);
  const cursor = req.query.cursor ? Number(req.query.cursor) : undefined;
  return { limit, cursor };
}

const baseInclude = {
  user: {
    select: { id: true, username: true, nickname: true, profile_img: true },
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

/** 목록: 전체/커뮤니티별/홈피드 전용(home=1)
 *  - page 기반 → 커서 기반으로 개선
 *  - 호환 위해 page/limit가 오면 page 사용, 아니면 cursor 사용
 */
r.get('/', async (req, res, next) => {
  try {
    const communityId = req.query.community_id
      ? Number(req.query.community_id)
      : undefined;
    const homeOnly = String(req.query.home ?? '') === '1';

    // 커서 우선
    const { limit, cursor } = parsePage(req);

    const where = communityId
      ? { community_id: communityId }
      : homeOnly
      ? { community_id: null } // 네 기존 로직 유지(홈을 community null로 운영한다면)
      : {};

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

    await decorateViewerFlagsAndThumb(items, req.me ?? null);
    res.json({ items, next_cursor });
  } catch (e) {
    next(e);
  }
});

/** 생성: 태그(#), 파일 URL 배열(optional), community_id는 선택 */
r.post('/', requireMe, async (req, res, next) => {
  try {
    const me = req.me;
    const { community_id, title, content, files = [] } = req.body ?? {};

    if (!title && !content) {
      return res
        .status(400)
        .json({ message: 'title 또는 content 중 하나는 필요합니다.' });
    }

    const cid = community_id ? Number(community_id) : null; // 홈을 null로 운영하면 그대로 허용
    const tags = extractTags(`${title ?? ''} ${content ?? ''}`);

    const created = await prisma.$transaction(async (tx) => {
      const post = await tx.post.create({
        data: {
          user_id: me,
          community_id: cid,
          title: title ?? null,
          content: content ?? null,
        },
        select: { id: true },
      });

      if (Array.isArray(files) && files.length) {
        await tx.post_file.createMany({
          data: files
            .map((url, i) => ({
              post_id: post.id,
              file_url: typeof url === 'string' ? url : String(url?.url || ''),
              is_thumbnail: i === 0,
            }))
            .filter((x) => x.file_url),
        });
      }

      for (const tagName of tags) {
        const tag = await tx.tag.upsert({
          where: { name: tagName },
          create: { name: tagName },
          update: {},
        });
        await tx.post_tag
          .create({ data: { post_id: post.id, tag_id: tag.id } })
          .catch((e) => {
            if (e?.code !== 'P2002') throw e; // 중복이면 무시
          });
      }

      return post;
    });

    res.status(201).json(created);
  } catch (e) {
    if (e?.code === 'P2003')
      return res.status(400).json({ message: 'Invalid community_id' });
    next(e);
  }
});

/** 상세: GET /posts/:id */
r.get('/:id', async (req, res, next) => {
  try {
    const id = Number(req.params.id);
    const me = req.me ?? null;

    const post = await prisma.post.findUnique({
      where: { id },
      include: baseInclude,
    });
    if (!post) return res.status(404).json({ message: 'not found' });

    await decorateViewerFlagsAndThumb([post], me);
    res.json({ post });
  } catch (e) {
    next(e);
  }
});

/** 수정: 작성자만 */
r.put('/:id', requireMe, async (req, res, next) => {
  try {
    const id = Number(req.params.id);
    const p = await prisma.post.findUnique({ where: { id } });
    if (!p) return res.status(404).json({ message: 'not found' });
    if (!assertOwner(p.user_id, req.me, res)) return;

    const data = {};
    if ('title' in req.body) data.title = req.body.title ?? null;
    if ('content' in req.body) data.content = req.body.content ?? null;
    if ('is_deleted' in req.body) data.is_deleted = !!req.body.is_deleted;

    const updated = await prisma.post.update({ where: { id }, data });
    res.json(updated);
  } catch (e) {
    next(e);
  }
});

/** 삭제: 작성자만(하드 삭제) */
r.delete('/:id', requireMe, async (req, res, next) => {
  try {
    const id = Number(req.params.id);
    const p = await prisma.post.findUnique({ where: { id } });
    if (!p) return res.status(404).json({ message: 'not found' });
    if (!assertOwner(p.user_id, req.me, res)) return;

    await prisma.post.delete({ where: { id } });
    res.json({ ok: true });
  } catch (e) {
    next(e);
  }
});

export default r;
