// The one mini-game: Chase the Ribbon.
//
// Ribbons appear, you tap them, your cat glides over to each one. Forty
// seconds, or twelve catches for a perfect round. There is no way to lose.
import { el, card, button, text, icon } from '../ui.js'
import { petNode } from '../art.js'
import { MY_PET } from '../content.js'

const ROUND_SECONDS = 40
const PERFECT = 12

export function PlayScreen({ go, game }) {
  let caught = 0
  let remaining = ROUND_SECONDS
  let over = false
  let tick = null

  const field = el('div', { class: 'field', id: 'play-field' })
  const fill = el('div', { class: 'timer-fill', style: { width: '100%' } })
  const score = el('div', { class: 'score', id: 'score', text: `0 / ${PERFECT}` })
  const chaser = petNode(MY_PET, 'art pet-portrait chaser')
  chaser.style.left = '46%'
  chaser.style.top = '58%'

  // Ribbons take a free cell of a coarse grid, so two never land on top of
  // each other — overlapping ones look wrong and the lower one is unclickable.
  const COLS = 4
  const ROWS = 3
  const taken = new Set()

  function freeSlot() {
    const open = []
    for (let i = 0; i < COLS * ROWS; i += 1) if (!taken.has(i)) open.push(i)
    if (!open.length) return null
    return open[Math.floor(Math.random() * open.length)]
  }

  function spawn() {
    if (over) return
    const slot = freeSlot()
    if (slot === null) return
    taken.add(slot)
    const col = slot % COLS
    const rowIndex = Math.floor(slot / COLS)
    const ribbon = el('button', { class: 'ribbon', 'aria-label': 'ribbon' }, [icon('ribbon')])
    ribbon.dataset.slot = String(slot)
    ribbon.style.left = `${10 + col * 21 + Math.random() * 6}%`
    ribbon.style.top = `${24 + rowIndex * 20 + Math.random() * 6}%`
    ribbon.addEventListener('click', () => {
      if (over) return
      // The cat goes where the ribbon was: the point is watching her chase.
      chaser.style.left = ribbon.style.left
      chaser.style.top = ribbon.style.top
      taken.delete(Number(ribbon.dataset.slot))
      ribbon.remove()
      caught += 1
      score.textContent = `${Math.min(caught, PERFECT)} / ${PERFECT}`
      if (caught >= PERFECT) finish()
      else fillField()
    })
    field.append(ribbon)
  }

  const fillField = () => { while (!over && field.querySelectorAll('.ribbon').length < 3) spawn() }

  function finish() {
    if (over) return
    over = true
    clearInterval(tick)
    field.querySelectorAll('.ribbon').forEach((r) => r.remove())
    taken.clear()
    game.finishPlay()
    field.append(el('div', { class: 'veil', id: 'play-done' }, [
      el('div', { class: 'modal card' }, [
        petNode(MY_PET, 'art pet-portrait', ),
        el('h1', { text: `You played with ${game.petName()}!` }),
        text(caught >= PERFECT
          ? 'She caught every single ribbon. Worn out and very pleased with herself.'
          : `She chased down ${caught} ribbon${caught === 1 ? '' : 's'} and flopped over happy.`),
        text('There is a treat waiting for her at home.'),
        button('Back home', () => go('home'), 'btn-primary btn-big', { id: 'play-home' }),
      ]),
    ]))
  }

  tick = setInterval(() => {
    remaining -= 1
    fill.style.width = `${Math.max(0, (remaining / ROUND_SECONDS) * 100)}%`
    if (remaining <= 0) finish()
  }, 1000)

  field.append(chaser, el('div', { class: 'timer-bar' }, [fill]), score)
  fillField()

  return {
    node: el('div', { class: 'screen', id: 'play-screen' }, [field]),
    scene: 'room',
    keepOnChange: true,
    dispose() { over = true; clearInterval(tick) },
  }
}
