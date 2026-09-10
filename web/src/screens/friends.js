// Friends: the animals waiting for you, and the people who have been waiting
// for them. Reuniting a pair is a guess you can make as many times as you like.
import { el, row, card, button, text, pill, icon, meter } from '../ui.js'
import { petNode, friendNode } from '../art.js'
import { getSpecies, speciesName, npc as dataNpc, Data } from '../data.js'
import { TAME_ACTIONS } from '../state.js'

let selected = ''
let matching = false

export function FriendsScreen({ go, args, game }) {
  if (args.species) { selected = args.species; matching = false }
  const wrap = el('div', { class: 'screen page', id: 'friends-screen' })

  function draw() {
    const waiting = game.sanctuaryIds()
    if (!selected || !waiting.includes(selected)) selected = waiting[0] ?? ''

    const header = row([
      icon('friends'), el('h1', { text: 'Friends' }), el('div', { class: 'grow' }),
      pill(`${waiting.length} waiting`, 'sage'),
      pill(`${game.homedCount()} / 5 reunited`, 'pink'),
    ], 'head')

    const body = el('div', { class: 'col' })
    body.append(waiting.length ? row([list(waiting), detail()], 'grow') : quiet())
    body.append(el('h2', { text: 'Our human friends' }))
    body.append(el('div', { class: 'grid c3' }, Data.npcs.map(friendCard)))

    wrap.replaceChildren(header, el('div', { class: 'scroll' }, [body]))
  }

  function quiet() {
    return card([
      el('h2', { text: 'Nobody is waiting right now' }),
      text('Every animal you found is home. Head out to Play to find someone new.'),
      button('Go to Play', () => go('activities'), 'primary', {}),
    ])
  }

  function list(waiting) {
    return el('div', { style: { width: '330px', flex: 'none' } },
      [el('div', { class: 'col' }, waiting.map((id) => {
        const node = card([
          row([
            petNode(id, 'art art-pet'),
            el('div', { class: 'grow' }, [
              el('h3', { text: speciesName(id) }),
              meter(`Trust ${game.trust(id)}%`, game.trust(id), 100, '#f2a9b4', { hideValue: true }),
            ]),
            button('Visit', () => { selected = id; matching = false; draw() }, 'soft', {}),
          ], 'pair'),
        ], 'tight')
        node.id = `friend-${id}`
        if (id === selected) node.style.background = '#fbdde2'
        return node
      }))])
  }

  function detail() {
    const info = getSpecies(selected)
    const tamed = game.isTamed(selected)
    const children = [
      row([
        petNode(selected, 'art art-pet'),
        el('div', { class: 'grow' }, [
          el('h2', { text: info.name }),
          text(info.bio),
          el('div', { class: 'chips' }, (info.traits ?? []).map((t) => pill(t, 'sky'))),
        ]),
      ], 'pair'),
      meter('Trust', game.trust(selected), 100, '#f2a9b4'),
    ]

    if (matching) {
      children.push(el('h2', { text: 'Who has been waiting for them?' }))
      children.push(text('Their traits are the clue. A wrong guess costs nothing — they simply wait.'))
      children.push(el('div', { class: 'grid c3' }, game.friendCandidates(selected).map((person) => {
        const node = card([
          el('div', { class: 'friend-card' }, [
            friendNode(person.id, 'art art-friend'),
            el('h3', { text: person.name }),
            el('div', { class: 'chips' }, person.likes.map((l) => pill(l))),
          ]),
          button('They belong together', () => {
            if (game.homeAnimal(selected, person.id)) { matching = false; selected = '' }
          }, 'primary', {}),
        ], 'tight')
        node.id = `candidate-${person.id}`
        return node
      })))
      children.push(button('Not yet', () => { matching = false; draw() }, 'soft', {}))
    } else if (tamed) {
      children.push(text(`${info.name} is ready. Somewhere out there is the person who has been waiting.`))
      const find = button('Find their person', () => { matching = true; draw() }, 'primary', {})
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

  function friendCard(person) {
    const pet = person.pet
    const reunited = pet && game.isHomed(pet)
    const node = card([
      el('div', { class: 'friend-card' }, [
        friendNode(person.id, 'art art-friend'),
        el('h3', { text: person.name }),
        el('div', { class: 'friend-quote', text: `“${person.quote}”` }),
        el('div', { class: 'chips' }, (person.interests ?? []).map((i) => pill(i))),
        reunited
          ? pill(`Together with ${speciesName(pet)}`, 'sage')
          : pet ? pill('Still looking', 'red') : pill('Runs the photo walk', 'sky'),
      ]),
    ])
    node.id = `person-${person.id}`
    if (reunited) node.style.background = '#eef6e6'
    return node
  }

  draw()
  return { node: wrap, scene: 'room' }
}
