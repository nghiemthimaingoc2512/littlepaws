// Missions: what the current chapter asks for, and every badge.
import { el, row, card, button, text, pill, icon, meter } from '../ui.js'
import { Data } from '../data.js'

export function MissionsScreen({ go, game }) {
  game.markSeen('missions')

  const chapter = game.currentChapter()
  const chapterCard = card(chapter ? [
    el('h2', { text: `Right now: ${chapter.title}` }),
    ...chapter.goals.map((goal) => {
      const done = game.goalDone(goal)
      const target = game.goalTarget(goal)
      const label = target > 1
        ? `${goal.text}   ${Math.min(game.goalProgress(goal), target)} / ${target}`
        : goal.text
      return row([icon(done ? 'check' : 'paw'), el('span', { text: label, style: { color: done ? 'var(--ink-soft)' : '' } })])
    }),
    button('Open the map', () => go('map'), 'soft', {}),
  ] : [
    el('h2', { text: 'Every chapter is finished' }),
    text('The world is yours to revisit whenever you like.'),
  ])

  const badgeCard = (badge) => {
    const earned = game.hasBadge(badge.id)
    const target = Math.max(1, badge.target ?? 1)
    const progress = Math.min(game.badgeProgress(badge), target)
    return el('div', { class: 'card', style: { background: earned ? '#fdf1d4' : '' } }, [
      row([icon('trophy'), el('h3', { text: badge.name }), el('div', { class: 'grow' }),
        pill(`+${badge.gems ?? 0}`, 'sky')]),
      text(badge.text),
      meter(earned ? 'Earned' : 'Progress', progress, target, earned ? '#f2c14e' : '#a8cc8c', { hideValue: true }),
      el('span', { class: 'muted', text: `${progress} / ${target}` }),
    ])
  }

  return {
    node: el('div', { class: 'screen page', id: 'missions-screen' }, [
      row([icon('trophy'), el('h1', { text: 'Missions' }), el('div', { class: 'grow' }),
        pill(`${game.badgesEarned()} / ${Data.badges.length} badges`, 'gold')], 'head'),
      el('div', { class: 'scroll' }, [
        el('div', { class: 'col' }, [
          chapterCard,
          el('h2', { text: 'Badges' }),
          el('div', { class: 'grid c3' }, Data.badges.map(badgeCard)),
        ]),
      ]),
    ]),
    scene: 'home',
  }
}
