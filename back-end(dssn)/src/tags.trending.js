import { Router } from 'express';
import { prisma } from './lib/prisma.js';

const r = Router();

/**
 * GET /tags/trending?days=7&limit=10
 * - 최근 N일간 post_tag 사용량 상위 태그
 */
r.get('/trending', async (req, res, next) => {
  try {
    const days = Math.min(30, parseInt(req.query.days) || 7);
    const limit = Math.min(50, parseInt(req.query.limit) || 10);

    const since = new Date(Date.now() - days * 24 * 60 * 60 * 1000);

    // 최근 N일 내 작성된 게시글의 태그 집계
    const rows = await prisma.$queryRawUnsafe(
      `
      SELECT t.id, t.name, COUNT(*) AS usage_count
      FROM post_tag pt
      JOIN tag t       ON t.id = pt.tag_id
      JOIN post p      ON p.id = pt.post_id
      WHERE p.created_at >= ?
      GROUP BY t.id, t.name
      ORDER BY usage_count DESC, t.id ASC
      LIMIT ?
      `,
      since,
      limit
    );

    res.json({ items: rows });
  } catch (e) {
    next(e);
  }
});

export default r;
