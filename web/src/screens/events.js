// Events: whoever is out there needing help right now.
import { el, row, card, button, text, pill, icon } from '../ui.js'
import { creatureNode } from '../art.js'
import { getSpecies } from '../data.js'

export function EventsScreen({ go, game }) {
  const chapter = game.currentChapter()
  const missions = game.availableMissions()
  const body = el('div', { class: 'col' })

  if (!chapter) {
    body.append(card([el('h2', { text: 'You have been everywhere' }),
      text('Every region is finished. Your library is the record of it.')]))
  } else {
    body.append(card([el('h2', { text: chapter.title }), text(chapter.intro)]))
    if (!missions.length) {
      body.append(card([
        el('h2', { text: 'Nobody is waiting out there' }),
        text('Everyone in this region is safe. Look after them in the sanctuary and the next region opens.'),
        button('Go to the sanctuary', () => go('friends'), 'primary', {}),
      ]))
    } else {
      body.append(el('div', { class: 'grid c3' }, missions.map((id) => {
        const info = getSpecies(id)
        return card([
          el('div', { class: 'tile' }, [
            creatureNode(id, 'peek'),
            el('h3', { text: info.name }),
            pill(String(info.rarity ?? 'common'), 'sage'),
            text(info.bio),
          ]),
          button('Go find them', () => go('rescue', { species: id }), 'primary', {}),
        ])
      })))
    }
  }

  return {
    node: el('div', { class: 'screen page', id: 'events-screen' }, [
      row([icon('sparkle'), el('h1', { text: 'Events' }), el('div', { class: 'grow' }),
        pill(`${game.homedCount()} homed · ${game.rescuedCount()} rescued`, 'sage')], 'head'),
      el('div', { class: 'scroll' }, [body]),
    ]),
    scene: chapter?.scene === 'mall' ? 'mall' : 'home',
  }
}
