// Who you have met. Five slots, so the empty ones are an invitation.
import { el, button, text, roundButton } from '../ui.js'
import { petNode } from '../art.js'
import { PETS, MY_PET } from '../content.js'

export function PetsScreen({ go, game }) {
  const card = (info) => {
    const known = game.isDiscovered(info.id)
    const mine = info.id === MY_PET
    const name = mine ? game.petName() : info.name
    return el('div', { class: 'pet-card', id: `pet-${info.id}` }, [
      petNode(info.id, `art pet-portrait ${known ? '' : 'unknown'}`),
      el('span', { class: 'tag', text: known ? name : '???' }),
      el('span', {
        class: known && (mine || game.isFriend(info.id)) ? 'friend-mark' : 'tag-note',
        text: mine ? 'your cat' : !known ? 'not met yet' : game.isFriend(info.id) ? '♥ friend' : 'met',
      }),
    ])
  }

  return {
    node: el('div', { class: 'page', id: 'pets-screen' }, [
      el('div', { class: 'page-head' }, [
        roundButton('back', () => go('home'), { id: 'pets-home', label: 'go home' }),
        el('h1', { text: 'Pets' }),
        el('div', { class: 'grow' }),
        text(`${game.discoveredCount()} of ${PETS.length} met`),
      ]),
      el('div', { class: 'pet-grid' }, PETS.map(card)),
      el('div', { class: 'grow' }),
      text('Take your cat to the park to meet the rest.'),
    ]),
    scene: 'room',
  }
}
