import { Router } from 'express';
import bcrypt from 'bcryptjs';
import { prisma } from './lib/prisma.js';
import { requireMe } from './mw.js';

const r = Router();

// 공통: 응답에서 민감정보 제거
const userOut = (u) => {
  if (!u) return u;
  const { password, ...rest } = u; // password 필드가 있더라도 제거
  return rest;
};

// 목록 (page, limit, q 검색)
r.get('/', async (req, res, next) => {
  try {
    const page = Math.max(1, parseInt(req.query.page) || 1);
    const limit = Math.min(100, parseInt(req.query.limit) || 20);
    const skip = (page - 1) * limit;
    const q = String(req.query.q ?? '').trim();

    const where = q
      ? {
          OR: [
            { username: { contains: q } },
            { nickname: { contains: q } },
            { name: { contains: q } },
          ],
        }
      : {};

    const [items, total] = await Promise.all([
      prisma.user.findMany({
        where,
        skip,
        take: limit,
        orderBy: { created_at: 'desc' }, // introspect된 필드명 유지
        select: {
          id: true,
          username: true,
          email: true,
          name: true,
          nickname: true,
          profile_img: true,
          created_at: true,
          // password: false  // select 사용 시 기본적으로 제외되지만 방어적으로 위 userOut도 사용
        },
      }),
      prisma.user.count({ where }),
    ]);

    res.json({ page, limit, total, items: items.map(userOut) });
  } catch (e) {
    next(e);
  }
});

// 단건 조회
r.get('/:id', async (req, res, next) => {
  try {
    const id = Number(req.params.id);
    if (!Number.isFinite(id))
      return res.status(400).json({ message: 'invalid id' });

    const user = await prisma.user.findUnique({
      where: { id },
      select: {
        id: true,
        username: true,
        email: true,
        name: true,
        nickname: true,
        bio: true,
        website: true,
        profile_img: true,
        created_at: true,
      },
    });
    if (!user) return res.status(404).json({ message: 'Not found' });
    res.json(userOut(user));
  } catch (e) {
    next(e);
  }
});

// 회원가입 (username/email unique, password 해시)
r.post('/', async (req, res, next) => {
  try {
    const username = String(req.body?.username ?? '').trim();
    const email = String(req.body?.email ?? '').trim();
    const name = req.body?.name ?? null;
    const password = String(req.body?.password ?? '');

    if (!username || !email || !password) {
      return res
        .status(400)
        .json({ message: 'username, email, password required' });
    }
    if (password.length < 6) {
      return res
        .status(400)
        .json({ message: 'password must be at least 6 chars' });
    }

    const hash = await bcrypt.hash(password, 10);

    const created = await prisma.user.create({
      data: { username, email, password: hash, name },
      select: {
        id: true,
        username: true,
        email: true,
        name: true,
        nickname: true,
        profile_img: true,
        created_at: true,
      },
    });
    res.status(201).json(userOut(created));
  } catch (e) {
    if (e?.code === 'P2002') {
      // Prisma unique 에러: meta.target 로 어떤 유니크인지 확인 가능
      return res
        .status(409)
        .json({ message: 'username or email already exists' });
    }
    next(e);
  }
});

// 내 정보 수정 (본인만)
r.put('/me', requireMe, async (req, res, next) => {
  try {
    const up = {};
    const allow = [
      'name',
      'nickname',
      'bio',
      'website',
      'profile_img',
      'location',
      'status',
    ];
    for (const k of allow) if (k in req.body) up[k] = req.body[k];

    // 비밀번호 변경(옵션)
    if (req.body?.password) {
      const newPwd = String(req.body.password);
      if (newPwd.length < 6)
        return res
          .status(400)
          .json({ message: 'password must be at least 6 chars' });
      up.password = await bcrypt.hash(newPwd, 10);
    }

    // 이메일/유저명 변경 옵션 (원하면 허용)
    if (req.body?.email) up.email = String(req.body.email).trim();
    if (req.body?.username) up.username = String(req.body.username).trim();

    const updated = await prisma.user.update({
      where: { id: req.me },
      data: up,
      select: {
        id: true,
        username: true,
        email: true,
        name: true,
        nickname: true,
        bio: true,
        website: true,
        profile_img: true,
        location: true,
        status: true,
        created_at: true,
      },
    });
    res.json(userOut(updated));
  } catch (e) {
    if (e?.code === 'P2002') {
      return res
        .status(409)
        .json({ message: 'username or email already exists' });
    }
    next(e);
  }
});

// 내 계정 삭제(하드 삭제; 필요하면 소프트로 변경)
r.delete('/me', requireMe, async (req, res, next) => {
  try {
    await prisma.user.delete({ where: { id: req.me } });
    res.status(204).end();
  } catch (e) {
    next(e);
  }
});

export default r;
