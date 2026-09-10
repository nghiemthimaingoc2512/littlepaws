// A casual tap game. One engine, three flavours (see ACTIVITIES in state.js).
//
// There is no timer and no way to lose: targets keep appearing until you have
// tapped enough of them, and leaving early costs nothing.
import { el, row, card, button, text, icon, meter } from '../ui.js'
import { ownerNode } from '../art.js'
import { ACTIVITIES } from '../state.js'

const TARGET_CLASS = { drop: 'bubble-target', bowl: 'treat-target', paw: 'treat-target' }

export function MinigameScreen({ go, args, game }) {
  const id = args.activity && ACTIVITIES[args.activity] ? args.activity : 'bath'
  const activity = ACTIVITIES[id]
  let scored = 0
  let done = false
  const timers = new Set()

  const wrap = el('div', { class: 'screen page', id: 'minigame-screen' })
  const field = el('div', { class: 'play-field', id: 'play-field' })
  const progress = meter('Progress', 0, activity.targets, '#a8cc8c', { hideValue: true })
  const tally = el('b', { text: `0 / ${activity.targets}` })

  function spawn() {
    if (done) return
    const size = 54 + Math.random() * 34
    const node = el('button', {
      class: `target ${TARGET_CLASS[activity.icon] ?? ''}`,
      'aria-label': activity.label,
      style: {
        width: `${size}px`, height: `${size}px`,
        left: `${6 + Math.random() * 82}%`, top: `${8 + Math.random() * 70}%`,
      },
    }, [icon(activity.icon)])
    node.addEventListener('click', () => {
      if (done) return
      node.remove()
      scored += 1
      progress.set(scored)
      tally.textContent = `${scored} / ${activity.targets}`
      if (scored >= activity.targets) finish()
      else top_up()
    })
    field.append(node)
  }

  /** Keeps three things on screen to reach for, so there is never dead time. */
  function top_up() {
    while (!done && field.childElementCount < 3) spawn()
  }

  function finish() {
    done = true
    field.replaceChildren(el('div', { class: 'onboard' }, [
      card([
        ownerNode('cheer', 'art'),
        el('h1', { text: 'All done!' }),
        text(`${game.petName()} loved that.`),
      ], 'onboard-card'),
    ]))
    game.finishActivity(id)
  }

  function draw() {
    wrap.replaceChildren(
      row([
        button('', () => go('activities'), 'round-btn', { icon: 'back' }),
        icon(activity.icon), el('h1', { text: activity.label }),
        el('div', { class: 'grow' }),
        el('div', { class: 'play-hud' }, [progress, tally]),
      ], 'head'),
      field,
    )
    field.replaceChildren()
    scored = 0
    done = false
    progress.set(0)
    top_up()
  }

  draw()
  return {
    node: wrap,
    scene: activity.scene,
    // Finishing pays out, which rebuilds the screen; keep the result on screen.
    keepOnChange: true,
    dispose() { timers.forEach(clearTimeout) },
  }
}
