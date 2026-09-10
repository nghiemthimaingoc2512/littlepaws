// Artwork lookup.
//
// Every image here is the artwork from /assets, sliced by tools/prepare_art.py
// into web/public/art. Nothing is drawn in code: if a piece of art is missing
// the game shows a neutral placeholder rather than a redrawing of the subject.
import manifest from '../public/art/manifest.json'

export const ART = manifest

/** Poses the owner artwork provides, in the order they appear on the sheet. */
export const OWNER_POSES = Object.keys(manifest.owner)

export const ownerUrl = (pose) => manifest.owner[pose] ?? manifest.owner.idle
export const petUrl = (petId) => manifest.pets[petId] ?? null
export const friendUrl = (npcId) => manifest.npc[npcId] ?? null
export const sceneUrl = (scene) => manifest.bg[scene] ?? manifest.bg.room

/** How the owner artwork should read for each thing the game does. */
const CARE_POSE = {
  feed: 'drink', play: 'cheer', bathe: 'wink', brush: 'hug', sleep: 'sleep', heal: 'think',
}
const MOOD_POSE = { happy: 'pet', idle: 'pet', loaf: 'think', curl: 'sleep' }

export const carePose = (actionId) => CARE_POSE[actionId] ?? 'pet'
export const moodPose = (mood) => MOOD_POSE[mood] ?? 'pet'

function image(url, className, alt = '') {
  const node = document.createElement(url ? 'img' : 'div')
  node.className = className
  if (url) {
    node.src = url
    node.alt = alt
    node.draggable = false
    node.addEventListener('error', () => { node.classList.add('art-missing') }, { once: true })
  } else {
    node.classList.add('art-missing')
  }
  return node
}

export const ownerNode = (pose = 'idle', className = 'art art-owner') =>
  image(ownerUrl(pose), className, 'your character')

export const petNode = (petId, className = 'art art-pet') =>
  image(petUrl(petId), className, petId)

export const friendNode = (npcId, className = 'art art-friend') =>
  image(friendUrl(npcId), className, npcId)

/** Sets a scene as a CSS background on an element. */
export function paintScene(node, scene) {
  node.style.backgroundImage = `url("${sceneUrl(scene)}")`
}
