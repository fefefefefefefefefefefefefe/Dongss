import 'dotenv/config';
import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcrypt';

const prisma = new PrismaClient();

const DEPARTMENTS = [
  '컴퓨터소프트웨어과',
  '디자인과',
  '경영학과',
  '호텔관광과',
  '전기과',
  '건축과',
];

function pickDept(i) {
  return DEPARTMENTS[i % DEPARTMENTS.length];
}

async function main() {
  const password = 'pass1234';
  const hash = await bcrypt.hash(password, 10);

  const users = [];
  for (let i = 1; i <= 10; i++) {
    const username = `testuser${i}`;
    const email = `test${i}@dsu.ac.kr`;
    const nickname = `테스터${i}`;
    const student_no = `2025${String(100000 + i).slice(1)}`; // 길이 <= 20 유니크
    const department = pickDept(i);

    // 여러 번 실행해도 안전하게 upsert
    const u = await prisma.user.upsert({
      where: { username }, // username 유니크
      update: {}, // 이미 있으면 그대로 둠
      create: {
        username,
        email,
        password: hash,
        name: `테스트사용자${i}`,
        student_no,
        nickname,
        gender: i % 2 ? 'M' : 'F',
        department,
        // university는 DB default("동서울대학교")
        email_verified: true, // 테스트 편의를 위해 인증 완료 처리
      },
      select: {
        id: true,
        username: true,
        email: true,
        nickname: true,
        department: true,
      },
    });
    users.push(u);
  }

  console.log('✅ Seeded users (password: pass1234)');
  console.table(users);
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
