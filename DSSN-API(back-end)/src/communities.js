import { Router } from 'express';
import { prisma } from './lib/prisma.js';
import { requireMe } from './mw.js';

const r = Router();

// 목록/검색
r.get('/', async (req, res, next) => {
  try {
    const q = String(req.query.q ?? '').trim();
    const where = q ? { name: { contains: q } } : {};
    const items = await prisma.community.findMany({
      where,
      orderBy: { id: 'desc' },
    });
    res.json(items);
  } catch (e) {
    next(e);
  }
});

// 생성: 누구나 가능(본인이 admin)
r.post('/', requireMe, async (req, res, next) => {
  try {
    const { name, description, is_private } = req.body;

    if (!name) return res.status(400).json({ message: 'name required' });

    const created = await prisma.community.create({
      data: {
        name,
        description: description ?? null,
        admin_id: req.me,
        // ← 숫자로 넘기지 말고 Boolean으로 넘기기!
        is_private: Boolean(is_private),
      },
      select: {
        id: true,
        name: true,
        description: true,
        is_private: true,
        admin_id: true,
        created_at: true,
      },
    });

    res.status(201).json(created);
  } catch (e) {
    if (e?.code === 'P2002')
      return res.status(409).json({ message: 'name already exists' });
    next(e);
  }
});

// 수정: 관리자만
r.put('/:id', requireMe, async (req, res, next) => {
  try {
    const id = Number(req.params.id);
    const cm = await prisma.community.findUnique({ where: { id } });
    if (!cm) return res.status(404).json({ message: 'not found' });
    if (cm.admin_id !== req.me)
      return res.status(403).json({ message: 'forbidden' });

    const data = {};
    if (req.body?.name) data.name = String(req.body.name);
    if ('description' in req.body)
      data.description = req.body.description ?? null;
    if ('is_private' in req.body) data.is_private = req.body.is_private ? 1 : 0;

    const updated = await prisma.community.update({ where: { id }, data });
    res.json(updated);
  } catch (e) {
    next(e);
  }
});

// 삭제: 관리자만
r.delete('/:id', requireMe, async (req, res, next) => {
  try {
    const id = Number(req.params.id);
    const cm = await prisma.community.findUnique({ where: { id } });
    if (!cm) return res.status(404).json({ message: 'not found' });
    if (cm.admin_id !== req.me)
      return res.status(403).json({ message: 'forbidden' });

    await prisma.community.delete({ where: { id } });
    res.json({ ok: true });
  } catch (e) {
    next(e);
  }
});

export default r;
