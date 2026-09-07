// First run: name yourself, choose the one pet you will raise, make the promise.
import { el, card, button, text } from '../ui.js'
import { creatureNode } from '../art.js'
import { starterIds, getSpecies } from '../data.js'

export function OnboardingScreen({ go, game }) {
  let step = 0
  let ownerName = ''
  let speciesId = ''

  const wrap = el('div', { class: 'onboard', id: 'onboarding' })
  const draw = () => {
    wrap.replaceChildren(step === 0 ? welcome() : step === 1 ? choose() : promise())
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
        step = 1
        draw()
      }, 'primary', {}),
    ], 'onboard-card')
  }

  function choose() {
    return el('div', { class: 'col', style: { alignItems: 'center', gap: '16px' } }, [
      el('h1', { text: 'Choose your one pet' }),
      text('You will raise this friend for the whole journey. Pick the one you want to wake up to.'),
      el('div', { class: 'starter-row' }, starterIds().map((id) => {
        const info = getSpecies(id)
        return card([
          creatureNode(id, 'happy'),
          el('h2', { text: info.name }),
          el('div', { class: 'row center', style: { flexWrap: 'wrap', gap: '5px' } },
            (info.traits ?? []).map((t) => el('span', { class: 'pill sage', text: t }))),
          text(info.bio),
          button('Choose', () => { speciesId = id; step = 2; draw() }, 'primary', {}),
        ], `starter ${speciesId === id ? 'selected' : ''}`)
      })),
    ])
  }

  function promise() {
    const info = getSpecies(speciesId)
    const field = el('input', {
      type: 'text', id: 'pet-name', maxlength: '14',
      placeholder: `Your ${String(info.kind ?? 'pet').toLowerCase()}'s name`,
    })
    return card([
      creatureNode(speciesId, 'happy'),
      el('h1', { text: 'Give them a name', style: { fontSize: '30px' } }),
      field,
      text('I promise to feed them, keep them clean, play with them, and come back to them.'),
      el('div', { class: 'row center' }, [
        button('Choose again', () => { step = 1; draw() }, 'soft', {}),
        button('I promise', () => {
          game.newGame(speciesId, field.value.trim() || info.kind || 'Pet', ownerName)
          game.dailyCheck()
          go('home')
        }, 'primary', {}),
      ]),
    ], 'onboard-card')
  }

  draw()
  return { node: wrap, scene: 'home', chrome: false }
}
