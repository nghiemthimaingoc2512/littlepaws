// Inline SVG icons. Kept deliberately few and simple: the references are not
// icon-heavy, so these exist only where a label alone would be slower to read.
const svg = (body, box = 24) =>
  `<svg viewBox="0 0 ${box} ${box}" fill="none" xmlns="http://www.w3.org/2000/svg" aria-hidden="true">${body}</svg>`

const S = 'stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"'
const F = 'fill="currentColor"'

export const ICONS = {
  home: svg(`<path d="M3.6 10.4 12 3.8l8.4 6.6V19a1.6 1.6 0 0 1-1.6 1.6h-3.4v-5.2H8.6v5.2H5.2A1.6 1.6 0 0 1 3.6 19z" ${S}/>`),
  cat: svg(`<path d="M5 9.4 5.6 4l4 3M19 9.4 18.4 4l-4 3" ${S}/><path d="M12 6.4c4 0 7 3 7 6.6s-3 6.6-7 6.6-7-3-7-6.6 3-6.6 7-6.6Z" ${S}/><circle cx="9.5" cy="12.4" r="1" ${F}/><circle cx="14.5" cy="12.4" r="1" ${F}/><path d="M10.6 15.6c.5.5 2.3.5 2.8 0" ${S}/>`),
  friends: svg(`<path d="M8.5 20c-2.8 0-5-2-5-4.6 0-2.7 2.2-4.8 5-4.8s5 2.1 5 4.8C13.5 18 11.3 20 8.5 20Z" ${S}/><path d="M15.5 16.4c2.6-.3 4.6-2.2 4.6-4.6 0-2.6-2.2-4.7-5-4.7-1.2 0-2.3.4-3.2 1" ${S}/><circle cx="6.9" cy="15" r=".9" ${F}/><circle cx="10.1" cy="15" r=".9" ${F}/>`),
  map: svg(`<path d="M12 21s6.4-5.6 6.4-10A6.4 6.4 0 0 0 5.6 11c0 4.4 6.4 10 6.4 10Z" ${S}/><circle cx="12" cy="10.6" r="2.4" ${S}/>`),
  bag: svg(`<path d="M8.4 8.4V6.8a3.6 3.6 0 0 1 7.2 0v1.6" ${S}/><rect x="4" y="8.4" width="16" height="11.6" rx="3" ${S}/><path d="M4 13h16" ${S}/>`),
  shop: svg(`<path d="M4 9.6 5.4 5h13.2L20 9.6" ${S}/><path d="M4 9.6a2.4 2.4 0 0 0 4 1.6 2.4 2.4 0 0 0 4 0 2.4 2.4 0 0 0 4 0 2.4 2.4 0 0 0 4-1.6" ${S}/><path d="M5.6 11.6V19h12.8v-7.4" ${S}/><rect x="9.8" y="14.4" width="4.4" height="4.6" rx="1" ${S}/>`),
  mail: svg(`<rect x="3" y="5.4" width="18" height="13.2" rx="2.6" ${S}/><path d="m3.8 7 7.1 5.3a2 2 0 0 0 2.2 0L20.2 7" ${S}/>`),
  camera: svg(`<path d="M4.6 7.8h2.9l1.3-2h6.4l1.3 2h2.9A2 2 0 0 1 21.4 10v7.4a2 2 0 0 1-2 2H4.6a2 2 0 0 1-2-2V9.8a2 2 0 0 1 2-2Z" ${S}/><circle cx="12" cy="13.6" r="3.4" ${S}/>`),
  gear: svg(`<circle cx="12" cy="12" r="3.1" ${S}/><path d="M12 2.8v2.4M12 18.8v2.4M21.2 12h-2.4M5.2 12H2.8M18.5 5.5 16.8 7.2M7.2 16.8l-1.7 1.7M18.5 18.5l-1.7-1.7M7.2 7.2 5.5 5.5" ${S}/>`),
  calendar: svg(`<rect x="3.4" y="5.2" width="17.2" height="15.4" rx="2.6" ${S}/><path d="M3.4 10h17.2M8 3.4v3.4M16 3.4v3.4" ${S}/><circle cx="8.4" cy="14" r="1" ${F}/><circle cx="12" cy="14" r="1" ${F}/><circle cx="15.6" cy="14" r="1" ${F}/>`),
  trophy: svg(`<path d="M7 4.4h10v5a5 5 0 0 1-10 0z" ${S}/><path d="M7 6H4.6v1.4A3.4 3.4 0 0 0 7 10.6M17 6h2.4v1.4a3.4 3.4 0 0 1-2.4 3.2" ${S}/><path d="M12 14.4v3.2M8.6 20.2h6.8" ${S}/>`),
  sparkle: svg(`<path d="M12 3.2 13.7 9l5.8 1.7-5.8 1.7L12 18.2l-1.7-5.8L4.5 10.7 10.3 9z" ${S}/>`),
  coin: svg(`<circle cx="12" cy="12" r="8.6" fill="#f6cf5e" stroke="#d9a83a" stroke-width="1.6"/><ellipse cx="12" cy="13.4" rx="2.7" ry="2.3" fill="#d9a83a" opacity=".55"/><ellipse cx="9.1" cy="10" rx="1.1" ry="1.4" fill="#d9a83a" opacity=".55"/><ellipse cx="12" cy="8.9" rx="1.1" ry="1.4" fill="#d9a83a" opacity=".55"/><ellipse cx="14.9" cy="10" rx="1.1" ry="1.4" fill="#d9a83a" opacity=".55"/>`),
  gem: svg(`<path d="M12 3.4 20 9.2 12 20.6 4 9.2z" fill="#7fb2e5"/><path d="M12 3.4 20 9.2H4z" fill="#a6cdf0"/><path d="M12 3.4 4 9.2h8z" fill="#c6e0f7"/>`),
  heart: svg(`<path d="M12 20.4S3.6 15.3 3.6 9.7A4.3 4.3 0 0 1 12 7.6a4.3 4.3 0 0 1 8.4 2.1c0 5.6-8.4 10.7-8.4 10.7Z" fill="#e8626f"/>`),
  paw: svg(`<ellipse cx="12" cy="16.1" rx="4.5" ry="3.7" ${F}/><ellipse cx="6.4" cy="10.6" rx="2" ry="2.5" ${F}/><ellipse cx="10" cy="7.6" rx="2" ry="2.5" ${F}/><ellipse cx="14" cy="7.6" rx="2" ry="2.5" ${F}/><ellipse cx="17.6" cy="10.6" rx="2" ry="2.5" ${F}/>`),
  plus: svg(`<path d="M12 5.6v12.8M5.6 12h12.8" stroke="currentColor" stroke-width="2.6" stroke-linecap="round"/>`),
  check: svg(`<path d="m5 12.6 4.6 4.6L19 7.4" stroke="currentColor" stroke-width="2.8" stroke-linecap="round" stroke-linejoin="round"/>`),
  close: svg(`<path d="M6.4 6.4 17.6 17.6M17.6 6.4 6.4 17.6" stroke="currentColor" stroke-width="2.4" stroke-linecap="round"/>`),
  back: svg(`<path d="M14.4 5.6 8 12l6.4 6.4" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"/>`),
  bowl: svg(`<ellipse cx="12" cy="9.4" rx="6.4" ry="2.6" fill="#f0a86a"/><path d="M4.6 9.6a7.4 7.4 0 0 0 14.8 0v.6c0 4-3.3 7.2-7.4 7.2s-7.4-3.2-7.4-7.2z" fill="currentColor"/>`),
  drop: svg(`<path d="M12 3.4c3.6 4.3 6 7.3 6 9.9a6 6 0 1 1-12 0c0-2.6 2.4-5.6 6-9.9Z" fill="#8fc7e8"/>`),
  moon: svg(`<path d="M20 14.4A8.4 8.4 0 0 1 9.6 4 8.6 8.6 0 1 0 20 14.4Z" fill="#a8c4e4"/>`),
}

/** Returns an <i class="icon"> element wrapping the named icon. */
export function icon(name, className = '') {
  const node = document.createElement('i')
  node.className = `icon ${className}`.trim()
  node.innerHTML = ICONS[name] ?? ICONS.paw
  return node
}
