// Home. Your pet is the screen; everything else is three buttons.
import { el, button, roundButton, icon } from '../ui.js'
import { ownerNode, ownerUrl, POSE } from '../art.js'
import { petNode } from '../art.js'
import { MY_PET } from '../content.js'

export function HomeScreen({ go, game }) {
  const hero = ownerNode('idle', 'art hero')
  let settle = null

  /** Swap to a reaction pose, then settle back. */
  function react(pose) {
    hero.src = ownerUrl(POSE[pose] ?? pose)
    clearTimeout(settle)
    settle = setTimeout(() => { hero.src = ownerUrl(POSE.idle) }, 2200)
  }

  function hearts(count = 3) {
    for (let i = 0; i < count; i += 1) {
      const spark = el('div', { class: 'spark', text: '♥' })
      spark.style.left = `${29 + Math.random() * 12}%`
      spark.style.bottom = `${400 + Math.random() * 70}px`
      spark.style.animationDelay = `${i * 0.12}s`
      wrap.append(spark)
      setTimeout(() => spark.remove(), 1400)
    }
  }

  function stroke() {
    game.strokePet()
    react('stroke')
    hearts()
  }

  function takeTreat() {
    if (!game.giveTreat()) return
    react('treat')
    hearts(4)
    treatBubble.remove()
  }

  const treatBubble = el('button', {
    class: 'treat-bubble', id: 'treat', onClick: takeTreat, 'aria-label': 'give the treat',
  }, [icon('paw'), 'A treat for her'])

  const wrap = el('div', { class: 'screen', id: 'home-screen' }, [
    el('div', { class: 'name-tag' }, [
      petNode(MY_PET, 'art pet-portrait'),
      el('b', { text: game.petName() }),
    ]),
    el('div', { class: 'corner' }, [
      roundButton('cat', () => go('pets'), { id: 'to-pets', label: 'pets you have met' }),
      roundButton('book', () => go('memories'), { id: 'to-memories', label: 'memories' }),
    ]),
    el('button', { class: 'stage-pet', id: 'pet-tap', onClick: stroke, 'aria-label': `pet ${game.petName()}` }, [hero]),
    el('div', { class: 'actions' }, [
      button('Pet', stroke, 'btn-big', { id: 'act-pet' }),
      button('Play', () => go('play'), 'btn-primary btn-big', { id: 'act-play' }),
      button('Explore', () => go('park'), 'btn-big', { id: 'act-explore' }),
    ]),
  ])

  if (game.hasTreat()) wrap.append(treatBubble)

  return {
    node: wrap,
    scene: 'room',
    // Reactions animate in place; a rebuild would cut them short.
    keepOnChange: true,
    dispose() { clearTimeout(settle) },
  }
}
