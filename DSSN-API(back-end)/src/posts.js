// 게시글 라우트 (생성/목록 + 태그, 파일)

import { Router } from 'express';
import { prisma } from './lib/prisma.js';
import { extractTags } from './lib/tags.js';
import { getMe } from './lib/me.js';
import { requireMe, assertOwner } from './mw.js';

const r = Router();

/** 목록: 커뮤니티별 또는 전체 */
r.get('/', async (req, res, next) => {
  try {
    const communityId = req.query.community_id
      ? Number(req.query.community_id)
      : undefined;
    const page = Math.max(1, parseInt(req.query.page) || 1);
    const limit = Math.min(50, parseInt(req.query.limit) || 20);
    const skip = (page - 1) * limit;

    const where = communityId ? { community_id: communityId } : {};
    const [items, total] = await Promise.all([
      prisma.post.findMany({
        where,
        skip,
        take: limit,
        orderBy: { id: 'desc' }, // created_at로 바꿔도 됨
        include: {
          user: {
            select: {
              id: true,
              username: true,
              nickname: true,
              profile_img: true,
            },
          },
          post_file: true, // PostFile 모델 명이 다르면 수정
          post_tag: { include: { tag: true } }, // PostTag/Tag 명도 확인
          _count: {
            select: {
              comment: true,
              post_like: true,
              bookmark: true,
              repost: true,
            },
          },
        },
      }),
      prisma.post.count({ where }),
    ]);
    res.json({ page, limit, total, items });
  } catch (e) {
    next(e);
  }
});

/** 생성: 태그(#), 파일 URL 배열(optional) */
r.post('/', async (req, res, next) => {
  try {
    const me = getMe(req);
    if (!me)
      return res
        .status(401)
        .json({ message: 'x-user-id header required (temp)' });

    const { community_id, title, content, files = [] } = req.body;
    if (!community_id || (!title && !content)) {
      return res
        .status(400)
        .json({ message: 'community_id and title|content required' });
    }

    const tags = extractTags(`${title ?? ''} ${content ?? ''}`);
    const created = await prisma.$transaction(async (tx) => {
      const post = await tx.post.create({
        data: { user_id: me, community_id, title, content },
      });

      // 파일 저장 (file_url만, 필요하면 file_type/is_thumbnail도 세팅)
      if (Array.isArray(files) && files.length) {
        await tx.post_file.createMany({
          data: files.map((url, i) => ({
            post_id: post.id,
            file_url: url,
            is_thumbnail: i === 0, // ✅ 불리언(true/false)
          })),
        });
      }

      // 태그 upsert + post_tag 연결 (스키마가 post_tag 이므로 post_tag 사용)
      for (const tagName of tags) {
        const tag = await tx.tag.upsert({
          where: { name: tagName },
          create: { name: tagName },
          update: {},
        });
        // post_tag는 (post_id, tag_id) 복합 PK/유니크이므로 create 시 중복이면 P2002 발생 → 무시
        await tx.post_tag
          .create({ data: { post_id: post.id, tag_id: tag.id } })
          .catch((e) => {
            if (e?.code !== 'P2002') throw e;
          });
      }

      return post;
    });

    res.status(201).json(created);
  } catch (e) {
    next(e);
  }
});

// 수정: 작성자만
r.put('/:id', requireMe, async (req, res, next) => {
  try {
    const id = Number(req.params.id);
    const p = await prisma.post.findUnique({ where: { id } });
    if (!p) return res.status(404).json({ message: 'not found' });
    if (!assertOwner(p.user_id, req.me, res)) return;

    const data = {};
    if ('title' in req.body) data.title = req.body.title ?? null;
    if ('content' in req.body) data.content = req.body.content ?? null;
    if ('is_deleted' in req.body) data.is_deleted = req.body.is_deleted ? 1 : 0;

    const updated = await prisma.post.update({ where: { id }, data });
    res.json(updated);
  } catch (e) {
    next(e);
  }
});

// 삭제: 작성자만(소프트 대신 하드 삭제)
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
