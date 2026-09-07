// Entry point: boots the game, scales the stage, owns routing and the chrome
// that floats over every screen.
import './style.css'
import { game } from './state.js'
import { el, row, col, button, iconButton, icon, meter } from './ui.js'
import { ownerNode, roomNode } from './art.js'
import { OnboardingScreen } from './screens/onboarding.js'
import { HomeScreen } from './screens/home.js'
import { DailyScreen } from './screens/daily.js'
import { MissionsScreen } from './screens/missions.js'
import { EventsScreen } from './screens/events.js'
import { BagScreen } from './screens/bag.js'
import { MailScreen } from './screens/mail.js'
import { PetsScreen } from './screens/pets.js'
import { FriendsScreen } from './screens/friends.js'
import { MapScreen } from './screens/map.js'
import { ShopScreen } from './screens/shop.js'
import { RescueScreen } from './screens/rescue.js'
import { ProfileScreen } from './screens/profile.js'

const SCREENS = {
  onboarding: OnboardingScreen, home: HomeScreen, daily: DailyScreen,
  missions: MissionsScreen, events: EventsScreen, bag: BagScreen, mail: MailScreen,
  pets: PetsScreen, friends: FriendsScreen, map: MapScreen, shop: ShopScreen,
  rescue: RescueScreen, profile: ProfileScreen,
}

const TABS = [
  { id: 'home', label: 'Home', icon: 'home' },
  { id: 'pets', label: 'Pets', icon: 'cat' },
  { id: 'friends', label: 'Friends', icon: 'friends' },
  { id: 'map', label: 'Map', icon: 'map' },
  { id: 'bag', label: 'Bag', icon: 'bag' },
  { id: 'shop', label: 'Shop', icon: 'shop' },
]

const app = document.getElementById('app')
const stage = el('div', { class: 'stage', id: 'stage' })
const backdrop = el('div', { id: 'backdrop' })
const host = el('div', { id: 'host' })
const chrome = el('div', { class: 'chrome', id: 'chrome' })
const toastEl = el('div', { class: 'toast', id: 'toast' })
const modalHost = el('div', { id: 'modals' })
stage.append(backdrop, host, chrome, toastEl, modalHost)
app.append(stage, el('div', {
  class: 'rotate-hint',
  html: '<div><h1>Little Paws</h1><p>Turn your device sideways to play.</p></div>',
}))

let current = 'home'
let currentArgs = {}
let currentScene = 'home'

// --- stage scaling ---------------------------------------------------------
function fit() {
  const scale = Math.min(window.innerWidth / 1280, window.innerHeight / 720)
  stage.style.transform = `scale(${scale})`
}
window.addEventListener('resize', fit)

// --- routing ---------------------------------------------------------------
export function go(name, args = {}) {
  if (!SCREENS[name]) return
  current = name
  currentArgs = args
  render()
}

function ctx() {
  return { go, args: currentArgs, game }
}

let mounted = null

function render() {
  mounted?.dispose?.()
  const factory = SCREENS[current]
  const screen = factory(ctx())
  mounted = screen
  host.replaceChildren(screen.node ?? screen)

  const scene = screen.scene ?? 'home'
  if (scene !== currentScene || !backdrop.firstChild) {
    currentScene = scene
    backdrop.replaceChildren(roomNode(scene))
  }
  renderChrome(screen.chrome !== false)
}

// --- chrome ----------------------------------------------------------------
function walletPill(iconName, value, onAdd) {
  return el('div', { class: 'coin-pill' }, [
    icon(iconName), el('b', { text: value }),
    el('button', { class: 'coin-add', onClick: onAdd, 'aria-label': `more ${iconName}` }, [icon('plus')]),
  ])
}

function shortNumber(n) {
  if (n < 1000) return String(n)
  if (n < 1000000) return `${Math.floor(n / 1000)},${String(n % 1000).padStart(3, '0')}`
  return `${(n / 1000000).toFixed(1)}M`
}

function renderChrome(visible) {
  chrome.replaceChildren()
  chrome.style.display = visible && game.started() ? '' : 'none'
  if (!visible || !game.started()) return

  const level = game.playerLevelInfo()
  const avatar = el('div', { class: 'avatar' }, [ownerNode('idle', 'creature')])
  const player = el('button', { class: 'player-card', id: 'btn-profile', onClick: () => go('profile') }, [
    avatar,
    el('div', {}, [
      el('div', { class: 'player-name', text: game.ownerName() }),
      el('div', { class: 'player-level' }, [
        el('span', { text: `Lv. ${level.level}` }),
        el('div', { class: 'xp-track' }, [
          el('div', { class: 'xp-fill', style: { width: `${(level.into / level.need) * 100}%` } }),
        ]),
      ]),
    ]),
    icon('paw', 'paw-mark'),
  ])

  const wallet = el('div', { class: 'wallet' }, [
    walletPill('coin', shortNumber(game.coins()), () => showRewardedVideo(() => game.grantAdReward())),
    walletPill('gem', String(game.gems()), () => go('shop')),
    walletPill('heart', String(game.hearts()), () => go('daily')),
  ])

  const corner = el('div', { class: 'corner' }, [
    iconButton('mail', () => go('mail'), 'round-btn', game.unreadMail()),
    iconButton('camera', takePhoto),
    iconButton('gear', () => go('profile')),
  ])

  const nav = el('div', { class: 'nav' }, TABS.map((tab) => {
    const node = el('button', {
      class: `nav-item ${tab.id === current ? 'active' : ''}`,
      id: `nav-${tab.id}`,
      onClick: () => go(tab.id),
    }, [icon(tab.icon), el('span', { text: tab.label })])
    if (tab.id === 'friends' && game.friendsHaveNews()) node.append(el('span', { class: 'dot' }))
    return node
  }))

  const play = el('button', { class: 'play-btn', id: 'btn-play', onClick: () => go('home', { openCare: true }) },
    [icon('paw'), document.createTextNode("Let's Play!"), icon('heart')])

  chrome.append(player, wallet, corner, el('div', { class: 'bottom' }, [
    el('div', { class: 'logo' }, [
      el('b', { text: 'Little Paws' }),
      el('span', { text: 'Small Paws · Big Happiness' }),
    ]),
    nav, play,
  ]))
}

// --- camera ----------------------------------------------------------------
async function takePhoto() {
  chrome.style.visibility = 'hidden'
  await new Promise((r) => requestAnimationFrame(r))
  chrome.style.visibility = ''
  showToast('Photo mode: the room is yours to keep.')
}

// --- rewarded video --------------------------------------------------------
/**
 * Stand-in for a real rewarded ad. Replace the body with an SDK call and run
 * `onReward` from the SDK's reward callback. See docs/MONETISATION.md.
 */
export function showRewardedVideo(onReward) {
  if (!game.adAvailable()) { showToast('More free coins in a little while.'); return }
  const counter = el('h2', { text: 'Your reward arrives in 5…' })
  const veil = el('div', { class: 'ad-veil', id: 'ad-veil' }, [
    el('div', { class: 'col center', style: { textAlign: 'center' } }, [
      el('h2', { text: 'Sponsored break' }), counter,
    ]),
  ])
  modalHost.append(veil)
  let left = 5
  const timer = setInterval(() => {
    left -= 1
    if (left > 0) { counter.textContent = `Your reward arrives in ${left}…`; return }
    clearInterval(timer)
    veil.remove()
    onReward?.()
  }, 1000)
}

// --- toast & celebration ---------------------------------------------------
let toastTimer = null
export function showToast(message) {
  toastEl.textContent = message
  toastEl.classList.add('show')
  clearTimeout(toastTimer)
  toastTimer = setTimeout(() => toastEl.classList.remove('show'), 2400)
}

const CELEBRATION_ICON = {
  stage: 'sparkle', chapter: 'map', rescue: 'paw', tame: 'heart',
  home: 'home', badge: 'trophy', daily: 'calendar',
}

const celebrationQueue = []
function showNextCelebration() {
  if (!celebrationQueue.length) return
  const { title, body, icon: kind } = celebrationQueue[0]
  const veil = el('div', { class: 'modal-veil', id: 'celebration' })
  veil.append(el('div', { class: 'modal' }, [
    icon(CELEBRATION_ICON[kind] ?? 'paw'),
    el('h1', { text: title, style: { fontSize: '27px' } }),
    el('p', { text: body }),
    button('Lovely', () => {
      veil.remove()
      celebrationQueue.shift()
      showNextCelebration()
    }, 'primary', {}),
  ]))
  modalHost.append(veil)
}

// --- wiring ----------------------------------------------------------------
game.addEventListener('changed', () => render())
game.addEventListener('toast', (e) => showToast(e.detail))
game.addEventListener('celebrate', (e) => {
  celebrationQueue.push(e.detail)
  if (celebrationQueue.length === 1) showNextCelebration()
})

window.addEventListener('beforeunload', () => game.persist())

fit()
if (game.load()) go('home')
else go('onboarding')

// Exposed for the automated interaction tests.
window.__littlepaws = { game, go, showToast }
