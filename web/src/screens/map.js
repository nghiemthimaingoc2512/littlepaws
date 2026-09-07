// The chapter map: care chapters first, then the rescue regions.
import { el, row, card, button, text, pill, icon } from '../ui.js'
import { Data } from '../data.js'

export function MapScreen({ go, game }) {
  const chapterCard = (chapter, index) => {
    const cleared = game.chapterCleared(chapter.id)
    const active = index === game.chapterIndex()
    const locked = index > game.chapterIndex()

    const node = card([
      row([
        el('h2', { text: `${index + 1}. ${chapter.title}` }),
        el('div', { class: 'grow' }),
        pill(cleared ? 'Complete' : locked ? 'Locked' : 'In progress', cleared ? 'sage' : locked ? '' : 'pink'),
      ]),
      locked ? text(`Finish chapter ${game.chapterIndex() + 1} to open this.`) : text(chapter.intro),
      ...(locked ? [] : chapter.goals.map((goal) => {
        const done = game.goalDone(goal)
        const target = game.goalTarget(goal)
        const label = target > 1
          ? `${goal.text}   ${Math.min(game.goalProgress(goal), target)} / ${target}`
          : goal.text
        return row([
          icon(done ? 'check' : 'paw'),
          el('span', { class: 'grow', text: label, style: { color: done ? 'var(--ink-soft)' : '' } }),
          goal.type === 'rescue' && !done && active
            && button('Go find them', () => go('rescue', { species: goal.key }), 'primary', {}),
          goal.type === 'homed' && !done && active
            && button('Sanctuary', () => go('friends'), 'soft', {}),
        ])
      })),
    ])
    if (cleared) node.style.background = '#eef6e6'
    if (locked) node.style.opacity = '.72'
    return node
  }

  return {
    node: el('div', { class: 'screen page', id: 'map-screen' }, [
      row([icon('map'), el('h1', { text: 'Map' }), el('div', { class: 'grow' }),
        pill(`${game.chaptersDone()} / ${Data.chapters.length} chapters`, 'sage')], 'head'),
      el('div', { class: 'scroll' }, [el('div', { class: 'col' }, Data.chapters.map(chapterCard))]),
    ]),
    scene: 'mall',
  }
}
