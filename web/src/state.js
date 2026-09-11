// The whole Sprint 1 save.
//
// Deliberately tiny: a name, who you have met, who is friends with whom, and a
// few memories. No stats, no currencies, no timers. Nothing here can be lost.
import { MY_PET, PETS, pet as petInfo, otherPets } from './content.js'

const SAVE_KEY = 'littlepaws.sprint1'

const emptySave = () => ({
  v: 1,
  petName: 'Mochi',
  discovered: [MY_PET],
  friends: [],
  memories: [],
  treat: false,
  pets: 0,
  plays: 0,
})

class Game extends EventTarget {
  constructor() {
    super()
    this.save = emptySave()
  }

  changed() { this.dispatchEvent(new CustomEvent('changed')) }
  say(text) { this.dispatchEvent(new CustomEvent('say', { detail: text })) }
  celebrate(detail) { this.dispatchEvent(new CustomEvent('celebrate', { detail })) }

  // --- persistence ------------------------------------------------------
  started() { return !!this.save.started }

  load() {
    try {
      const raw = localStorage.getItem(SAVE_KEY)
      if (!raw) return false
      const parsed = JSON.parse(raw)
      if (!parsed?.started) return false
      this.save = { ...emptySave(), ...parsed }
      return true
    } catch { return false }
  }

  persist() {
    try { localStorage.setItem(SAVE_KEY, JSON.stringify(this.save)) } catch { /* private mode */ }
  }

  reset() {
    try { localStorage.removeItem(SAVE_KEY) } catch { /* ignore */ }
    this.save = emptySave()
    this.changed()
  }

  begin(name) {
    this.save = { ...emptySave(), started: true, petName: name.trim() || 'Mochi' }
    this.addMemory('the-day-we-met', 'The day we met',
      `${this.petName()} came home and fell asleep on your lap.`, MY_PET)
    this.commit()
  }

  commit() { this.persist(); this.changed() }

  // --- my pet -----------------------------------------------------------
  petName() { return this.save.petName }
  myPet() { return { ...petInfo(MY_PET), name: this.petName() } }

  /** A stroke. Small, repeatable, and always welcome. */
  strokePet() {
    this.save.pets += 1
    this.say(STROKE_LINES[this.save.pets % STROKE_LINES.length].replace('%s', this.petName()))
    this.commit()
  }

  /** The mini-game finished. The reward is a treat, not a number. */
  finishPlay() {
    this.save.plays += 1
    this.save.treat = true
    if (this.save.plays === 1) {
      this.addMemory('our-first-game', 'Our first game',
        `${this.petName()} chased every ribbon in the room.`, MY_PET)
    }
    this.commit()
  }

  hasTreat() { return this.save.treat }

  giveTreat() {
    if (!this.save.treat) return false
    this.save.treat = false
    this.say(`${this.petName()} loved that.`)
    this.commit()
    return true
  }

  // --- meeting pets -----------------------------------------------------
  isDiscovered(id) { return this.save.discovered.includes(id) }
  isFriend(id) { return this.save.friends.includes(id) }
  discoveredCount() { return this.save.discovered.length }

  /** Who is waiting in the park: the first pet you have not befriended. */
  nextPet() { return otherPets().find((p) => !this.isFriend(p.id)) ?? null }

  /** The two pets play together, and that is that: strangers become friends. */
  makeFriends(id) {
    if (this.isFriend(id)) return false
    const them = petInfo(id)
    if (!this.isDiscovered(id)) this.save.discovered.push(id)
    this.save.friends.push(id)
    this.addMemory(`friends-${id}`, this.save.friends.length === 1 ? 'First playdate' : 'A new friend',
      `${this.petName()} and ${them.name} played until the sun went orange.`, id)
    this.celebrate({
      title: `${this.petName()} made a new friend!`,
      body: `${them.name} the ${them.kind.toLowerCase()} will be at the park whenever you visit.`,
      pets: [MY_PET, id],
    })
    this.commit()
    return true
  }

  // --- memories ---------------------------------------------------------
  addMemory(id, title, text, art) {
    if (this.save.memories.some((m) => m.id === id)) return
    this.save.memories.unshift({
      id, title, text, art,
      date: new Date().toLocaleDateString(undefined, { month: 'short', day: 'numeric' }),
    })
  }

  memories() { return this.save.memories }
}

const STROKE_LINES = [
  '%s leans into your hand.',
  '%s starts purring immediately.',
  '%s rolls over and shows you her tummy.',
  '%s closes both eyes and stays very still.',
  '%s headbutts your palm for more.',
]

export const game = new Game()
export { PETS, MY_PET, petInfo, otherPets }
