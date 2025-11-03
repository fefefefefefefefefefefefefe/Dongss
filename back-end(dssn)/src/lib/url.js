export function toAbsoluteUrl(pathOrUrl) {
  if (!pathOrUrl) return null;
  // 이미 절대 URL이면 그대로
  if (/^https?:\/\//i.test(pathOrUrl)) return pathOrUrl;
  const base = process.env.PUBLIC_BASE_URL;
  if (!base) return pathOrUrl; // fallback: 상대경로 유지
  return `${base.replace(/\/+$/, '')}${
    pathOrUrl.startsWith('/') ? '' : '/'
  }${pathOrUrl}`;
}
