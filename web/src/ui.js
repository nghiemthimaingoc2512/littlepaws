// Tiny DOM helpers. No framework: screens build their tree and are rebuilt
// whenever the save changes, so state and view cannot drift apart.
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
export const grow = () => el('div', { class: 'grow' })
export const text = (value, cls = 'muted') => el('p', { class: cls, text: value })
export const pill = (label, cls = '') => el('span', { class: `pill ${cls}`.trim() }, [label])

export function button(label, onClick, cls = '', opts = {}) {
  const node = el('button', { class: cls, onClick, disabled: opts.disabled })
  if (opts.icon) node.append(icon(opts.icon))
  node.append(document.createTextNode(label))
  return node
}

export function iconButton(name, onClick, cls = 'round-btn', badge = 0) {
  const node = el('button', { class: cls, onClick, 'aria-label': name }, [icon(name)])
  if (badge > 0) node.append(el('span', { class: 'dot', text: String(badge) }))
  else if (badge < 0) node.append(el('span', { class: 'dot', text: '' }))
  return node
}

/** A labelled meter. Returns the element with a `set(value)` method. */
export function meter(label, value, max, color, opts = {}) {
  const fill = el('div', { class: 'meter-fill', style: { background: color } })
  const amount = el('span', { text: opts.hideValue ? '' : String(Math.round(value)) })
  const node = el('div', { class: 'meter' }, [
    el('div', { class: 'meter-top' }, [el('span', { text: label }), amount]),
    el('div', { class: 'meter-track' }, [fill]),
  ])
  node.set = (next) => {
    fill.style.width = `${Math.max(0, Math.min(1, next / max)) * 100}%`
    if (!opts.hideValue) amount.textContent = String(Math.round(next))
  }
  node.set(value)
  return node
}

export { icon }
