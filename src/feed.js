// 피드 라우트 (팔로잉 타임라인 + 커서)

import { Router } from 'express';
import { prisma } from './lib/prisma.js';
import { extractTags } from './lib/tags.js';
import { getMe } from './lib/me.js';

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
          postFile: true, // PostFile 모델 명이 다르면 수정
          postTag: { include: { tag: true } }, // PostTag/Tag 명도 확인
          _count: {
            select: {
              comment: true,
              postLike: true,
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
        await tx.postFile.createMany({
          data: files.map((url, i) => ({
            post_id: post.id,
            file_url: url,
            is_thumbnail: i === 0 ? 1 : 0,
          })),
        });
      }

      // 태그 upsert + post_tag 연결
      for (const tagName of tags) {
        const tag = await tx.tag.upsert({
          where: { name: tagName },
          create: { name: tagName },
          update: {},
        });
        await tx.postTag.upsert({
          where: { post_id_tag_id: { post_id: post.id, tag_id: tag.id } }, // 복합 PK/유니크 alias 확인 필요
          create: { post_id: post.id, tag_id: tag.id },
          update: {},
        });
      }

      return post;
    });

    res.status(201).json(created);
  } catch (e) {
    next(e);
  }
});

export default r;
