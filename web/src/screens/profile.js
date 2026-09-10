// Player and pet profile, plus the few settings the game needs.
import { el, row, card, button, text, pill, icon, meter } from '../ui.js'
import { ownerNode, petNode } from '../art.js'
import { Data, getSpecies, itemName, rescuableIds } from '../data.js'

let confirming = false

export function ProfileScreen({ go, game }) {
  const wrap = el('div', { class: 'screen page', id: 'profile-screen' })

  function draw() {
    const info = getSpecies(game.petSpecies())
    const days = Math.floor((Date.now() / 1000 - game.save.pet.born) / 86400)
    const rows = [
      ['Care moments', String(game.counter('care_total'))],
      ['Animals rescued', `${game.rescuedCount()} / ${rescuableIds().length}`],
      ['Forever homes found', String(game.homedCount())],
      ['Chapters complete', `${game.chaptersDone()} / ${Data.chapters.length}`],
      ['Badges earned', `${game.badgesEarned()} / ${Data.badges.length}`],
      ['Coins earned all-time', String(game.counter('coins_earned'))],
      ['Room', itemName('decor', game.equipped('decor'))],
    ]

    const settings = [
      el('h2', { text: 'Your record' }),
      ...rows.map(([label, value]) => row([
        el('span', { class: 'muted grow', text: label }),
        el('b', { text: value }),
      ])),
      text('Little Paws saves to this browser automatically. Come and go as you like.'),
    ]

    if (!confirming) {
      settings.push(button('Start over', () => { confirming = true; draw() }, 'soft', {}))
    } else {
      settings.push(text(`Starting over erases ${game.petName()}, your library, your badges and everything you have collected.`))
      settings.push(row([
        button('Keep everything', () => { confirming = false; draw() }, 'sage', {}),
        button('Erase and start over', () => { game.deleteSave(); go('onboarding') }, 'primary', {}),
      ]))
    }

    wrap.replaceChildren(
      row([icon('gear'), el('h1', { text: 'Profile' })], 'head'),
      el('div', { class: 'scroll' }, [
        row([
          card([
            el('div', { class: 'tile' }, [ownerNode('idle'), el('h2', { text: game.ownerName() })]),
            text(`Wearing ${itemName('outfit', game.equipped('outfit'))}`),
            pill(`Day ${game.streak()} in a row`, 'pink'),
            button('Open the wardrobe', () => go('shop'), 'soft', {}),
          ], 'grow'),
          card([
            el('div', { class: 'tile' }, [petNode(game.petSpecies(), 'art art-pet'), el('h2', { text: game.petName() })]),
            text(`${info.name}  ·  ${game.stageName()}`),
            text(`Together for ${days} day${days === 1 ? '' : 's'}`),
            meter('Bond', game.bond(), 100, '#f2a9b4'),
            text(`Wearing ${itemName('accessory', game.equipped('accessory'))}`),
          ], 'grow'),
          card(settings, 'grow'),
        ]),
      ]),
    )
  }

  draw()
  return { node: wrap, scene: 'room' }
}
