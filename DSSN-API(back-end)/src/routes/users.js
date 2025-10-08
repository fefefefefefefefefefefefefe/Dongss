import { Router } from 'express';
import { prisma } from '../lib/prisma.js';
import { requireAuth } from '../mw.js';

const r = Router();

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

/** GET /users/me */
r.get('/me', requireAuth, async (req, res, next) => {
  try {
    const me = await prisma.user.findUnique({
      where: { id: req.userId },
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
r.patch('/me', requireAuth, async (req, res, next) => {
  try {
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
      where: { id: req.userId },
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

/** 공개 프로필 */
r.get('/:id', async (req, res, next) => {
  try {
    const id = Number(req.params.id);
    if (!Number.isInteger(id) || id <= 0) {
      return res.status(400).json({ message: 'invalid id' });
    }

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
