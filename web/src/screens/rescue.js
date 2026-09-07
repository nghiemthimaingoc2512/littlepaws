// A rescue mission. The animal shows what it needs; you answer.
// There is no timer and no failure — a wrong guess costs nothing but a nudge.
import { el, row, card, button, text, pill, icon, meter } from '../ui.js'
import { creatureNode } from '../art.js'
import { getSpecies, rescuableIds } from '../data.js'

const ROUNDS = 5
const NEEDS = [
  { id: 'feed', prompt: "%s's stomach growls softly.", hint: 'They are hungry.' },
  { id: 'play', prompt: '%s watches you, then looks away.', hint: 'They are lonely.' },
  { id: 'bathe', prompt: '%s is dusty from the road.', hint: 'They need cleaning up.' },
  { id: 'brush', prompt: "%s's fur is tangled and matted.", hint: 'A brush would help.' },
  { id: 'sleep', prompt: "%s's eyes keep drifting closed.", hint: 'They are exhausted.' },
  { id: 'heal', prompt: '%s is favouring one paw.', hint: 'They are hurt.' },
]
const CHOICES = [
  { id: 'feed', label: 'Offer food' }, { id: 'play', label: 'Play gently' },
  { id: 'bathe', label: 'Clean them up' }, { id: 'brush', label: 'Brush them' },
  { id: 'sleep', label: 'Make a warm bed' }, { id: 'heal', label: 'Treat the wound' },
]

const pickNeed = () => NEEDS[Math.floor(Math.random() * NEEDS.length)]

// One mission in progress. Rescuing changes the save, which rebuilds the
// screen, so the run has to outlive the rebuild.
let session = null

export function RescueScreen({ go, args, game }) {
  const speciesId = args.species || rescuableIds()[0]
  const info = getSpecies(speciesId)
  if (!session || session.species !== speciesId) {
    session = { species: speciesId, round: 0, need: pickNeed(), message: '', showHint: false, finished: false }
  }

  const wrap = el('div', { class: 'screen page', id: 'rescue-screen' })

  function answer(choiceId) {
    if (choiceId !== session.need.id) {
      session.message = `Not quite — ${info.name} stays still. Try another way.`
      session.showHint = true
      draw()
      return
    }
    session.round += 1
    if (session.round >= ROUNDS) {
      session.finished = true
      game.rescue(speciesId)
      draw()
      return
    }
    session.message = `That was exactly right. ${info.name} edges a little closer.`
    session.need = pickNeed()
    session.showHint = false
    draw()
  }

  function draw() {
    if (session.finished) {
      wrap.replaceChildren(el('div', { class: 'onboard' }, [
        card([
          el('div', { class: 'tile' }, [creatureNode(speciesId, 'happy')]),
          el('h1', { text: `${info.name} is safe` }),
          text(info.bio), text(info.hint),
          row([
            button('Take them to the Sanctuary', () => go('friends', { species: speciesId }), 'primary', {}),
            button('Back to the map', () => go('map'), 'soft', {}),
          ], 'center'),
        ], 'onboard-card'),
      ]))
      return
    }

    wrap.replaceChildren(
      row([icon('paw'), el('h1', { text: `Rescue: ${info.name}` })], 'head'),
      el('div', { class: 'rescue-body' }, [
        el('div', { class: 'rescue-left' }, [
          creatureNode(speciesId, 'peek'),
          meter('Calm', session.round, ROUNDS, '#a8cc8c', { hideValue: true }),
          el('span', { class: 'muted', text: `Step ${Math.min(session.round + 1, ROUNDS)} of ${ROUNDS}` }),
        ]),
        el('div', { class: 'rescue-right' }, [
          card([
            el('h2', { text: session.need.prompt.replace('%s', info.name) }),
            session.showHint && text(session.need.hint),
            session.message && text(session.message),
          ]),
          el('div', { class: 'choice-grid' }, CHOICES.map((choice) => {
            const node = button(choice.label, () => answer(choice.id), 'soft', {})
            node.id = `choice-${choice.id}`
            return node
          })),
          row([
            button('What do they need?', () => { session.showHint = true; draw() }, 'soft', {}),
            button('Come back later', () => go('map'), 'soft', {}),
          ]),
        ]),
      ]),
    )
  }

  draw()
  return { node: wrap, scene: info.region === 'alley' ? 'mall' : 'home' }
}
