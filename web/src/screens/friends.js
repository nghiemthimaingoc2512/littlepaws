// Where rescued animals stay until they trust you, and until you find the
// person they will spend their life with.
import { el, row, card, button, text, pill, icon, meter } from '../ui.js'
import { creatureNode } from '../art.js'
import { getSpecies, speciesName } from '../data.js'
import { TAME_ACTIONS } from '../state.js'

let selected = ''
let matching = false

export function FriendsScreen({ go, args, game }) {
  if (args.species) { selected = args.species; matching = false }
  const wrap = el('div', { class: 'screen page', id: 'friends-screen' })

  function draw() {
    const waiting = game.sanctuaryIds()
    if (!selected || !waiting.includes(selected)) selected = waiting[0] ?? ''

    const header = row([icon('friends'), el('h1', { text: 'Friends' }), el('div', { class: 'grow' }),
      pill(`${waiting.length} waiting · ${game.homedCount()} homed`, 'sage')], 'head')

    if (!waiting.length) {
      wrap.replaceChildren(header, card([
        el('h2', { text: 'The sanctuary is quiet right now' }),
        text('Every animal you rescued has found their person. Head out on the map to find someone new.'),
        button('Open the map', () => go('map'), 'primary', {}),
      ]))
      return
    }

    const list = el('div', { class: 'scroll', style: { width: '360px', flex: 'none' } },
      [el('div', { class: 'col' }, waiting.map((id) => {
        const node = card([
          row([
            el('div', { class: 'tile', style: { width: '64px' } }, [creatureNode(id, 'idle')]),
            el('div', { class: 'grow' }, [
              el('h3', { text: speciesName(id) }),
              meter(`Trust ${game.trust(id)}%`, game.trust(id), 100, '#f2a9b4', { hideValue: true }),
            ]),
            button('Visit', () => { selected = id; matching = false; draw() }, 'soft', {}),
          ]),
        ], 'tight')
        node.id = `friend-${id}`
        if (id === selected) node.style.background = '#fbdde2'
        return node
      }))])

    wrap.replaceChildren(header, row([list, detail()], 'grow'))
  }

  function detail() {
    const info = getSpecies(selected)
    const tamed = game.isTamed(selected)
    const children = [
      row([
        el('div', { class: 'tile', style: { width: '120px' } }, [creatureNode(selected, tamed ? 'happy' : 'peek')]),
        el('div', { class: 'grow' }, [
          el('h2', { text: info.name }),
          text(info.bio),
          el('div', { class: 'row', style: { flexWrap: 'wrap', gap: '5px' } },
            (info.traits ?? []).map((t) => el('span', { class: 'pill sky', text: t }))),
        ]),
      ]),
      meter('Trust', game.trust(selected), 100, '#f2a9b4'),
    ]

    if (matching) {
      children.push(el('h2', { text: 'Who should they go home with?' }))
      children.push(text('Every one of these people would love them. A closer match simply makes for a sweeter story.'))
      children.push(el('div', { class: 'grid c3' }, game.friendCandidates(selected).map((person) => {
        const score = game.matchScore(selected, person.id)
        return card([
          el('h3', { text: person.name, style: { textAlign: 'center' } }),
          text(person.blurb),
          el('div', { class: 'row center', style: { flexWrap: 'wrap', gap: '4px' } },
            person.likes.map((l) => el('span', { class: 'pill', text: l }))),
          el('span', { class: 'muted', text: score >= 0.95 ? 'A perfect fit' : score >= 0.65 ? 'A warm match' : 'A gentle match' }),
          button('They belong together', () => {
            game.homeAnimal(selected, person.id)
            matching = false
            selected = ''
          }, 'primary', {}),
        ], 'tight')
      })))
      children.push(button('Not yet', () => { matching = false; draw() }, 'soft', {}))
    } else if (tamed) {
      children.push(text(`${info.name} is ready. Somewhere out there is a person who has been waiting for them.`))
      const find = button('Find a forever friend', () => { matching = true; draw() }, 'primary', {})
      find.id = 'find-friend'
      children.push(find)
    } else {
      children.push(text(info.hint))
      children.push(row(Object.entries(TAME_ACTIONS).map(([id, action]) => {
        const node = button(action.label, () => game.doTame(selected, id), 'soft', {
          disabled: game.tameBlockedReason(selected, id) !== '',
        })
        node.id = `tame-${id}`
        node.style.flex = '1'
        return node
      })))
    }
    return card(children, 'grow')
  }

  draw()
  return { node: wrap, scene: 'home' }
}
