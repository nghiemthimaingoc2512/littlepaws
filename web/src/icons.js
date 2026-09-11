// Six icons. Anything that can be a word instead of an icon is a word.
const svg = (body) =>
  `<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" aria-hidden="true">${body}</svg>`
const S = 'stroke="currentColor" stroke-width="2.1" stroke-linecap="round" stroke-linejoin="round"'
const F = 'fill="currentColor"'

export const ICONS = {
  cat: svg(`<path d="M5 9.4 5.6 4l4 3M19 9.4 18.4 4l-4 3" ${S}/><path d="M12 6.4c4 0 7 3 7 6.6s-3 6.6-7 6.6-7-3-7-6.6 3-6.6 7-6.6Z" ${S}/><circle cx="9.5" cy="12.4" r="1.1" ${F}/><circle cx="14.5" cy="12.4" r="1.1" ${F}/>`),
  book: svg(`<path d="M4 4.6h6a3 3 0 0 1 3 3V20a2.6 2.6 0 0 0-2.6-2.6H4z" ${S}/><path d="M20 4.6h-6a3 3 0 0 0-3 3V20a2.6 2.6 0 0 1 2.6-2.6H20z" ${S}/>`),
  back: svg(`<path d="M14.6 5.4 8 12l6.6 6.6" ${S}/>`),
  heart: svg(`<path d="M12 20.4S3.6 15.3 3.6 9.7A4.3 4.3 0 0 1 12 7.6a4.3 4.3 0 0 1 8.4 2.1c0 5.6-8.4 10.7-8.4 10.7Z" ${F}/>`),
  paw: svg(`<ellipse cx="12" cy="16.1" rx="4.6" ry="3.8" ${F}/><ellipse cx="6.3" cy="10.5" rx="2.1" ry="2.6" ${F}/><ellipse cx="10" cy="7.4" rx="2.1" ry="2.6" ${F}/><ellipse cx="14" cy="7.4" rx="2.1" ry="2.6" ${F}/><ellipse cx="17.7" cy="10.5" rx="2.1" ry="2.6" ${F}/>`),
  ribbon: svg(`<path d="M12 13.4 5.2 6.6a3.4 3.4 0 0 1 4.8-4.8L12 3.8l2-2a3.4 3.4 0 0 1 4.8 4.8z" ${F}/><path d="M12 13.4v8M8.6 21.4h6.8" ${S}/>`),
}

export function icon(name) {
  const node = document.createElement('i')
  node.className = 'icon'
  node.innerHTML = ICONS[name] ?? ICONS.paw
  return node
}
