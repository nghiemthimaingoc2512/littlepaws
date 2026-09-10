// First run: your name, then your cat's name. The artwork gives you one cat.
import { el, card, button, text } from '../ui.js'
import { ownerNode } from '../art.js'
import { starterIds, getSpecies } from '../data.js'

export function OnboardingScreen({ go, game }) {
  let step = 0
  let ownerName = ''
  let speciesId = ''

  const wrap = el('div', { class: 'onboard', id: 'onboarding' })
  const draw = () => {
    wrap.replaceChildren(step === 0 ? welcome() : promise())
  }

  function welcome() {
    const field = el('input', { type: 'text', id: 'owner-name', placeholder: 'What should we call you?', maxlength: '16' })
    return card([
      el('h1', { text: 'Little Paws' }),
      text('A quiet place to raise one small friend, and to help every animal you meet along the way.'),
      text('Nothing here can be lost. Come back whenever you like.'),
      field,
      button('Begin', () => {
        ownerName = field.value.trim() || 'Friend'
        speciesId = starterIds()[0]
        step = 1
        draw()
      }, 'primary', {}),
    ], 'onboard-card')
  }

  function promise() {
    const info = getSpecies(speciesId)
    const field = el('input', {
      type: 'text', id: 'pet-name', maxlength: '14',
      placeholder: `Your ${String(info.kind ?? 'pet').toLowerCase()}'s name`,
    })
    return card([
      ownerNode('hug', 'art'),
      el('h1', { text: 'Give them a name', style: { fontSize: '30px' } }),
      field,
      text('I promise to feed them, keep them clean, play with them, and come back to them.'),
      el('div', { class: 'row center' }, [
        button('I promise', () => {
          game.newGame(speciesId, field.value.trim() || info.kind || 'Pet', ownerName)
          game.dailyCheck()
          go('home')
        }, 'primary', {}),
      ]),
    ], 'onboard-card')
  }

  draw()
  return { node: wrap, scene: 'room', chrome: false }
}
