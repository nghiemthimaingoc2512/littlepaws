// Entry point: scales the stage, routes between five screens, and owns the two
// overlays (a one-line toast and the celebration moment).
import './style.css'
import { game } from './state.js'
import { el, button } from './ui.js'
import { sceneUrl, petNode } from './art.js'
import { OnboardingScreen } from './screens/onboarding.js'
import { HomeScreen } from './screens/home.js'
import { PlayScreen } from './screens/play.js'
import { ParkScreen } from './screens/park.js'
import { PetsScreen } from './screens/pets.js'
import { MemoriesScreen } from './screens/memories.js'

const SCREENS = {
  onboarding: OnboardingScreen, home: HomeScreen, play: PlayScreen,
  park: ParkScreen, pets: PetsScreen, memories: MemoriesScreen,
}

const app = document.getElementById('app')
const stage = el('div', { class: 'stage', id: 'stage' })
const scene = el('div', { class: 'scene', id: 'scene' })
const host = el('div', { id: 'host' })
const toastEl = el('div', { class: 'toast', id: 'toast' })
const overlay = el('div', { id: 'overlay' })
stage.append(scene, host, toastEl, overlay)
app.append(stage, el('div', {
  class: 'rotate-hint',
  html: '<div><h1>Little Paws</h1><p>Turn your device sideways to play.</p></div>',
}))

let current = ''
let mounted = null
let currentScene = ''

const fit = () => {
  stage.style.transform = `scale(${Math.min(window.innerWidth / 1280, window.innerHeight / 720)})`
}
window.addEventListener('resize', fit)

export function go(name, args = {}) {
  if (!SCREENS[name]) return
  mounted?.dispose?.()
  current = name
  const screen = SCREENS[name]({ go, args, game })
  mounted = screen
  host.replaceChildren(screen.node ?? screen)
  const next = screen.scene ?? 'room'
  if (next !== currentScene) {
    currentScene = next
    scene.style.backgroundImage = `url("${sceneUrl(next)}")`
  }
}

// --- overlays --------------------------------------------------------------
let toastTimer = null
function say(message) {
  toastEl.textContent = message
  toastEl.classList.add('show')
  clearTimeout(toastTimer)
  toastTimer = setTimeout(() => toastEl.classList.remove('show'), 2400)
}

/** The one big emotional beat: two pets, a heart, and a line about them. */
function celebrate({ title, body, pets = [] }) {
  const veil = el('div', { class: 'veil', id: 'celebration' })
  const pair = pets.length === 2
    ? el('div', { class: 'pair' }, [
        petNode(pets[0]), el('span', { class: 'heart', text: '♥' }), petNode(pets[1]),
      ])
    : null
  veil.append(el('div', { class: 'modal card' }, [
    pair,
    el('h1', { text: title }),
    el('p', { text: body }),
    button('Lovely', () => veil.remove(), 'btn-primary btn-big', { id: 'celebration-ok' }),
  ]))
  overlay.append(veil)
}

game.addEventListener('changed', () => { if (mounted?.keepOnChange !== true) go(current) })
game.addEventListener('say', (e) => say(e.detail))
game.addEventListener('celebrate', (e) => celebrate(e.detail))
window.addEventListener('beforeunload', () => game.persist())

fit()
go(game.load() ? 'home' : 'onboarding')

// Exposed for the automated play-through test.
window.__littlepaws = { game, go }
