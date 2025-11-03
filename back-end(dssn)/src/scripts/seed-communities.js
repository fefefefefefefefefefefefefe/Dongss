import 'dotenv/config';
import { PrismaClient } from '@prisma/client';
const prisma = new PrismaClient();

const NAMES = ['홈피드', '자유게시판', '질문게시판', '정보공유'];

async function main() {
  for (const name of NAMES) {
    const c = await prisma.community.upsert({
      where: { name },
      update: {},
      create: { name, description: `${name}입니다`, is_private: false },
      select: { id: true, name: true },
    });
    console.log('community:', c);
  }
  console.log('✅ communities ready');
  await prisma.$disconnect();
}
main().catch(console.error);
