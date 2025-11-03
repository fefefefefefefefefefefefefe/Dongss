export const COMMUNITY_NAME_BY_KEY = {
  home: '홈피드',
  free: '자유게시판',
  qna: '질문게시판',
  info: '정보공유',
};

export async function resolveCommunityId(prisma, input) {
  if (input == null) return undefined;
  const n = Number(input);
  if (!Number.isNaN(n) && String(input).trim() === String(n)) return n;
  const name = COMMUNITY_NAME_BY_KEY[String(input)];
  if (!name) return undefined;
  const found = await prisma.community.findUnique({
    where: { name },
    select: { id: true },
  });
  return found?.id;
}
