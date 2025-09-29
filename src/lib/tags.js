// 해시태그 파서

export function extractTags(text = '') {
  const m = text.match(/#([0-9A-Za-z가-힣_]{1,64})/g) || [];
  return [...new Set(m.map((s) => s.slice(1).toLowerCase()))];
}
