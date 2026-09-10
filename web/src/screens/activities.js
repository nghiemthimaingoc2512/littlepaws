// The Play hub: what you and your cat can do today, and who still needs help.
import { el, row, card, button, text, pill, icon } from '../ui.js'
import { ownerNode, petNode } from '../art.js'
import { getSpecies } from '../data.js'
import { ACTIVITIES } from '../state.js'

const ACTIVITY_POSE = { bath: 'wink', snack: 'drink', fetch: 'cheer' }

export function ActivitiesScreen({ go, game }) {
  const activityCard = ([id, activity]) => {
    const node = card([
      el('div', { class: 'activity' }, [
        ownerNode(ACTIVITY_POSE[id] ?? 'cheer', 'art'),
        el('h3', { text: activity.label }),
        text(activity.blurb),
        pill(`+${activity.coins} coins`, 'gold'),
      ]),
      button('Start', () => go('minigame', { activity: id }), 'primary', {}),
    ])
    node.id = `activity-${id}`
    node.querySelector('.activity img').style.height = '104px'
    node.querySelector('.activity img').style.width = 'auto'
    return node
  }

  const missions = game.availableMissions()
  const missionCard = (speciesId) => {
    const info = getSpecies(speciesId)
    const node = card([
      el('div', { class: 'activity' }, [
        petNode(speciesId, 'art art-pet'),
        el('h3', { text: info.name }),
        text(info.bio),
        pill(String(info.rarity ?? 'common'), 'sage'),
      ]),
      button('Go find them', () => go('rescue', { species: speciesId }), 'primary', {}),
    ])
    node.id = `mission-${speciesId}`
    return node
  }

  const body = el('div', { class: 'col' }, [
    el('h2', { text: 'Things to do together' }),
    el('div', { class: 'activity-grid' }, Object.entries(ACTIVITIES).map(activityCard)),
  ])

  const chapter = game.currentChapter()
  if (missions.length) {
    body.append(el('h2', { text: 'Somebody needs help' }))
    body.append(el('div', { class: 'activity-grid' }, missions.map(missionCard)))
  } else if (chapter) {
    body.append(card([
      el('h2', { text: 'Nobody is out there right now' }),
      text('Everyone you found is safe. Reunite them with their people and the next place opens.'),
      button('Go to Friends', () => go('friends'), 'primary', {}),
    ]))
  }

  return {
    node: el('div', { class: 'screen page', id: 'activities-screen' }, [
      row([icon('sparkle'), el('h1', { text: 'Play' }), el('div', { class: 'grow' }),
        pill(`${game.homedCount()} reunited`, 'pink')], 'head'),
      el('div', { class: 'scroll' }, [body]),
    ]),
    scene: 'room',
  }
}
