// The room. Four shortcuts down the left, the day's list on the right, and you
// and your cat in the middle — drawn from the uploaded artwork, not redrawn.
//
// Care lives in a sheet that slides up, so the room itself stays uncluttered.
import { el, row, button, icon, meter } from '../ui.js'
import { ownerNode, ownerUrl, carePose, moodPose } from '../art.js'
import { ACTIONS, STAT_KEYS, STAGES, DAILY_TASKS } from '../state.js'

const STAT_COLORS = {
  food: '#f0a86a', clean: '#8fc7e8', energy: '#f2c761', mood: '#f4a3b4', health: '#9ecfa5',
}
const CARE_ORDER = ['feed', 'play', 'bathe', 'brush', 'sleep', 'heal']
const RAIL = [
  { id: 'daily', label: 'Daily', icon: 'calendar' },
  { id: 'missions', label: 'Missions', icon: 'trophy' },
  { id: 'activities', label: 'Play', icon: 'sparkle' },
  { id: 'shop', label: 'Shop', icon: 'shop' },
]

// The care sheet is view state, not game state, so it lives outside the screen
// and a save change cannot slam it shut mid-tap.
let careOpen = false

export function HomeScreen({ go, args, game }) {
  if (args.openCare) careOpen = true
  const wrap = el('div', { class: 'screen', id: 'home-screen' })
  const meters = {}
  const careButtons = {}
  let heroImg = null
  let poseTimer = null

  const railNews = (id) => (
    id === 'daily' ? game.anyTaskClaimable()
      : id === 'missions' ? game.missionsHaveNews()
        : id === 'activities' ? game.eventsHaveNews() : false)

  function rail() {
    return el('div', { class: 'rail' }, RAIL.map((entry) => {
      const node = el('button', { class: 'rail-btn', id: `rail-${entry.id}`, onClick: () => go(entry.id) },
        [icon(entry.icon), el('span', { text: entry.label })])
      if (railNews(entry.id)) node.append(el('span', { class: 'dot' }))
      return node
    }))
  }

  function moodIcon() {
    if (game.stat('food') < 40) return 'bowl'
    if (game.stat('clean') < 40) return 'drop'
    if (game.stat('energy') < 35) return 'moon'
    if (game.stat('mood') < 45) return 'paw'
    return 'heart'
  }

  function todo() {
    return el('div', { class: 'card todo' }, [
      el('h3', { text: 'To Do Today' }),
      ...DAILY_TASKS.map((task) => {
        const done = game.taskDone(task)
        const line = el('div', { class: `todo-row ${done ? 'done' : ''}` }, [
          el('div', { class: `tick ${done ? 'done' : ''}` }, done ? [icon('check')] : []),
          el('span', { text: task.label }),
        ])
        if (game.taskClaimable(task)) {
          line.append(el('button', {
            class: 'todo-claim', id: `claim-${task.id}`,
            onClick: () => game.claimTask(task.id),
          }, [icon('plus')]))
        }
        return line
      }),
    ])
  }

  function petStage() {
    heroImg = ownerNode(moodPose(game.moodPose()), 'art')
    return el('div', { class: `pet-stage ${careOpen ? 'raised' : ''}`, id: 'pet-stage' }, [
      el('div', { class: 'bubble' }, [icon(moodIcon())]),
      el('button', {
        class: 'pet-tap', id: 'pet-tap', onClick: toggleCare,
        'aria-label': `care for ${game.petName()}`,
      }, [heroImg]),
      el('div', { class: 'name-pill', text: `${game.petName()}  ·  ${game.stageName()}` }),
    ])
  }

  function careSheet() {
    const nextStage = game.stage() < STAGES.length - 1 ? STAGES[game.stage() + 1] : 'full grown'
    const metersCol = el('div', { class: 'care-meters' }, STAT_KEYS.map((key) => {
      const bar = meter(key[0].toUpperCase() + key.slice(1), game.stat(key), 100, STAT_COLORS[key])
      meters[key] = bar
      return bar
    }))

    const actions = el('div', { class: 'care-grid' }, CARE_ORDER.map((id) => {
      const node = button(ACTIONS[id].label, () => game.doCare(id), 'soft', {})
      node.id = `care-${id}`
      careButtons[id] = node
      return node
    }))

    meters.bond = meter('Bond', game.bond(), 100, '#f2a9b4')
    meters.stage = meter(`Growth to ${nextStage}`, game.stageProgress(), 1, '#a8cc8c', { hideValue: true })

    return el('div', { class: 'care-sheet', id: 'care-sheet' }, [
      row([
        el('h2', { text: `Looking after ${game.petName()}` }),
        el('div', { class: 'grow' }),
        el('button', {
          class: 'round-btn', id: 'care-close',
          style: { width: '34px', height: '34px' }, onClick: closeCare,
        }, [icon('close')]),
      ]),
      el('div', { class: 'care-body' }, [
        metersCol,
        el('div', { class: 'care-right' }, [actions, row([meters.bond, meters.stage])]),
      ]),
    ])
  }

  function toggleCare() { careOpen = !careOpen; draw() }
  function closeCare() { careOpen = false; draw() }

  function draw() {
    wrap.replaceChildren(
      rail(),
      el('div', { class: 'side-panel' }, [todo()]),
      petStage(),
    )
    if (careOpen) wrap.append(careSheet())
    refreshCareButtons()
  }

  function refreshCareButtons() {
    for (const [id, node] of Object.entries(careButtons)) {
      const action = ACTIONS[id]
      const left = game.cooldownLeft(id)
      const cost = action.cost > 0 ? `  ${action.cost}` : ''
      node.textContent = left > 0 ? `${action.label}  ${Math.ceil(left)}s` : `${action.label}${cost}`
      node.disabled = game.careBlockedReason(id) !== ''
    }
  }

  const ticker = setInterval(refreshCareButtons, 500)
  const onTick = () => {
    for (const key of STAT_KEYS) meters[key]?.set?.(game.stat(key))
    meters.bond?.set?.(game.bond())
    meters.stage?.set?.(game.stageProgress())
  }
  // A care action swaps the artwork to the pose that matches it, then settles
  // back to how your cat is actually feeling.
  const onPose = (e) => {
    if (!heroImg) return
    heroImg.src = ownerUrl(carePose(e.detail) ?? e.detail)
    clearTimeout(poseTimer)
    poseTimer = setTimeout(() => {
      if (heroImg?.isConnected) heroImg.src = ownerUrl(moodPose(game.moodPose()))
    }, 3200)
  }
  game.addEventListener('ticked', onTick)
  game.addEventListener('pose', onPose)

  draw()
  return {
    node: wrap,
    scene: 'room',
    dispose() {
      clearInterval(ticker)
      clearTimeout(poseTimer)
      game.removeEventListener('ticked', onTick)
      game.removeEventListener('pose', onPose)
    },
  }
}
