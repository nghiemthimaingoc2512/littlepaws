// Game content. These are the same JSON files the Godot build reads, so
// balance and copy have exactly one source of truth.
import species from '../../data/species.json'
import chapters from '../../data/chapters.json'
import items from '../../data/items.json'
import badges from '../../data/badges.json'
import npcs from '../../data/npcs.json'

export const Data = { species, chapters, items, badges, npcs }

export const getSpecies = (id) => species[id] ?? {}
export const speciesName = (id) => getSpecies(id).name ?? id
export const starterIds = () => Object.keys(species).filter((id) => species[id].starter)
export const rescuableIds = () => Object.keys(species).filter((id) => !species[id].starter)
export const chapter = (index) => chapters[index] ?? null
export const chapterCount = () => chapters.length
export const item = (category, id) => items[category]?.[id] ?? {}
export const itemName = (category, id) => item(category, id).name ?? id
export const badge = (id) => badges.find((b) => b.id === id) ?? {}
export const npc = (id) => npcs.find((n) => n.id === id) ?? {}

export function categoryOf(itemId) {
  for (const category of Object.keys(items)) {
    if (items[category][itemId]) return category
  }
  return ''
}

export function defaultOwned() {
  const owned = []
  for (const category of Object.keys(items)) {
    for (const [id, entry] of Object.entries(items[category])) {
      if (entry.owned) owned.push(id)
    }
  }
  return owned
}
