// One step: name your cat.
import { el, card, button, text } from '../ui.js'
import { ownerNode } from '../art.js'

export function OnboardingScreen({ go, game }) {
  const field = el('input', {
    type: 'text', id: 'pet-name', maxlength: '14', placeholder: 'Name your cat',
  })
  const start = () => { game.begin(field.value); go('home') }
  field.addEventListener('keydown', (e) => { if (e.key === 'Enter') start() })

  return {
    node: el('div', { class: 'onboard', id: 'onboarding' }, [
      card([
        ownerNode('stroke', 'art'),
        el('h1', { text: 'Little Paws' }),
        text('She has been waiting for you. What should we call her?'),
        field,
        button('Begin', start, 'btn-primary btn-big', { id: 'begin' }),
      ]),
    ]),
    scene: 'room',
  }
}
