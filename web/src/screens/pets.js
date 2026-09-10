// The collection: every animal in the world, discovered or still unknown.
import { el, row, card, button, text, pill, icon } from '../ui.js'
import { petNode } from '../art.js'
import { getSpecies, rescuableIds, npc as dataNpc } from '../data.js'

let selected = ''

export function PetsScreen({ go, game }) {
  const wrap = el('div', { class: 'screen page', id: 'pets-screen' })
  const all = rescuableIds()

  const tile = (id, isCompanion) => {
    const known = isCompanion || game.isRescued(id)
    const info = getSpecies(id)
    const node = card([
      el('div', { class: `tile ${known ? '' : 'locked'}` }, [
        petNode(id, 'art art-pet'),
        el('h3', { text: known ? info.name : '? ? ?' }),
        known
          ? pill(isCompanion ? 'Companion' : game.isHomed(id) ? 'Homed' : 'In sanctuary', 'sage')
          : pill('Not found yet'),
        known && button('Read', () => { selected = id; draw() }, 'soft', {}),
      ]),
    ], 'tight')
    node.id = `pet-${id}`
    return node
  }

  function detail() {
    if (!selected) {
      return card([el('h2', { text: 'Pick an animal' }),
        text('Silhouettes are animals still out in the world. Follow the map to meet them.')])
    }
    const info = getSpecies(selected)
    const entry = game.entry(selected)
    const children = [
      el('div', { class: 'tile' }, [petNode(selected, 'art art-pet'), el('h2', { text: info.name })]),
      pill(String(info.rarity ?? 'common'), 'sky'),
      text(info.bio),
      el('div', { class: 'row center', style: { flexWrap: 'wrap', gap: '5px' } },
        (info.traits ?? []).map((t) => el('span', { class: 'pill sage', text: t }))),
    ]
    if (selected === game.petSpecies()) {
      children.push(text('Your companion since day one.'))
    } else if (entry.rescued) {
      children.push(el('span', { class: 'muted', text: `Rescued on ${new Date(entry.rescued * 1000).toISOString().slice(0, 10)}` }))
      if (game.isHomed(selected)) {
        const friend = dataNpc(entry.friend)
        children.push(el('h3', { text: `Living with ${friend.name}` }), text(friend.blurb))
      } else {
        children.push(text(`Still in the sanctuary · trust ${game.trust(selected)}%`))
        children.push(button('Visit them', () => go('friends', { species: selected }), 'primary', {}))
      }
    }
    return card(children)
  }

  function draw() {
    wrap.replaceChildren(
      row([icon('cat'), el('h1', { text: 'Pets' }), el('div', { class: 'grow' }),
        pill(`${game.rescuedCount()} / ${all.length} rescued`, 'sage'),
        pill(`${game.homedCount()} homed`, 'pink')], 'head'),
      row([
        el('div', { class: 'scroll grow' }, [
          el('div', { class: 'grid c4' }, [tile(game.petSpecies(), true), ...all.map((id) => tile(id, false))]),
        ]),
        el('div', { style: { width: '330px', flex: 'none', alignSelf: 'flex-start' } }, [detail()]),
      ], 'grow'),
    )
  }

  draw()
  return { node: wrap, scene: 'room' }
}
