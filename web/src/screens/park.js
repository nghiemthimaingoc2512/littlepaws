// The Pet Park: the one place to explore, and where two pets become friends.
import { el, card, button, text, roundButton } from '../ui.js'
import { petNode } from '../art.js'
import { MY_PET } from '../content.js'

export function ParkScreen({ go, game }) {
  let them = game.nextPet()
  const wrap = el('div', { class: 'screen', id: 'park-screen' })
  let playing = false

  function draw() {
    wrap.replaceChildren(el('div', { class: 'corner' }, [
      roundButton('back', () => go('home'), { id: 'park-home', label: 'go home' }),
    ]))

    if (!them) {
      wrap.append(el('div', { class: 'onboard' }, [
        card([
          el('h1', { text: 'Everyone here is a friend' }),
          text(`${game.petName()} knows every pet in the park. Come back any time — they will all be here.`),
          button('Go home', () => go('home'), 'btn-primary btn-big', { id: 'park-home-2' }),
        ]),
      ]))
      return
    }

    const meeting = el('div', { class: `meeting ${playing ? 'playing' : ''}`, id: 'meeting' }, [
      el('figure', {}, [petNode(MY_PET), el('figcaption', { text: game.petName() })]),
      el('figure', {}, [
        petNode(them.id, playing || game.isDiscovered(them.id)
          ? 'art pet-portrait' : 'art pet-portrait unknown'),
        el('figcaption', { text: playing || game.isDiscovered(them.id) ? them.name : 'Someone new' }),
      ]),
    ])

    wrap.append(
      el('div', { class: 'speech card', id: 'park-speech' }, [
        text(playing ? `${game.petName()} and ${them.name} are chasing each other in circles.`
          : them.greeting),
      ]),
      meeting,
      el('div', { class: 'actions' }, [
        button(playing ? 'Playing…' : 'Introduce them', introduce,
          'btn-primary btn-big', { id: 'introduce', disabled: playing }),
      ]),
    )
  }

  function introduce() {
    if (playing || !them) return
    playing = true
    draw()
    // A beat of watching them play before the payoff.
    setTimeout(() => {
      game.makeFriends(them.id)
      playing = false
      // Move on to whoever is next, so the button always does something.
      them = game.nextPet()
      draw()
    }, 2200)
  }

  draw()
  return { node: wrap, scene: 'park', keepOnChange: true }
}
