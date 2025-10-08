// src/routes/users.js
import { Router } from 'express';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { prisma } from '../lib/prisma.js';

const r = Router();

// 토큰 유틸
const signToken = (userId) =>
  jwt.sign({ sub: userId }, process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_EXPIRES || '7d',
  });

// 응답에서 보여줄 필드만 정리
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
  university: u.university,
  email_verified: u.email_verified,
  created_at: u.created_at,
});

/**
 * 회원가입 (+ 즉시 JWT 발급)
 * body:
 * {
 *   username, email, password, name?,
 *   student_no, nickname, gender?, department?, birthday? (YYYY-MM-DD)
 *   // university는 DB default "동서울대학교"
 * }
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
      birthday, // "2003-08-15"
    } = req.body ?? {};

    // 필수값 체크
    if (!username || !email || !password || !student_no || !nickname) {
      return res.status(400).json({
        message: 'username, email, password, student_no, nickname are required',
      });
    }
    if (String(password).length < 6) {
      return res
        .status(400)
        .json({ message: 'password must be at least 6 chars' });
    }

    // 중복 선확인 (username/email/nickname/student_no)
    const dup = await prisma.user.findFirst({
      where: {
        OR: [
          { username: String(username) },
          { email: String(email) },
          { nickname: String(nickname) },
          { student_no: String(student_no) },
        ],
      },
      select: { id: true },
    });
    if (dup)
      return res
        .status(409)
        .json({ message: 'duplicate: username/email/nickname/student_no' });

    const hash = await bcrypt.hash(String(password), 10);

    // 유저 생성 (university는 스키마 default: "동서울대학교")
    const created = await prisma.user.create({
      data: {
        username: String(username).trim(),
        email: String(email).trim(),
        password: hash,
        name: name ?? null,
        student_no: String(student_no).trim(),
        nickname: String(nickname).trim(),
        gender: gender ?? null,
        department: department ?? null,
        birthday: birthday ? new Date(birthday) : null,
        // university: 생략하면 default 적용
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

    // (선택) 이메일 인증 코드도 발급해서 저장하고 싶은 경우 — 주석 해제해서 사용
    /*
    const code = Math.floor(100000 + Math.random() * 900000).toString();
    const expires = new Date(Date.now() + 15 * 60 * 1000);
    await prisma.emailVerification.create({
      data: { email: created.email, code, purpose: 'signup', expiresAt: expires, userId: created.id },
    });
    */

    // 회원가입 직후 토큰 발급
    const token = signToken(created.id);

    res.status(201).json({
      user: userOut(created),
      token, // 프론트는 이 토큰을 Bearer로 저장하여 즉시 로그인 상태 유지
      // verify_hint: code && `개발모드 이메일 코드: ${code}` // 위 주석 사용 시
    });
  } catch (e) {
    if (e?.code === 'P2002') {
      // Prisma unique 충돌
      return res.status(409).json({ message: 'unique constraint failed' });
    }
    next(e);
  }
});

export default r;
