import { z } from 'zod';

export const registerSchema = z.object({
  username: z.string().min(3).max(30),
  email: z.string().email(),
  password: z.string().min(6).max(72),
  name: z.string().max(50).optional().nullable(),
  student_no: z.string().min(4).max(20),
  nickname: z.string().min(2).max(20),
  gender: z.enum(['male', 'female', 'other']).optional().nullable(),
  department: z.string().max(100).optional().nullable(),
  birthday: z
    .string()
    .regex(/^\d{4}-\d{2}-\d{2}$/)
    .optional(),
});

export const loginSchema = z
  .object({
    username: z.string().optional(),
    email: z.string().email().optional(),
    password: z.string().min(6),
  })
  .refine((d) => d.username || d.email, {
    message: 'username or email required',
  });

export const validate = (schema) => (req, res, next) => {
  const parsed = schema.safeParse(req.body);
  if (!parsed.success) {
    const msg = parsed.error.issues.map((i) => i.message).join(', ');
    return res.status(400).json({ message: msg });
  }
  req.body = parsed.data; // 정제된 값으로 교체
  next();
};
