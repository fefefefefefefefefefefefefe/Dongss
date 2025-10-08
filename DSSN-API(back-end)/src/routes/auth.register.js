import { Router } from 'express';
import bcrypt from 'bcryptjs';
import { prisma } from '../lib/prisma.js';

const r = Router();

// 옵션: 회원가입 시 토큰도 같이 발급하려면 true로
const ISSUE_TOKEN_ON_REGISTER = false; // 필요하면 true
let signToken; // true일 때만 동적 import
if (ISSUE_TOKEN_ON_REGISTER) {
  const jwt = await import('jsonwebtoken');
  signToken = (uid) =>
    jwt.default.sign({ sub: uid }, process.env.JWT_SECRET, {
      expiresIn: process.env.JWT_EXPIRES || '7d',
    });
}

/**
 * POST /auth/register
 * body: { username, email, password, name?, student_no, nickname, gender?, department?, birthday? }
 * university는 DB default("동서울대학교")
 */
r.post('/', async (req, res, next) => {
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

    // 기본 검증 & 정규화
    const u = String(username || '').trim();
    const em = String(email || '')
      .trim()
      .toLowerCase();
    const pw = String(password || '');

    if (!u || !em || !pw || !student_no || !nickname) {
      return res
        .status(400)
        .json({
          message:
            'username, email, password, student_no, nickname are required',
        });
    }
    if (pw.length < 6) {
      return res
        .status(400)
        .json({ message: 'password must be at least 6 chars' });
    }

    // 중복 선확인
    const dup = await prisma.user.findFirst({
      where: {
        OR: [{ username: u }, { email: em }, { nickname }, { student_no }],
      },
      select: { id: true },
    });
    if (dup)
      return res
        .status(409)
        .json({ message: 'duplicate: username/email/nickname/student_no' });

    const hash = await bcrypt.hash(pw, 10);

    const created = await prisma.user.create({
      data: {
        username: u,
        email: em,
        password: hash,
        name: name ?? null,
        student_no: String(student_no).trim(),
        nickname: String(nickname).trim(),
        gender: gender ?? null,
        department: department ?? null,
        birthday: birthday ? new Date(birthday) : null,
        // university: default("동서울대학교")
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

    if (ISSUE_TOKEN_ON_REGISTER) {
      const token = signToken(created.id);
      return res.status(201).json({ user: created, token });
    }
    return res.status(201).json({ user: created });
  } catch (e) {
    if (e?.code === 'P2002')
      return res.status(409).json({ message: 'unique constraint failed' });
    next(e);
  }
});

export default r;
