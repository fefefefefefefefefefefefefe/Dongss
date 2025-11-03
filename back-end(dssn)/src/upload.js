import { Router } from 'express';
import multer from 'multer';
import path from 'path';
import fs from 'fs';
import crypto from 'crypto';
import { requireMe } from './mw.js';
import { toAbsoluteUrl } from './lib/url.js';
import imageSize from 'image-size';

const r = Router();

// 저장 폴더
const UPLOAD_DIR = path.resolve('uploads');
if (!fs.existsSync(UPLOAD_DIR)) fs.mkdirSync(UPLOAD_DIR, { recursive: true });

// 파일명: 해시_타임스탬프.ext
const storage = multer.diskStorage({
  destination: (_req, _file, cb) => cb(null, UPLOAD_DIR),
  filename: (_req, file, cb) => {
    const ext = path.extname(file.originalname || '').toLowerCase();
    const base = crypto.randomBytes(8).toString('hex');
    cb(null, `${base}_${Date.now()}${ext}`);
  },
});

// 타입/크기 제한
const upload = multer({
  storage,
  limits: { fileSize: 10 * 1024 * 1024 }, // 10MB
  fileFilter: (_req, file, cb) => {
    const ok = /^image\/(png|jpe?g|gif|webp|heic)$/i.test(file.mimetype);
    cb(ok ? null : new Error('only image allowed'), ok);
  },
});

// 체크섬 계산
function sha256File(absPath) {
  const hash = crypto.createHash('sha256');
  const buf = fs.readFileSync(absPath);
  hash.update(buf);
  return hash.digest('hex');
}

/**
 * POST /upload (로그인 필요)
 * form-data: file=<binary>
 * 응답:
 * {
 *   url: "/static/xxx.jpg",
 *   abs_url: "http://.../static/xxx.jpg"   // PUBLIC_BASE_URL 설정 시
 *   mime, size_bytes, width, height, checksum, storage
 * }
 */
r.post('/', requireMe, upload.single('file'), async (req, res, next) => {
  try {
    if (!req.file) return res.status(400).json({ message: 'file required' });

    const pubUrl = `/static/${req.file.filename}`;
    const absUrl = toAbsoluteUrl(pubUrl);

    let width = null,
      height = null;
    try {
      const dim = imageSize(req.file.path);
      width = dim?.width ?? null;
      height = dim?.height ?? null;
    } catch (_) {}

    const checksum = sha256File(req.file.path);

    return res.status(201).json({
      url: pubUrl,
      abs_url: absUrl,
      mime: req.file.mimetype,
      size_bytes: req.file.size,
      width,
      height,
      checksum,
      storage: 'local',
    });
  } catch (e) {
    if (e?.message === 'only image allowed') {
      return res.status(400).json({ message: 'only image allowed' });
    }
    if (e?.code === 'LIMIT_FILE_SIZE') {
      return res.status(400).json({ message: 'file too large (<=10MB)' });
    }
    next(e);
  }
});

export default r;
