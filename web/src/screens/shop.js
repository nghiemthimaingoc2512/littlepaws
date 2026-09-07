// Pantry, wardrobe and room decor.
import { el, row, card, button, text, pill, icon } from '../ui.js'
import { Data, item as dataItem, getSpecies } from '../data.js'
import { AD_REWARD_COINS } from '../state.js'
import { showRewardedVideo } from '../main.js'

const TABS = [
  { id: 'food', label: 'Pantry' },
  { id: 'outfit', label: 'Your outfits' },
  { id: 'accessory', label: 'Pet accessories' },
  { id: 'decor', label: 'Room decor' },
]

let tab = 'food'

export function ShopScreen({ game }) {
  const wrap = el('div', { class: 'screen page', id: 'shop-screen' })

  const itemCard = (id) => {
    const entry = dataItem(tab, id)
    const price = entry.price ?? 0
    const currency = entry.currency ?? 'coins'
    const owned = game.owns(id)
    const equipped = tab !== 'food' && game.equipped(tab) === id
    const children = [
      el('div', { class: 'swatch', style: { background: entry.color ?? entry.sky ?? '#f6ead9' } }),
      el('h3', { text: entry.name, style: { textAlign: 'center' } }),
    ]

    if (tab === 'food') {
      children.push(el('span', { class: 'muted', text: `In the pantry: ${game.save.inventory[id] ?? 0}` }))
      if (id === getSpecies(game.petSpecies()).favorite) {
        children.push(pill(`${game.petName()}'s favourite`, 'pink'))
      }
      children.push(button(`Buy  ${price}`, () => game.buyFood(id, 1), 'soft',
        { disabled: !game.canAfford(price) }))
      children.push(button(`Buy 5  ${price * 5}`, () => game.buyFood(id, 5), 'soft',
        { disabled: !game.canAfford(price * 5) }))
    } else if (equipped) {
      children.push(pill('Wearing', 'gold'))
    } else if (owned) {
      children.push(button('Wear', () => game.equip(id), 'soft', {}))
    } else {
      children.push(button(`${price} ${currency}`, () => game.buy(tab, id), 'soft',
        { disabled: !game.canAfford(price, currency) }))
    }

    const node = card(children, 'tight')
    node.id = `shop-${id}`
    if (equipped) node.style.background = '#fbe9b8'
    return node
  }

  function draw() {
    wrap.replaceChildren(
      row([icon('shop'), el('h1', { text: 'Paw & Co.' }), el('div', { class: 'grow' }),
        card([row([
          el('span', { class: 'muted', text: 'Short on coins?' }),
          button(`Watch  +${AD_REWARD_COINS}`, () => showRewardedVideo(() => game.grantAdReward()),
            'sage', { disabled: !game.adAvailable() }),
        ])], 'tight')], 'head'),
      el('div', { class: 'tabs' }, TABS.map((entry) => {
        const node = button(entry.label, () => { tab = entry.id; draw() },
          tab === entry.id ? 'active' : 'soft', {})
        node.id = `tab-${entry.id}`
        return node
      })),
      el('div', { class: 'scroll' }, [
        el('div', { class: 'grid c4' }, Object.keys(Data.items[tab]).map(itemCard)),
      ]),
    )
  }

  draw()
  return { node: wrap, scene: 'mall' }
}
