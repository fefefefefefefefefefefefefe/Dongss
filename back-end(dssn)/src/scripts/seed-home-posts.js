// src/scripts/seed-home-posts.js
import 'dotenv/config';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

// 생성 개수 조절 (기본 50개) — 필요하면 CLI 인자로도 받음
const COUNT = Number(process.argv[2] || 50);

// 홈 커뮤니티 찾기 (이름이 '홈피드'여야 함)
async function getHomeCommunityId() {
  const c = await prisma.community.findUnique({
    where: { name: '홈피드' },
    select: { id: true },
  });
  if (!c)
    throw new Error(
      '홈피드 커뮤니티가 없습니다. 먼저 seed-communities를 실행하세요.'
    );
  return c.id;
}

// 랜덤 유저 하나 고르기
async function pickRandomUserId() {
  const [minMax] = await prisma.$queryRawUnsafe(`
    SELECT MIN(id) AS minId, MAX(id) AS maxId FROM user
  `);
  if (!minMax?.minId)
    throw new Error('유저가 없습니다. 먼저 seed-users를 실행하세요.');
  // 랜덤 시도 최대 10번 (중간에 삭제된 id가 있을 수 있으니)
  for (let i = 0; i < 10; i++) {
    const randId =
      Math.floor(Math.random() * (minMax.maxId - minMax.minId + 1)) +
      minMax.minId;
    const u = await prisma.user.findUnique({
      where: { id: randId },
      select: { id: true },
    });
    if (u) return u.id;
  }
  // 최후: 아무 유저 하나
  const any = await prisma.user.findFirst({ select: { id: true } });
  return any.id;
}

function makeTitle(i) {
  const titles = [
    '강아지 사진',
    '캠퍼스 풍경',
    '오늘의 점심',
    '스터디 인증',
    '과제 도움',
    '정보 공유',
  ];
  return `${titles[i % titles.length]} #${i}`;
}

function makeContent(i) {
  const tags = [
    '#동서울',
    '#홈',
    '#테스트',
    '#랜덤',
    '#학과',
    '#사진',
    '#하루기록',
  ];
  return `자동 생성된 홈 게시글 ${i}. ${tags[i % tags.length]} ${
    tags[(i + 2) % tags.length]
  }`;
}

function img(i) {
  // picsum 랜덤 이미지
  return `https://picsum.photos/seed/dsu-home-${i}/600/600`;
}

async function main() {
  const homeId = await getHomeCommunityId();
  console.log(`홈 커뮤니티 ID: ${homeId}`);
  const createdIds = [];

  // 트랜잭션 없이 배치로 빠르게 생성
  for (let i = 1; i <= COUNT; i++) {
    const userId = await pickRandomUserId();
    const title = makeTitle(i);
    const content = makeContent(i);
    const post = await prisma.post.create({
      data: {
        user_id: userId,
        community_id: homeId, // 홈피드 고정
        title,
        content,
      },
      select: { id: true },
    });

    await prisma.post_file.createMany({
      data: [
        { post_id: post.id, file_url: img(i), is_thumbnail: true },
        { post_id: post.id, file_url: img(i + 1000), is_thumbnail: false },
      ],
    });

    // 간단 태그 2개 연결 (중복 연결 에러는 무시)
    for (const name of ['홈', '테스트']) {
      const tag = await prisma.tag.upsert({
        where: { name },
        update: {},
        create: { name },
      });
      await prisma.post_tag
        .create({ data: { post_id: post.id, tag_id: tag.id } })
        .catch(() => {});
    }

    createdIds.push(post.id);
    if (i % 10 === 0) console.log(`... ${i}/${COUNT} 생성`);
  }

  console.log(`✅ 홈 게시글 ${createdIds.length}개 생성 완료`);
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
