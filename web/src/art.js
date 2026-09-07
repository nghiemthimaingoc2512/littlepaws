// All character, pet and scene art.
//
// Art is image-first: if a PNG exists for a species or scene it is used, and
// the drawn SVG below is the fallback. Drop files into the repo's /assets
// folder (served at the site root) and they take over with no code change:
//   assets/pets/<species_id>.png      ->  /pets/ragdoll.png
//   assets/pets/<species_id>_<pose>.png
//   assets/owner/<pose>.png           ->  /owner/idle.png
//   assets/bg/<scene>.png             ->  /bg/home.png
import { getSpecies } from './data.js'

const EYE_COLOR = { ragdoll: '#4b86c4', snow_fox: '#6f9fd0', fennec: '#5b4636' }
const DEFAULT_EYE = '#4c3a2e'

/** A soft, organic blob outline — the base shape for every fluffy body. */
function fluff(cx, cy, rx, ry, bumps = 13, amp = 0.05, phase = 0) {
  const pts = []
  const n = bumps * 2
  for (let i = 0; i < n; i += 1) {
    const a = (i / n) * Math.PI * 2 + phase
    const k = 1 + (i % 2 === 0 ? amp : -amp)
    pts.push([cx + Math.cos(a) * rx * k, cy + Math.sin(a) * ry * k])
  }
  let d = ''
  for (let i = 0; i < pts.length; i += 1) {
    const cur = pts[i]
    const next = pts[(i + 1) % pts.length]
    const after = pts[(i + 2) % pts.length]
    const mid = [(cur[0] + next[0]) / 2, (cur[1] + next[1]) / 2]
    const mid2 = [(next[0] + after[0]) / 2, (next[1] + after[1]) / 2]
    if (i === 0) d += `M${mid[0].toFixed(1)} ${mid[1].toFixed(1)}`
    d += `Q${next[0].toFixed(1)} ${next[1].toFixed(1)} ${mid2[0].toFixed(1)} ${mid2[1].toFixed(1)}`
  }
  return `${d}Z`
}

const POSES = {
  idle: { eyes: 'open', mouth: 'smile' },
  happy: { eyes: 'closed', mouth: 'open' },
  loaf: { eyes: 'open', mouth: 'neutral', squash: 0.86 },
  curl: { eyes: 'sleep', mouth: 'neutral', squash: 0.82 },
  sleep: { eyes: 'sleep', mouth: 'neutral', squash: 0.84, prop: 'zzz' },
  eat: { eyes: 'open', mouth: 'open', prop: 'bowl' },
  play: { eyes: 'open', mouth: 'open', prop: 'yarn', lean: -7 },
  crown: { eyes: 'closed', mouth: 'smile', prop: 'crown' },
  curious: { eyes: 'open', mouth: 'neutral', lean: 8 },
  peek: { eyes: 'open', mouth: 'neutral', squash: 0.9 },
  wave: { eyes: 'closed', mouth: 'open', prop: 'wave' },
  dressed: { eyes: 'open', mouth: 'smile', prop: 'bow' },
  love: { eyes: 'closed', mouth: 'smile', prop: 'heart' },
}

function ears(kind, cx, cy, r, body, accent) {
  const inner = '#f0b3b8'
  switch (kind) {
    case 'Bunny':
      return `
        <ellipse cx="${cx - r * 0.42}" cy="${cy - r * 1.15}" rx="${r * 0.19}" ry="${r * 0.62}" fill="${body}" transform="rotate(-9 ${cx - r * 0.42} ${cy - r * 1.15})"/>
        <ellipse cx="${cx + r * 0.42}" cy="${cy - r * 1.15}" rx="${r * 0.19}" ry="${r * 0.62}" fill="${body}" transform="rotate(9 ${cx + r * 0.42} ${cy - r * 1.15})"/>
        <ellipse cx="${cx - r * 0.42}" cy="${cy - r * 1.15}" rx="${r * 0.09}" ry="${r * 0.44}" fill="${inner}" transform="rotate(-9 ${cx - r * 0.42} ${cy - r * 1.15})"/>
        <ellipse cx="${cx + r * 0.42}" cy="${cy - r * 1.15}" rx="${r * 0.09}" ry="${r * 0.44}" fill="${inner}" transform="rotate(9 ${cx + r * 0.42} ${cy - r * 1.15})"/>`
    case 'Dog':
      return `
        <ellipse cx="${cx - r * 0.92}" cy="${cy - r * 0.05}" rx="${r * 0.27}" ry="${r * 0.52}" fill="${accent}" transform="rotate(12 ${cx - r * 0.92} ${cy})"/>
        <ellipse cx="${cx + r * 0.92}" cy="${cy - r * 0.05}" rx="${r * 0.27}" ry="${r * 0.52}" fill="${accent}" transform="rotate(-12 ${cx + r * 0.92} ${cy})"/>`
    case 'Bird': case 'Duck': case 'Penguin':
      return `<path d="M${cx + r * 0.86} ${cy + r * 0.06} l${r * 0.42} ${r * 0.14} l${-r * 0.42} ${r * 0.2} Z" fill="#f0a94e"/>`
    case 'Hedgehog': {
      let spines = ''
      for (let i = 0; i < 11; i += 1) {
        const a = -Math.PI * 0.97 + (i / 10) * Math.PI * 0.94
        spines += `<path d="M${cx + Math.cos(a) * r * 0.96} ${cy + Math.sin(a) * r * 0.96} L${cx + Math.cos(a) * r * 1.3} ${cy + Math.sin(a) * r * 1.3}" stroke="${accent}" stroke-width="${r * 0.13}" stroke-linecap="round"/>`
      }
      return spines
    }
    case 'Fox':
      return `
        <path d="M${cx - r * 0.86} ${cy - r * 0.3} L${cx - r * 0.72} ${cy - r * 1.32} L${cx - r * 0.12} ${cy - r * 0.72} Z" fill="${accent}"/>
        <path d="M${cx + r * 0.86} ${cy - r * 0.3} L${cx + r * 0.72} ${cy - r * 1.32} L${cx + r * 0.12} ${cy - r * 0.72} Z" fill="${accent}"/>
        <path d="M${cx - r * 0.72} ${cy - r * 0.4} L${cx - r * 0.66} ${cy - r * 1.08} L${cx - r * 0.26} ${cy - r * 0.7} Z" fill="${inner}"/>
        <path d="M${cx + r * 0.72} ${cy - r * 0.4} L${cx + r * 0.66} ${cy - r * 1.08} L${cx + r * 0.26} ${cy - r * 0.7} Z" fill="${inner}"/>`
    default:
      return `
        <path d="M${cx - r * 0.82} ${cy - r * 0.34} L${cx - r * 0.66} ${cy - r * 1.18} L${cx - r * 0.1} ${cy - r * 0.74} Z" fill="${accent}"/>
        <path d="M${cx + r * 0.82} ${cy - r * 0.34} L${cx + r * 0.66} ${cy - r * 1.18} L${cx + r * 0.1} ${cy - r * 0.74} Z" fill="${accent}"/>
        <path d="M${cx - r * 0.7} ${cy - r * 0.44} L${cx - r * 0.6} ${cy - r * 0.98} L${cx - r * 0.24} ${cy - r * 0.72} Z" fill="${inner}"/>
        <path d="M${cx + r * 0.7} ${cy - r * 0.44} L${cx + r * 0.6} ${cy - r * 0.98} L${cx + r * 0.24} ${cy - r * 0.72} Z" fill="${inner}"/>`
  }
}

function eyeMarkup(style, x, y, r, color) {
  if (style === 'closed') {
    return `<path d="M${x - r} ${y + r * 0.2} q${r} ${-r * 1.1} ${r * 2} 0" stroke="#5b4636" stroke-width="${r * 0.42}" fill="none" stroke-linecap="round"/>`
  }
  if (style === 'sleep') {
    return `<path d="M${x - r} ${y} q${r} ${r * 0.85} ${r * 2} 0" stroke="#5b4636" stroke-width="${r * 0.4}" fill="none" stroke-linecap="round"/>`
  }
  return `
    <ellipse cx="${x}" cy="${y}" rx="${r * 0.92}" ry="${r * 1.12}" fill="#3b2c22"/>
    <ellipse cx="${x}" cy="${y + r * 0.1}" rx="${r * 0.72}" ry="${r * 0.9}" fill="${color}"/>
    <circle cx="${x - r * 0.26}" cy="${y - r * 0.36}" r="${r * 0.3}" fill="#fff"/>
    <circle cx="${x + r * 0.3}" cy="${y + r * 0.38}" r="${r * 0.16}" fill="#fff" opacity=".7"/>`
}

function props(kind, cx, cy, r) {
  switch (kind) {
    case 'zzz':
      return `<g fill="#a08265" opacity=".85" font-family="system-ui" font-weight="700">
        <text x="${cx + r * 1.15}" y="${cy - r * 0.95}" font-size="${r * 0.42}">z</text>
        <text x="${cx + r * 1.5}" y="${cy - r * 1.35}" font-size="${r * 0.56}">z</text></g>`
    case 'bowl':
      return `<g><ellipse cx="${cx}" cy="${cy + r * 2.15}" rx="${r * 0.62}" ry="${r * 0.2}" fill="#e8a86a"/>
        <path d="M${cx - r * 0.62} ${cy + r * 2.15} a${r * 0.62} ${r * 0.55} 0 0 0 ${r * 1.24} 0Z" fill="#c98a53"/></g>`
    case 'yarn':
      return `<g><circle cx="${cx + r * 1.5}" cy="${cy + r * 1.85}" r="${r * 0.42}" fill="#f0a3ac"/>
        <path d="M${cx + r * 1.15} ${cy + r * 1.7} q${r * 0.35} ${r * 0.4} ${r * 0.7} 0 M${cx + r * 1.2} ${cy + r * 2.05} q${r * 0.32} ${-r * 0.36} ${r * 0.62} 0" stroke="#d9808f" stroke-width="${r * 0.08}" fill="none"/></g>`
    case 'crown':
      return `<g>${[-0.5, -0.17, 0.17, 0.5].map((t) => `<circle cx="${cx + t * r * 1.25}" cy="${cy - r * 1.06 + Math.abs(t) * r * 0.28}" r="${r * 0.17}" fill="#fdf6e6" stroke="#f2c14e" stroke-width="${r * 0.05}"/>`).join('')}</g>`
    case 'heart':
      return `<path d="M${cx + r * 1.35} ${cy - r * 0.85} c${-r * 0.3} ${-r * 0.34} ${-r * 0.72} ${-r * 0.02} ${-r * 0.36} ${r * 0.32} l${r * 0.36} ${r * 0.34} l${r * 0.36} ${-r * 0.34} c${r * 0.36} ${-r * 0.34} ${-r * 0.06} ${-r * 0.66} ${-r * 0.36} ${-r * 0.32}Z" fill="#e8626f"/>`
    case 'bow':
      return `<g><ellipse cx="${cx - r * 0.86}" cy="${cy - r * 0.86}" rx="${r * 0.26}" ry="${r * 0.18}" fill="#f2a9b4"/>
        <ellipse cx="${cx - r * 0.42}" cy="${cy - r * 0.86}" rx="${r * 0.26}" ry="${r * 0.18}" fill="#f2a9b4"/>
        <circle cx="${cx - r * 0.64}" cy="${cy - r * 0.86}" r="${r * 0.11}" fill="#d9808f"/></g>`
    default:
      return ''
  }
}

/** The drawn fallback for one animal. */
export function creatureSvg(speciesId, pose = 'idle') {
  const info = getSpecies(speciesId)
  const kind = info.kind ?? 'Cat'
  const bodyColor = info.body ?? '#f6ece0'
  const accent = info.accent ?? '#a08d7e'
  const eye = EYE_COLOR[speciesId] ?? DEFAULT_EYE
  const p = { squash: 1, lean: 0, prop: '', ...(POSES[pose] ?? POSES.idle) }

  const cx = 120
  const baseY = 168
  const bodyRy = 46 * p.squash
  const bodyCy = baseY - bodyRy * 0.72
  const headR = 46
  const headCy = bodyCy - bodyRy * 0.78 - headR * 0.22
  const tailUp = kind === 'Fox' || kind === 'Cat'

  return `
<svg viewBox="0 0 240 240" xmlns="http://www.w3.org/2000/svg" class="creature-svg">
  <ellipse cx="${cx}" cy="${baseY + 8}" rx="62" ry="11" fill="#6b4a32" opacity=".10"/>
  <g transform="rotate(${p.lean} ${cx} ${baseY})">
    <path d="${fluff(cx + 44, bodyCy + 20, 30, tailUp ? 34 : 24, 10, 0.08, 0.7)}" fill="${accent}"/>
    <path d="${fluff(cx + 30, bodyCy + 30, 22, 18, 9, 0.07, 1.4)}" fill="${accent}"/>
    <path d="${fluff(cx, bodyCy, 58, bodyRy, 15, 0.045)}" fill="${bodyColor}"/>
    <ellipse cx="${cx - 22}" cy="${baseY - 8}" rx="15" ry="10" fill="${bodyColor}"/>
    <ellipse cx="${cx + 22}" cy="${baseY - 8}" rx="15" ry="10" fill="${bodyColor}"/>
    <ellipse cx="${cx - 22}" cy="${baseY - 6}" rx="7" ry="4.5" fill="#f0b3b8" opacity=".8"/>
    <ellipse cx="${cx + 22}" cy="${baseY - 6}" rx="7" ry="4.5" fill="#f0b3b8" opacity=".8"/>
    ${ears(kind, cx, headCy, headR, bodyColor, accent)}
    <path d="${fluff(cx, headCy, headR, headR * 0.94, 14, 0.04, 0.3)}" fill="${bodyColor}"/>
    <path d="M${cx - headR * 0.95} ${headCy - headR * 0.2} a${headR} ${headR * 0.9} 0 0 1 ${headR * 1.9} 0 a${headR} ${headR} 0 0 0 ${-headR * 1.9} 0Z" fill="${accent}" opacity=".28"/>
    ${eyeMarkup(p.eyes, cx - headR * 0.4, headCy + headR * 0.1, headR * 0.2, eye)}
    ${eyeMarkup(p.eyes, cx + headR * 0.4, headCy + headR * 0.1, headR * 0.2, eye)}
    <ellipse cx="${cx - headR * 0.76}" cy="${headCy + headR * 0.42}" rx="${headR * 0.19}" ry="${headR * 0.11}" fill="#f0a8b2" opacity=".75"/>
    <ellipse cx="${cx + headR * 0.76}" cy="${headCy + headR * 0.42}" rx="${headR * 0.19}" ry="${headR * 0.11}" fill="#f0a8b2" opacity=".75"/>
    <path d="M${cx - 5} ${headCy + headR * 0.4} h10 l-5 6Z" fill="#e08e98"/>
    ${p.mouth === 'open'
      ? `<path d="M${cx - 7} ${headCy + headR * 0.54} a7 6 0 0 0 14 0Z" fill="#d9808f"/>`
      : p.mouth === 'smile'
        ? `<path d="M${cx - 8} ${headCy + headR * 0.54} q4 4 8 0 M${cx} ${headCy + headR * 0.54} q4 4 8 0" stroke="#b98a86" stroke-width="2" fill="none" stroke-linecap="round"/>`
        : ''}
    ${props(p.prop, cx, headCy, headR)}
  </g>
</svg>`
}

/** The drawn fallback for the player character. */
export function ownerSvg(pose = 'idle') {
  const hair = '#5c4033'
  const hairLight = '#6f4e3d'
  const skin = '#fbe3d2'
  const sweater = '#f6ead6'
  const closed = pose === 'sleep' || pose === 'happy' || pose === 'wink'
  return `
<svg viewBox="0 0 240 240" xmlns="http://www.w3.org/2000/svg" class="creature-svg">
  <ellipse cx="120" cy="212" rx="58" ry="10" fill="#6b4a32" opacity=".10"/>
  <path d="${fluff(120, 96, 74, 72, 16, 0.055)}" fill="${hair}"/>
  <path d="${fluff(88, 44, 30, 27, 11, 0.09, 0.4)}" fill="${hairLight}"/>
  <g>
    <ellipse cx="70" cy="44" rx="13" ry="9" fill="#f2a9b4" transform="rotate(-18 70 44)"/>
    <ellipse cx="94" cy="40" rx="13" ry="9" fill="#f2a9b4" transform="rotate(18 94 40)"/>
    <circle cx="82" cy="43" r="5.5" fill="#e0919e"/>
  </g>
  <path d="${fluff(120, 206, 66, 46, 13, 0.03)}" fill="${sweater}"/>
  <ellipse cx="64" cy="204" rx="18" ry="22" fill="${sweater}"/>
  <ellipse cx="176" cy="204" rx="18" ry="22" fill="${sweater}"/>
  <path d="${fluff(120, 112, 56, 54, 14, 0.028)}" fill="${skin}"/>
  <path d="M64 96 a56 52 0 0 1 112 0 a56 34 0 0 0 -112 0Z" fill="${hair}"/>
  <path d="M64 98 q22 26 4 46 q-16 -22 -4 -46Z" fill="${hair}"/>
  <path d="M176 98 q-22 26 -4 46 q16 -22 4 -46Z" fill="${hair}"/>
  ${closed
    ? `<path d="M92 116 q10 -11 20 0M128 116 q10 -11 20 0" stroke="#3b2c22" stroke-width="4" fill="none" stroke-linecap="round"/>`
    : `<ellipse cx="102" cy="118" rx="8.5" ry="10.5" fill="#3b2c22"/>
       <ellipse cx="138" cy="118" rx="8.5" ry="10.5" fill="#3b2c22"/>
       <circle cx="99" cy="114" r="3.2" fill="#fff"/><circle cx="135" cy="114" r="3.2" fill="#fff"/>`}
  <ellipse cx="86" cy="134" rx="10" ry="6" fill="#f2a0aa" opacity=".7"/>
  <ellipse cx="154" cy="134" rx="10" ry="6" fill="#f2a0aa" opacity=".7"/>
  <path d="M112 136 q8 8 16 0" stroke="#c98a86" stroke-width="3" fill="none" stroke-linecap="round"/>
</svg>`
}

/** The room behind the home screen. Replaced by /bg/home.png when present. */
export function roomSvg() {
  return `
<svg viewBox="0 0 1280 720" preserveAspectRatio="xMidYMid slice" xmlns="http://www.w3.org/2000/svg" class="room-svg">
  <rect width="1280" height="720" fill="#f7e9d7"/>
  <rect y="430" width="1280" height="290" fill="#e9d4b0"/>
  <g opacity=".5" stroke="#d9c096" stroke-width="2">
    <path d="M0 500h1280M0 570h1280M0 645h1280"/>
  </g>
  <g>
    <rect x="812" y="82" width="286" height="330" rx="14" fill="#fffdf7"/>
    <rect x="826" y="96" width="258" height="302" rx="8" fill="#d5e8f7"/>
    <circle cx="1010" cy="168" r="40" fill="#fffdf7" opacity=".85"/>
    <circle cx="960" cy="192" r="26" fill="#fffdf7" opacity=".7"/>
    <rect x="950" y="96" width="8" height="302" fill="#fffdf7"/>
    <rect x="826" y="250" width="258" height="8" fill="#fffdf7"/>
    <rect x="800" y="404" width="310" height="14" rx="6" fill="#dcc39c"/>
  </g>
  <g>
    <rect x="406" y="418" width="126" height="26" rx="12" fill="#e0c69f"/>
    <rect x="452" y="212" width="34" height="212" rx="10" fill="#dcc196"/>
    <rect x="396" y="196" width="146" height="28" rx="13" fill="#e9d3ae"/>
    <rect x="416" y="300" width="106" height="24" rx="11" fill="#e4cba4"/>
    <circle cx="540" cy="352" r="15" fill="#f0b9bf"/>
    <path d="M540 337v-40" stroke="#e0c69f" stroke-width="4"/>
  </g>
  <g>
    <rect x="96" y="300" width="300" height="132" rx="30" fill="#a8cc8c"/>
    <rect x="112" y="352" width="268" height="86" rx="26" fill="#bcd9a2"/>
    <rect x="88" y="330" width="40" height="106" rx="20" fill="#9cc27e"/>
    <rect x="364" y="330" width="40" height="106" rx="20" fill="#9cc27e"/>
    <rect x="188" y="322" width="70" height="46" rx="16" fill="#fbf0d8" transform="rotate(-8 223 345)"/>
  </g>
  <g>
    <ellipse cx="640" cy="566" rx="228" ry="72" fill="#f2e4c8"/>
    <ellipse cx="640" cy="566" rx="176" ry="53" fill="#e7ddbe" opacity=".7"/>
  </g>
  <g>
    <ellipse cx="1176" cy="470" rx="52" ry="20" fill="#dcc39c"/>
    <path d="M1176 470c-46-14-64-70-40-104 18 34 62 30 74-6 26 40 8 96-34 110Z" fill="#8fb877"/>
    <path d="M1176 470c-20-40 0-92 26-112" stroke="#7aa563" stroke-width="6" fill="none"/>
  </g>
  <g opacity=".95">
    <rect x="150" y="112" width="152" height="118" rx="12" fill="#fffdf7"/>
    <rect x="164" y="126" width="124" height="90" rx="7" fill="#f3e6cf"/>
    <circle cx="226" cy="162" r="19" fill="#f6d9a8"/>
    <path d="M186 216c6-30 20-46 40-46s34 16 40 46Z" fill="#bcd9a2"/>
    <path d="M226 216v-34" stroke="#9cc27e" stroke-width="4" stroke-linecap="round"/>
  </g>
</svg>`
}

// --- image-first loading ---------------------------------------------------

const imageOk = new Map()

function probe(url) {
  if (imageOk.has(url)) return imageOk.get(url)
  const promise = new Promise((resolve) => {
    const img = new Image()
    img.onload = () => resolve(true)
    img.onerror = () => resolve(false)
    img.src = url
  })
  imageOk.set(url, promise)
  return promise
}

/**
 * Builds an art node. Renders the drawn SVG immediately, then swaps in a real
 * image if one exists at any of `urls`, so art can be added without code edits.
 */
function artNode(svgMarkup, urls, className) {
  const node = document.createElement('div')
  node.className = className
  node.innerHTML = svgMarkup
  ;(async () => {
    for (const url of urls) {
      if (await probe(url)) {
        node.innerHTML = `<img src="${url}" alt="" draggable="false" />`
        return
      }
    }
  })()
  return node
}

export function creatureNode(speciesId, pose = 'idle', className = 'creature') {
  return artNode(creatureSvg(speciesId, pose),
    [`/pets/${speciesId}_${pose}.png`, `/pets/${speciesId}.png`], className)
}

export function ownerNode(pose = 'idle', className = 'creature') {
  return artNode(ownerSvg(pose), [`/owner/${pose}.png`, `/owner/portrait.png`], className)
}

export function roomNode(scene = 'home', className = 'room') {
  return artNode(roomSvg(), [`/bg/${scene}.png`], className)
}
