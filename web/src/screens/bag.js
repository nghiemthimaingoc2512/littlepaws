// The bag: what you are carrying and what you own.
import { el, row, card, button, text, pill, icon } from '../ui.js'
import { Data, item as dataItem } from '../data.js'

const SECTIONS = [
  { category: 'food', title: 'Pantry' },
  { category: 'outfit', title: 'Your outfits' },
  { category: 'accessory', title: 'Pet accessories' },
  { category: 'decor', title: 'Room decor' },
]

export function BagScreen({ go, game }) {
  const tile = (category, id) => {
    const entry = dataItem(category, id)
    const equipped = category !== 'food' && game.equipped(category) === id
    const node = card([
      el('div', { class: 'swatch', style: { background: entry.color ?? entry.sky ?? '#f6ead9' } }),
      el('h3', { text: entry.name, style: { textAlign: 'center' } }),
      category === 'food'
        ? pill(`x${game.save.inventory[id] ?? 0}`)
        : equipped
          ? pill('in use', 'gold')
          : button('Use', () => game.equip(id), 'soft', {}),
    ], 'tight')
    node.style.background = equipped ? '#fbe9b8' : 'var(--cream)'
    return node
  }

  const section = ({ category, title }) => {
    const group = Data.items[category] ?? {}
    const ids = Object.keys(group).filter((id) => (
      category === 'food' ? (game.save.inventory[id] ?? 0) > 0 : game.owns(id)))
    return card([
      el('h2', { text: title }),
      ids.length
        ? el('div', { class: 'grid c5' }, ids.map((id) => tile(category, id)))
        : text('Nothing here yet. The shop has some.'),
    ])
  }

  return {
    node: el('div', { class: 'screen page', id: 'bag-screen' }, [
      row([icon('bag'), el('h1', { text: 'Bag' }), el('div', { class: 'grow' }),
        pill(`${game.foodCount()} meals in the pantry`, 'gold'),
        button('Go to the shop', () => go('shop'), 'soft', {})], 'head'),
      el('div', { class: 'scroll' }, [el('div', { class: 'col' }, SECTIONS.map(section))]),
    ]),
    scene: 'room',
  }
}
