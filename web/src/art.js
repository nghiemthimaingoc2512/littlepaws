// Artwork lookup. Every image is the uploaded art in /assets, sliced into
// web/public/art by tools/prepare_art.py. Nothing is drawn in code.
import manifest from './art-manifest.json'

export const ownerUrl = (pose) => manifest.owner[pose] ?? manifest.owner.idle
export const petUrl = (id) => manifest.pets[id] ?? null
export const sceneUrl = (scene) => manifest.bg[scene] ?? manifest.bg.room

/** Which owner-and-cat pose reads for each thing that happens. */
export const POSE = {
  idle: 'pet',        // you and your cat, together
  stroke: 'hug',
  play: 'cheer',
  treat: 'drink',
  sleepy: 'sleep',
  wink: 'wink',
}

function img(url, className, alt) {
  if (!url) {
    const box = document.createElement('div')
    box.className = `${className} art-missing`
    return box
  }
  const node = document.createElement('img')
  node.className = className
  node.src = url
  node.alt = alt ?? ''
  node.draggable = false
  return node
}

export const ownerNode = (pose = 'idle', className = 'art hero') =>
  img(ownerUrl(POSE[pose] ?? pose), className, 'you and your pet')

export const petNode = (id, className = 'art pet-portrait') =>
  img(petUrl(id), className, id)
