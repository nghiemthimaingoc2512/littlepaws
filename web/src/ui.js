// Small DOM helpers. No framework: a screen builds its tree, and is rebuilt
// when the save changes.
import { icon } from './icons.js'

export function el(tag, props = {}, children = []) {
  const node = document.createElement(tag)
  for (const [key, value] of Object.entries(props)) {
    if (value === undefined || value === null || value === false) continue
    if (key === 'class') node.className = value
    else if (key === 'text') node.textContent = value
    else if (key === 'html') node.innerHTML = value
    else if (key === 'onClick') node.addEventListener('click', value)
    else if (key === 'style') Object.assign(node.style, value)
    else if (key === 'disabled') node.disabled = !!value
    else node.setAttribute(key, value)
  }
  for (const child of [].concat(children)) {
    if (child === null || child === undefined || child === false) continue
    node.append(typeof child === 'string' ? document.createTextNode(child) : child)
  }
  return node
}

export const row = (children, cls = '') => el('div', { class: `row ${cls}`.trim() }, children)
export const col = (children, cls = '') => el('div', { class: `col ${cls}`.trim() }, children)
export const card = (children, cls = '') => el('div', { class: `card ${cls}`.trim() }, children)
export const text = (value) => el('p', { text: value })

export function button(label, onClick, cls = '', opts = {}) {
  const node = el('button', { class: cls, onClick, disabled: opts.disabled })
  if (opts.icon) node.append(icon(opts.icon))
  if (label) node.append(document.createTextNode(label))
  if (opts.id) node.id = opts.id
  if (opts.label) node.setAttribute('aria-label', opts.label)
  return node
}

export const roundButton = (iconName, onClick, opts = {}) =>
  button('', onClick, 'btn-round', { icon: iconName, ...opts })

export { icon }
