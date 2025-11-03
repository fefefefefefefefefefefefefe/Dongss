// src/lib/tags.js
// 해시태그 파서 (다국어 지원, 1~64글자)
export function extractTags(text = '') {
  const m = String(text).match(/#[\p{L}\p{N}_-]{1,64}/gu) || [];
  // 소문자 통일 + 중복제거 + 앞의 # 제거
  return [...new Set(m.map((s) => s.slice(1).toLowerCase()))];
}
