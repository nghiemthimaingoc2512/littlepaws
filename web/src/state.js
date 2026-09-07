// Every rule in Little Paws lives here, ported from the Godot build's
// GameState.gd so both targets behave identically.
//
// Design rule: nothing here can produce a loss. Stats decay toward a comfort
// floor, never to zero; missions can be retried forever; progress is only ever
// added.
import {
  Data, getSpecies, speciesName, chapter as dataChapter, chapterCount,
  item as dataItem, categoryOf, defaultOwned, npc as dataNpc, rescuableIds,
} from './data.js'

export const SAVE_KEY = 'littlepaws.save.v1'
export const SAVE_VERSION = 1

export const STAGES = ['Baby', 'Kid', 'Teen', 'Adult']
export const STAGE_XP = [0, 150, 500, 1200]
export const STAT_KEYS = ['food', 'clean', 'energy', 'mood', 'health']

/** Points lost per real-world hour. Gentle on purpose. */
const DECAY = { food: 10, clean: 6, energy: 8, mood: 5, health: 1.5 }
/** Stats never fall below this, so a pet is never in danger. */
export const COMFORT_FLOOR = 20
/** However long you are away, at most this much decay is applied. */
const MAX_OFFLINE_HOURS = 12

export const ACTIONS = {
  feed: {
    label: 'Feed', pose: 'eat', cooldown: 8, cost: 0, xp: 8, bond: 2, needsFood: true,
    stats: { food: 30, mood: 5 },
    line: '%s eats every last bite and looks up for more.',
  },
  play: {
    label: 'Play', pose: 'play', cooldown: 10, cost: 0, xp: 11, bond: 3,
    stats: { mood: 26, energy: -14, food: -8 },
    line: '%s chases the toy in circles until you both give up laughing.',
  },
  bathe: {
    label: 'Bath', pose: 'happy', cooldown: 25, cost: 15, xp: 9, bond: 2,
    stats: { clean: 44, mood: 4, energy: -6 },
    line: '%s is warm, fluffy and smells like soap.',
  },
  brush: {
    label: 'Brush', pose: 'crown', cooldown: 18, cost: 0, xp: 7, bond: 2,
    stats: { clean: 16, mood: 14 },
    line: '%s leans into the brush and closes both eyes.',
  },
  sleep: {
    label: 'Nap', pose: 'sleep', cooldown: 45, cost: 0, xp: 6, bond: 1,
    stats: { energy: 46, health: 6, mood: 4 },
    line: '%s curls into a small warm circle and drifts off.',
  },
  heal: {
    label: 'Vet', pose: 'curious', cooldown: 60, cost: 60, xp: 10, bond: 2,
    stats: { health: 40, mood: -4 },
    line: 'The vet says %s is in wonderful shape.',
  },
}

export const TAME_ACTIONS = {
  tame_feed: { label: 'Offer food', trust: 18, cooldown: 6, line: '%s edges closer and takes the food.' },
  tame_soothe: { label: 'Soothe', trust: 14, cooldown: 6, line: 'You sit very still. %s stops trembling.' },
  tame_play: { label: 'Play', trust: 16, cooldown: 6, line: '%s bats at the ribbon and forgets to be afraid.' },
}

export const DAILY_TASKS = [
  { id: 't_care', label: 'Pet care', track: 'care', target: 3, coins: 60 },
  { id: 't_play', label: 'Play time', track: 'play', target: 1, coins: 50 },
  { id: 't_decorate', label: 'Decorate', track: 'decorate', target: 1, coins: 50 },
  { id: 't_friends', label: 'Meet friends', track: 'friends', target: 1, coins: 60 },
  { id: 't_happy', label: 'Be happy!', track: 'happy', target: 1, coins: 80 },
]
export const DAILY_CLEAR_HEARTS = 1
export const DAILY_CLEAR_GEMS = 2

export const AD_REWARD_COINS = 60
export const AD_COOLDOWN_SEC = 90
export const AD_DAILY_LIMIT = 12

const now = () => Math.floor(Date.now() / 1000)
const today = () => new Date().toISOString().slice(0, 10)
const clamp = (v, lo, hi) => Math.min(hi, Math.max(lo, v))

// ---------------------------------------------------------------------------

class GameState extends EventTarget {
  constructor() {
    super()
    this.save = null
    this._tickTimer = null
  }

  // --- events ---------------------------------------------------------
  /** Something meaningful changed; screens rebuild. */
  emitChanged() { this.dispatchEvent(new CustomEvent('changed')) }
  /** The slow decay tick; meters update without a rebuild. */
  emitTicked() { this.dispatchEvent(new CustomEvent('ticked')) }
  toast(text) { this.dispatchEvent(new CustomEvent('toast', { detail: text })) }
  celebrate(title, body, icon) {
    this.dispatchEvent(new CustomEvent('celebrate', { detail: { title, body, icon } }))
  }
  posePet(pose) { this.dispatchEvent(new CustomEvent('pose', { detail: pose })) }

  // --- save / load ----------------------------------------------------
  hasSave() {
    try { return localStorage.getItem(SAVE_KEY) !== null } catch { return false }
  }

  load() {
    let raw = null
    try { raw = localStorage.getItem(SAVE_KEY) } catch { return false }
    if (!raw) return false
    let parsed
    try { parsed = JSON.parse(raw) } catch { return false }
    if (!parsed || typeof parsed !== 'object' || !parsed.pet) return false
    this.save = parsed
    this._migrate()
    this._applyOffline()
    this.dailyCheck()
    this.startClock()
    this.emitChanged()
    return true
  }

  persist() {
    if (!this.save) return
    this.save.last = now()
    try { localStorage.setItem(SAVE_KEY, JSON.stringify(this.save)) } catch { /* private mode */ }
  }

  deleteSave() {
    try { localStorage.removeItem(SAVE_KEY) } catch { /* ignore */ }
    this.save = null
    this.stopClock()
  }

  newGame(speciesId, petName, ownerName) {
    const stamp = now()
    this.save = {
      v: SAVE_VERSION,
      created: stamp,
      last: stamp,
      owner: { name: ownerName, outfit: 'outfit_default' },
      pet: {
        species: speciesId, name: petName, born: stamp, xp: 0, bond: 0,
        accessory: 'acc_none',
        stats: { food: 45, clean: 40, energy: 55, mood: 50, health: 92 },
      },
      wallet: { coins: 350, gems: 5, hearts: 3 },
      inventory: { fish_snack: 4, milk_bone: 4, seed_mix: 4 },
      owned: defaultOwned(),
      decor: 'decor_default',
      chapter: 0,
      goals: {},
      chaptersDone: [],
      counters: { care_total: 0, coins_earned: 0, ads: 0, player_xp: 0 },
      library: {},
      badges: {},
      daily: { date: today(), streak: 1 },
      ads: { date: today(), count: 0, last: 0 },
      cooldowns: {},
      tasks: { date: today(), progress: {}, claimed: [] },
      mail: [],
      seen: {},
    }
    this.persist()
    this.startClock()
    this.emitChanged()
  }

  _migrate() {
    const defaults = {
      v: SAVE_VERSION, goals: {}, chaptersDone: [], counters: {}, library: {},
      badges: {}, cooldowns: {}, inventory: {}, owned: defaultOwned(),
      decor: 'decor_default', chapter: 0,
      daily: { date: today(), streak: 1 },
      ads: { date: today(), count: 0, last: 0 },
      tasks: { date: today(), progress: {}, claimed: [] },
      mail: [], seen: {},
    }
    for (const [key, value] of Object.entries(defaults)) {
      if (this.save[key] === undefined) this.save[key] = value
    }
    if (this.save.wallet.hearts === undefined) this.save.wallet.hearts = 3
    for (const key of STAT_KEYS) {
      if (this.save.pet.stats[key] === undefined) this.save.pet.stats[key] = 70
    }
  }

  // --- clock ----------------------------------------------------------
  startClock() {
    this.stopClock()
    this._tickTimer = setInterval(() => {
      if (!this.started()) return
      this._decay(5 / 3600)
      this.save.last = now()
      this.emitTicked()
    }, 5000)
  }

  stopClock() {
    if (this._tickTimer) clearInterval(this._tickTimer)
    this._tickTimer = null
  }

  _decay(hours) {
    if (hours <= 0 || !this.save) return
    const stats = this.save.pet.stats
    for (const [key, rate] of Object.entries(DECAY)) {
      stats[key] = Math.max(COMFORT_FLOOR, (stats[key] ?? 70) - rate * hours)
    }
  }

  _applyOffline() {
    const away = (now() - (this.save.last ?? now())) / 3600
    this._decay(Math.min(away, MAX_OFFLINE_HOURS))
    this.save.last = now()
  }

  // --- accessors ------------------------------------------------------
  started() { return !!this.save?.pet }
  pet() { return this.save.pet }
  petName() { return this.save.pet.name }
  petSpecies() { return this.save.pet.species }
  ownerName() { return this.save.owner.name }
  coins() { return this.save.wallet.coins }
  gems() { return this.save.wallet.gems }
  hearts() { return this.save.wallet.hearts ?? 0 }
  stat(key) { return this.save.pet.stats[key] ?? 0 }
  bond() { return this.save.pet.bond }
  xp() { return this.save.pet.xp }
  counter(key) { return this.save.counters[key] ?? 0 }

  stage() {
    let current = 0
    STAGE_XP.forEach((need, i) => { if (this.xp() >= need) current = i })
    return current
  }
  stageName() { return STAGES[this.stage()] }
  stageProgress() {
    const s = this.stage()
    if (s >= STAGE_XP.length - 1) return 1
    return clamp((this.xp() - STAGE_XP[s]) / (STAGE_XP[s + 1] - STAGE_XP[s]), 0, 1)
  }

  wellbeing() {
    return STAT_KEYS.reduce((sum, key) => sum + this.stat(key), 0) / STAT_KEYS.length
  }

  moodPose() {
    if (this.stat('energy') < 35) return 'curl'
    if (this.wellbeing() >= 78) return 'happy'
    if (this.wellbeing() <= 45) return 'loaf'
    return 'idle'
  }

  playerXp() { return this.counter('player_xp') }

  playerLevelInfo() {
    let remaining = this.playerXp()
    let level = 1
    let need = 100
    while (remaining >= need && level < 99) {
      remaining -= need
      level += 1
      need = 100 + (level - 1) * 60
    }
    return { level, into: remaining, need }
  }

  playerLevel() { return this.playerLevelInfo().level }

  // --- cooldowns ------------------------------------------------------
  cooldownLeft(key) { return Math.max(0, (this.save.cooldowns[key] ?? 0) - now()) }
  onCooldown(key) { return this.cooldownLeft(key) > 0 }
  _startCooldown(key, seconds) { this.save.cooldowns[key] = now() + seconds }

  // --- care -----------------------------------------------------------
  foodCount() {
    return Object.entries(this.save.inventory)
      .filter(([id]) => categoryOf(id) === 'food')
      .reduce((sum, [, n]) => sum + n, 0)
  }

  firstFood() {
    const favorite = getSpecies(this.petSpecies()).favorite
    if ((this.save.inventory[favorite] ?? 0) > 0) return favorite
    for (const [id, n] of Object.entries(this.save.inventory)) {
      if (categoryOf(id) === 'food' && n > 0) return id
    }
    return ''
  }

  /** Why a care action cannot run right now, or '' if it can. */
  careBlockedReason(actionId) {
    const action = ACTIONS[actionId]
    if (!action) return 'Unknown action'
    if (this.onCooldown(actionId)) return 'In a moment…'
    if ((action.cost ?? 0) > this.coins()) return 'Not enough coins'
    if (action.needsFood && this.foodCount() <= 0) return 'No food left'

    // Blocked only when EVERY stat it would raise is already full, so a dirty
    // coat can still be brushed while the mood is high.
    let raisesSomething = false
    let allFull = true
    for (const [key, delta] of Object.entries(action.stats)) {
      if (delta <= 0) continue
      raisesSomething = true
      if (this.stat(key) < 98) allFull = false
    }
    if (raisesSomething && allFull) return `${this.petName()} does not need that right now`
    return ''
  }

  doCare(actionId) {
    const reason = this.careBlockedReason(actionId)
    if (reason) { this.toast(reason); return false }

    const action = ACTIONS[actionId]
    let bonus = 1
    if (action.needsFood) {
      const foodId = this.firstFood()
      this.save.inventory[foodId] -= 1
      if (this.save.inventory[foodId] <= 0) delete this.save.inventory[foodId]
      if (foodId === getSpecies(this.petSpecies()).favorite) bonus = 1.25
    }
    if (action.cost > 0) this._spend('coins', action.cost)

    const stats = this.save.pet.stats
    for (const [key, raw] of Object.entries(action.stats)) {
      const delta = raw > 0 ? raw * bonus : raw
      stats[key] = clamp((stats[key] ?? 70) + delta, COMFORT_FLOOR, 100)
    }

    const beforeStage = this.stage()
    this.save.pet.xp += Math.round(action.xp * bonus)
    this.save.pet.bond = clamp(this.bond() + action.bond, 0, 100)

    this._bump('care_total')
    this._bump(actionId)
    this._bump('player_xp', 5)
    this._taskBump('care')
    if (actionId === 'play') this._taskBump('play')
    this._advanceGoals('action', actionId)
    this._advanceGoals('care_total', '')

    this.posePet(action.pose)
    this.toast(action.line.replace('%s', this.petName()))

    if (this.stage() > beforeStage) {
      this.celebrate(`${this.petName()} grew up!`,
        `${this.petName()} is now a ${this.stageName()}. Look how far you have come together.`,
        'stage')
    }
    this._startCooldown(actionId, action.cooldown)
    this._afterChange()
    return true
  }

  // --- economy --------------------------------------------------------
  addCoins(n) { this.save.wallet.coins += n; if (n > 0) this._bump('coins_earned', n) }
  addGems(n) { this.save.wallet.gems += n }
  addHearts(n) { this.save.wallet.hearts = (this.save.wallet.hearts ?? 0) + n }
  _spend(kind, n) { this.save.wallet[kind] = Math.max(0, this.save.wallet[kind] - n) }

  canAfford(price, currency = 'coins') {
    if (currency === 'gems') return this.gems() >= price
    if (currency === 'hearts') return this.hearts() >= price
    return this.coins() >= price
  }

  owns(itemId) { return this.save.owned.includes(itemId) }

  buy(category, itemId) {
    const entry = dataItem(category, itemId)
    if (!entry.name || this.owns(itemId)) return false
    const price = entry.price ?? 0
    const currency = entry.currency ?? 'coins'
    if (!this.canAfford(price, currency)) { this.toast(`Not enough ${currency} yet.`); return false }
    this._spend(currency, price)
    this.save.owned.push(itemId)
    this.toast(`${entry.name} is yours.`)
    this._afterChange()
    return true
  }

  buyFood(itemId, count = 1) {
    const entry = dataItem('food', itemId)
    if (!entry.name) return false
    const price = (entry.price ?? 0) * count
    if (!this.canAfford(price)) { this.toast('Not enough coins yet.'); return false }
    this._spend('coins', price)
    this.save.inventory[itemId] = (this.save.inventory[itemId] ?? 0) + count
    this.toast(`${entry.name} x${count} added to the pantry.`)
    this._afterChange()
    return true
  }

  equip(itemId) {
    if (!this.owns(itemId)) return false
    const category = categoryOf(itemId)
    if (category === 'outfit') this.save.owner.outfit = itemId
    else if (category === 'accessory') this.save.pet.accessory = itemId
    else if (category === 'decor') this.save.decor = itemId
    else return false
    if (!['outfit_default', 'acc_none', 'decor_default'].includes(itemId)) {
      this._advanceGoals('equip', '')
      this._taskBump('decorate')
    }
    this._afterChange()
    return true
  }

  equipped(category) {
    if (category === 'outfit') return this.save.owner.outfit
    if (category === 'accessory') return this.save.pet.accessory
    if (category === 'decor') return this.save.decor
    return ''
  }

  // --- rewarded video -------------------------------------------------
  adAvailable() {
    const ads = this.save.ads
    if (ads.date !== today()) return true
    if (ads.count >= AD_DAILY_LIMIT) return false
    return now() - ads.last >= AD_COOLDOWN_SEC
  }
  adWaitSeconds() { return Math.max(0, AD_COOLDOWN_SEC - (now() - this.save.ads.last)) }
  adsLeftToday() {
    const ads = this.save.ads
    return ads.date !== today() ? AD_DAILY_LIMIT : Math.max(0, AD_DAILY_LIMIT - ads.count)
  }

  /** Called once a rewarded video finishes. See docs/MONETISATION.md. */
  grantAdReward(coinAmount = AD_REWARD_COINS, gemAmount = 0) {
    const ads = this.save.ads
    if (ads.date !== today()) { ads.date = today(); ads.count = 0 }
    ads.count += 1
    ads.last = now()
    this.addCoins(coinAmount)
    if (gemAmount > 0) this.addGems(gemAmount)
    this._bump('ads')
    this.toast(`Thanks for watching! +${coinAmount} coins`)
    this._afterChange()
  }

  // --- daily streak ---------------------------------------------------
  dailyCheck() {
    const daily = this.save.daily
    if (daily.date === today()) return
    const yesterday = new Date(Date.now() - 86400000).toISOString().slice(0, 10)
    daily.streak = daily.date === yesterday ? daily.streak + 1 : 1
    daily.date = today()
    const coinReward = 40 + Math.min(daily.streak, 7) * 15
    this.addCoins(coinReward)
    let gemReward = 0
    if (daily.streak % 7 === 0) { gemReward = 5; this.addGems(gemReward) }
    this.celebrate(`Day ${daily.streak} together`,
      `Welcome back. +${coinReward} coins${gemReward ? ` and +${gemReward} gems` : ''}`, 'daily')
    this._afterChange()
  }

  streak() { return this.save.daily.streak }

  // --- chapters & goals -----------------------------------------------
  chapterIndex() { return this.save.chapter }
  currentChapter() { return dataChapter(this.chapterIndex()) }
  chaptersDone() { return this.save.chaptersDone.length }
  chapterCleared(id) { return this.save.chaptersDone.includes(id) }
  goalTarget(goal) { return Math.max(1, goal.target ?? 1) }

  goalProgress(goal) {
    switch (goal.type) {
      case 'bond': return this.bond()
      case 'stage': return this.stage()
      case 'homed': return this.homedCount()
      case 'rescue': return this.isRescued(goal.key) ? 1 : 0
      default: return this.save.goals[goal.id] ?? 0
    }
  }

  goalDone(goal) { return this.goalProgress(goal) >= this.goalTarget(goal) }

  _advanceGoals(type, key) {
    const chapter = this.currentChapter()
    if (!chapter) return
    for (const goal of chapter.goals) {
      if (goal.type !== type) continue
      if (type === 'action' && goal.key !== key) continue
      const target = this.goalTarget(goal)
      this.save.goals[goal.id] = Math.min((this.save.goals[goal.id] ?? 0) + 1, target)
    }
  }

  _checkChapter() {
    const chapter = this.currentChapter()
    if (!chapter) return
    if (!chapter.goals.every((goal) => this.goalDone(goal))) return
    if (this.chapterCleared(chapter.id)) return

    this.save.chaptersDone.push(chapter.id)
    const reward = chapter.reward ?? {}
    this.addCoins(reward.coins ?? 0)
    this.addGems(reward.gems ?? 0)
    this._bump('player_xp', 120)
    this.save.chapter += 1
    this.pushMail(`${chapter.title} complete`,
      'A new part of the world just opened up.', { coins: 0 }, true)
    this.celebrate(`${chapter.title} complete`,
      `+${reward.coins ?? 0} coins, +${reward.gems ?? 0} gems. A new part of the world just opened up.`,
      'chapter')
  }

  // --- rescue, taming, homing -----------------------------------------
  library() { return this.save.library }
  isRescued(id) { return !!this.save.library[id] }
  entry(id) { return this.save.library[id] ?? {} }
  trust(id) { return this.entry(id).trust ?? 0 }
  isTamed(id) { return this.trust(id) >= 100 }
  isHomed(id) { return !!this.entry(id).friend }
  rescuedCount() { return Object.keys(this.save.library).length }
  homedCount() { return Object.keys(this.save.library).filter((id) => this.isHomed(id)).length }
  sanctuaryIds() { return Object.keys(this.save.library).filter((id) => !this.isHomed(id)) }

  rescue(id) {
    if (this.isRescued(id)) return false
    this.save.library[id] = { rescued: now(), trust: 0, friend: '', homedAt: 0 }
    this._advanceGoals('rescue', id)
    this._bump('player_xp', 40)
    this.pushMail(`${speciesName(id)} is safe`,
      'They are resting in the sanctuary. Sit with them when you can.', {}, true)
    this.celebrate(`${speciesName(id)} is safe!`,
      'They are shy for now. Care for them in the Sanctuary until they trust you.', 'rescue')
    this._afterChange()
    return true
  }

  tameBlockedReason(id, actionId) {
    if (!this.isRescued(id)) return 'Not rescued yet'
    if (this.isTamed(id)) return 'Already fully tamed'
    if (this.onCooldown(`${id}:${actionId}`)) return 'In a moment…'
    if (actionId === 'tame_feed' && this.foodCount() <= 0) return 'No food left'
    return ''
  }

  doTame(id, actionId) {
    const reason = this.tameBlockedReason(id, actionId)
    if (reason) { this.toast(reason); return false }
    const action = TAME_ACTIONS[actionId]
    if (actionId === 'tame_feed') {
      const foodId = this.firstFood()
      this.save.inventory[foodId] -= 1
      if (this.save.inventory[foodId] <= 0) delete this.save.inventory[foodId]
    }
    const record = this.save.library[id]
    const before = record.trust
    record.trust = Math.min(100, before + action.trust)
    this._bump('care_total')
    this._bump('player_xp', 8)
    this._taskBump('friends')
    this._advanceGoals('care_total', '')
    this._startCooldown(`${id}:${actionId}`, action.cooldown)
    this.toast(action.line.replace('%s', speciesName(id)))
    if (before < 100 && record.trust >= 100) {
      this.celebrate(`${speciesName(id)} trusts you`,
        'They are ready to meet the person they will spend their life with.', 'tame')
    }
    this._afterChange()
    return true
  }

  /** Three candidates, chosen deterministically so the offer is stable. */
  friendCandidates(id) {
    let seed = 0
    for (const ch of id) seed += ch.charCodeAt(0)
    const pool = [...Data.npcs]
    const picked = []
    let cursor = seed
    while (picked.length < Math.min(3, pool.length)) {
      cursor = (cursor * 1103515245 + 12345) & 0x7fffffff
      const candidate = pool[cursor % pool.length]
      if (!picked.includes(candidate)) picked.push(candidate)
    }
    return picked
  }

  matchScore(speciesId, npcId) {
    const traits = getSpecies(speciesId).traits ?? []
    const likes = dataNpc(npcId).likes ?? []
    if (!traits.length || !likes.length) return 0.5
    const shared = traits.filter((t) => likes.includes(t)).length
    return clamp(0.4 + 0.3 * shared, 0, 1)
  }

  homeAnimal(speciesId, npcId) {
    if (!this.isTamed(speciesId) || this.isHomed(speciesId)) return false
    const record = this.save.library[speciesId]
    record.friend = npcId
    record.homedAt = now()
    const score = this.matchScore(speciesId, npcId)
    const gemReward = 3 + Math.round(score * 4)
    const coinReward = 120 + Math.round(score * 120)
    this.addGems(gemReward)
    this.addCoins(coinReward)
    this.addHearts(1)
    this._bump('player_xp', 60)
    this._advanceGoals('homed', '')
    this.pushMail(`A thank-you note from ${dataNpc(npcId).name}`,
      `${speciesName(speciesId)} settled in on the first night. I do not know how to thank you.`,
      { coins: 80 }, false)
    this.celebrate('A forever home',
      `${speciesName(speciesId)} is going home with ${dataNpc(npcId).name}. +${coinReward} coins, +${gemReward} gems`,
      'home')
    this._afterChange()
    return true
  }

  // --- daily to-do list -----------------------------------------------
  _ensureToday() {
    const tasks = this.save.tasks
    if (tasks.date === today()) return
    tasks.date = today()
    tasks.progress = {}
    tasks.claimed = []
  }

  _taskBump(track, amount = 1) {
    this._ensureToday()
    const progress = this.save.tasks.progress
    progress[track] = (progress[track] ?? 0) + amount
  }

  taskTarget(task) { return Math.max(1, task.target ?? 1) }

  taskProgress(task) {
    this._ensureToday()
    // Measured live: this one is about how your pet is doing right now.
    if (task.track === 'happy') return this.wellbeing() >= 80 ? 1 : 0
    return Math.min(this.save.tasks.progress[task.track] ?? 0, this.taskTarget(task))
  }

  taskDone(task) { return this.taskProgress(task) >= this.taskTarget(task) }
  taskClaimed(task) { this._ensureToday(); return this.save.tasks.claimed.includes(task.id) }
  taskClaimable(task) { return this.taskDone(task) && !this.taskClaimed(task) }
  anyTaskClaimable() { return DAILY_TASKS.some((task) => this.taskClaimable(task)) }
  tasksDoneToday() { return DAILY_TASKS.filter((task) => this.taskDone(task)).length }

  claimTask(taskId) {
    const task = DAILY_TASKS.find((t) => t.id === taskId)
    if (!task || !this.taskClaimable(task)) return false
    this.save.tasks.claimed.push(taskId)
    this.addCoins(task.coins)
    this.toast(`${task.label} done. +${task.coins} coins`)
    if (this.save.tasks.claimed.length >= DAILY_TASKS.length) {
      this.addHearts(DAILY_CLEAR_HEARTS)
      this.addGems(DAILY_CLEAR_GEMS)
      this.pushMail('A perfect day',
        `You finished everything on today's list. ${this.petName()} noticed.`,
        { hearts: DAILY_CLEAR_HEARTS, gems: DAILY_CLEAR_GEMS }, true)
      this.celebrate('Everything done',
        `The whole list is ticked off. +${DAILY_CLEAR_HEARTS} heart, +${DAILY_CLEAR_GEMS} gems`, 'daily')
    }
    this._afterChange()
    return true
  }

  // --- mail -----------------------------------------------------------
  pushMail(title, body, reward = {}, alreadyPaid = false) {
    const inbox = this.save.mail
    inbox.unshift({
      id: `m${now()}_${inbox.length}_${Math.floor(Math.random() * 1000)}`,
      title, body, at: now(), read: false, reward,
      claimed: alreadyPaid || Object.keys(reward).length === 0,
    })
    while (inbox.length > 40) inbox.pop()
  }

  mail() { return this.save.mail }
  unreadMail() { return this.save.mail.filter((m) => !m.read).length }
  claimableMail() { return this.save.mail.filter((m) => !m.claimed).length }
  readAllMail() { this.save.mail.forEach((m) => { m.read = true }); this._afterChange() }

  claimMail(mailId) {
    const letter = this.save.mail.find((m) => m.id === mailId)
    if (!letter || letter.claimed) return false
    const reward = letter.reward ?? {}
    this.addCoins(reward.coins ?? 0)
    this.addGems(reward.gems ?? 0)
    this.addHearts(reward.hearts ?? 0)
    letter.claimed = true
    letter.read = true
    this.toast('Gift collected.')
    this._afterChange()
    return true
  }

  // --- "new since you last looked" dots --------------------------------
  /**
   * Records that a screen was opened. Deliberately does NOT emit `changed`:
   * the caller is a screen that is mid-build, and re-rendering it here would
   * call this again forever. The dot clears on the next render.
   */
  markSeen(key) { this.save.seen[key] = now(); this.persist() }
  _seenAt(key) { return this.save.seen[key] ?? 0 }

  missionsHaveNews() {
    const last = this._seenAt('missions')
    return Object.values(this.save.badges).some((at) => at > last)
  }
  friendsHaveNews() { return this.sanctuaryIds().some((id) => this.isTamed(id)) }
  eventsHaveNews() { return this.availableMissions().length > 0 }

  availableMissions() {
    const chapter = this.currentChapter()
    if (!chapter) return []
    return chapter.goals.filter((g) => g.type === 'rescue' && !this.goalDone(g)).map((g) => g.key)
  }

  // --- badges ---------------------------------------------------------
  hasBadge(id) { return !!this.save.badges[id] }

  badgeProgress(badge) {
    switch (badge.type) {
      case 'chapter': return this.chaptersDone()
      case 'stage': return this.stage()
      case 'bond': return this.bond()
      case 'care_total': return this.counter('care_total')
      case 'rescued': return this.rescuedCount()
      case 'homed': return this.homedCount()
      case 'cosmetics': return Math.max(0, this.save.owned.length - defaultOwned().length)
      case 'streak': return this.streak()
      default: return 0
    }
  }

  _checkBadges() {
    for (const badge of Data.badges) {
      if (this.hasBadge(badge.id)) continue
      if (this.badgeProgress(badge) < (badge.target ?? 1)) continue
      this.save.badges[badge.id] = now()
      this.addGems(badge.gems ?? 0)
      this._bump('player_xp', 25)
      this.pushMail(`Badge earned: ${badge.name}`, badge.text, { gems: badge.gems ?? 0 }, true)
      this.celebrate(`Badge earned: ${badge.name}`,
        `${badge.text}  +${badge.gems ?? 0} gems`, 'badge')
    }
  }

  badgesEarned() { return Object.keys(this.save.badges).length }

  // --- plumbing -------------------------------------------------------
  _bump(key, amount = 1) {
    this.save.counters[key] = (this.save.counters[key] ?? 0) + amount
  }

  _afterChange() {
    this._ensureToday()
    this._checkChapter()
    this._checkBadges()
    this.persist()
    this.emitChanged()
  }
}

export const game = new GameState()
export { rescuableIds }
