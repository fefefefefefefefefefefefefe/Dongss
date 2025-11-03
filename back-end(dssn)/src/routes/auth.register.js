// src/routes/auth.register.js
import { Router } from 'express';
import bcrypt from 'bcryptjs'; // ✅ bcryptjs로 통일
import { prisma } from '../lib/prisma.js';
import { signAccess, signRefresh } from '../lib/jwt.js';

const r = Router();
const ISSUE_TOKEN_ON_REGISTER = true;
const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

/** POST /auth/register */
r.post('/register', async (req, res, next) => {
  // ✅ 경로 '/register'
  try {
    const {
      username,
      email,
      password,
      name,
      student_no,
      nickname,
      gender,
      department,
      birthday,
    } = req.body ?? {};

    // 1) 정규화
    const u = String(username || '').trim();
    const em = String(email || '')
      .trim()
      .toLowerCase();
    const pw = String(password || '');
    const sn = String(student_no ?? '').trim();
    const nn = String(nickname ?? '').trim();
    const dept = department == null ? null : String(department).trim() || null;
    const gen = gender == null ? null : String(gender).trim() || null;

    // 2) 필수값 & 검증
    if (!u || !em || !pw || !sn || !nn) {
      return res
        .status(400)
        .json({
          message:
            'username, email, password, student_no, nickname are required',
        });
    }
    if (!EMAIL_REGEX.test(em))
      return res.status(400).json({ message: 'Invalid email address' });
    if (pw.length < 6)
      return res
        .status(400)
        .json({ message: 'password must be at least 6 chars' });

    // 3) 중복 체크
    const dup = await prisma.user.findFirst({
      where: {
        OR: [
          { username: u },
          { email: em },
          { nickname: nn },
          { student_no: sn },
        ],
      },
      select: { id: true },
    });
    if (dup)
      return res
        .status(409)
        .json({ message: 'duplicate: username/email/nickname/student_no' });

    // 4) 해시 & 옵션 필드
    const hash = await bcrypt.hash(pw, 10);
    let birthdayDate = null;
    if (birthday) {
      const d = new Date(birthday);
      if (!isNaN(d.getTime())) birthdayDate = d;
    }

    // 5) 생성
    const created = await prisma.user.create({
      data: {
        username: u,
        email: em,
        password: hash,
        name: name ?? null,
        student_no: sn,
        nickname: nn,
        gender: gen,
        department: dept,
        birthday: birthdayDate,
      },
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
        university: true,
        email_verified: true,
        created_at: true,
      },
    });

    // 6) 토큰
    if (ISSUE_TOKEN_ON_REGISTER) {
      if (!process.env.JWT_SECRET)
        return res.status(500).json({ message: 'JWT_SECRET not configured' });
      const ver = 0; // token_version 사용 시 교체
      const access = signAccess(created.id, ver);
      const refresh = signRefresh(created.id, ver);
      return res.status(201).json({ user: created, access, refresh });
    }
    return res.status(201).json({ user: created });
  } catch (e) {
    if (e?.code === 'P2002')
      return res.status(409).json({ message: 'unique constraint failed' });
    next(e);
  }
});

export default r; // ✅ 꼭 필요
