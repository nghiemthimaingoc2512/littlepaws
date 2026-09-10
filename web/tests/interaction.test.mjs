// Drives the running game in a real browser and asserts that it is actually
// interactive: buttons click, navigation works, care changes state, menus open
// and close, and progress is saved.
//
//   npm run dev            (in web/)
//   node tests/interaction.test.mjs
import { chromium } from 'playwright'
import { mkdirSync } from 'node:fs'

const URL = process.env.GAME_URL ?? 'http://localhost:5173/'
const SHOTS = process.env.SHOT_DIR ?? '/tmp/littlepaws-shots'
mkdirSync(SHOTS, { recursive: true })

let passed = 0
let failed = 0
const check = (ok, label) => {
  if (ok) { passed += 1; return }
  failed += 1
  console.error(`  FAIL  ${label}`)
}
const section = (title) => console.log(`\n== ${title}`)

const browser = await chromium.launch({
  executablePath: '/opt/pw-browsers/chromium-1194/chrome-linux/chrome',
  args: ['--no-sandbox'],
})
const page = await browser.newPage({ viewport: { width: 1440, height: 810 } })
// Art is optional: the game draws SVG when no PNG is installed, so a 404 on
// an art path is expected. Anything else is a real error.
const OPTIONAL_ART = /\/(pets|owner|bg)\/[^\s]*\.png/
const errors = []
const note = (message) => { if (!OPTIONAL_ART.test(message)) errors.push(message) }
page.on('pageerror', (e) => note(String(e)))
page.on('console', (m) => { if (m.type() === 'error') note(`${m.text()} ${m.location?.().url ?? ''}`) })
page.on('requestfailed', (r) => note(`request failed: ${r.url()}`))

/** Celebrations queue up and legitimately block the screen; clear them all. */
async function dismissModals() {
  const veil = page.locator('.modal-veil')
  for (let i = 0; i < 12 && (await veil.count()); i += 1) {
    await veil.first().getByRole('button', { name: 'Lovely' }).click()
    await page.waitForTimeout(180)
  }
}

const state = () => page.evaluate(() => {
  const g = window.__littlepaws.game
  if (!g.started()) return null
  return {
    coins: g.coins(), gems: g.gems(), hearts: g.hearts(),
    food: g.stat('food'), mood: g.stat('mood'), clean: g.stat('clean'),
    bond: g.bond(), xp: g.xp(), careTotal: g.counter('care_total'),
    pantry: g.foodCount(), rescued: g.rescuedCount(), owner: g.ownerName(),
    pet: g.petName(), level: g.playerLevel(), mail: g.mail().length,
  }
})

await page.goto(URL, { waitUntil: 'networkidle' })
await page.evaluate(() => localStorage.clear())
await page.reload({ waitUntil: 'networkidle' })

// --- onboarding ------------------------------------------------------------
section('onboarding')
check(await page.locator('#onboarding').isVisible(), 'onboarding screen renders')
await page.fill('#owner-name', 'Ngoc')
await page.getByRole('button', { name: 'Begin' }).click()
check(await page.locator('#pet-name').isVisible(), 'naming step appears after Begin')
await page.screenshot({ path: `${SHOTS}/01-onboarding.png` })
await page.fill('#pet-name', 'Mochi')
await page.getByRole('button', { name: 'I promise' }).click()
await page.waitForSelector('#home-screen')

const start = await state()
check(start !== null, 'a new game was created')
check(start.owner === 'Ngoc' && start.pet === 'Mochi', 'names were stored')

// --- home screen -----------------------------------------------------------
section('home screen')
check(await page.locator('#home-screen').isVisible(), 'home screen renders')
check(await page.locator('.player-card').isVisible(), 'player card renders')
check((await page.locator('.coin-pill').count()) === 3, 'three currency bars render')
check((await page.locator('.nav-item').count()) === 6, 'six navigation tabs render')
check((await page.locator('.rail-btn').count()) === 4, 'four left-rail shortcuts render')
check(!(await page.locator('.sign').count()), 'the decorative signboard is gone')
check(await page.locator('.todo').isVisible(), 'the To Do card renders')
const hero = page.locator('#pet-tap img')
check(await hero.isVisible(), 'the pet artwork is on screen')
// A normal build serves /art/...; the single-file artifact inlines the same
// bytes as a data URI. Both count as using the uploaded artwork.
const heroSrc = await hero.getAttribute('src')
check(heroSrc.startsWith('/art/') || heroSrc.startsWith('data:image/'),
  'the hero uses the uploaded artwork')
check(await hero.evaluate((n) => n.complete && n.naturalWidth > 0),
  'the hero image actually decoded in the browser')
const backdropImage = await page.locator('#backdrop').evaluate(
  (n) => getComputedStyle(n).backgroundImage)
check(backdropImage.includes('/art/bg/room') || backdropImage.includes('data:image/'),
  'the room backdrop is the uploaded background')
check(await page.locator('.player-card img').evaluate((n) => n.naturalWidth > 0),
  'the player portrait decoded')
await page.screenshot({ path: `${SHOTS}/02-home.png` })

// --- the care sheet opens and closes ---------------------------------------
section('menus open and close')
check(!(await page.locator('#care-sheet').count()), 'care sheet starts closed')
await page.click('#pet-tap')
await page.waitForSelector('#care-sheet')
check(await page.locator('#care-sheet').isVisible(), 'tapping the pet opens the care sheet')
check(await page.locator('#pet-stage.raised').isVisible(), 'the pet moves up so it stays visible')
await page.waitForTimeout(420)  // let the sheet finish sliding up
await page.screenshot({ path: `${SHOTS}/03-care.png` })
await page.click('#care-close')
await page.waitForSelector('#care-sheet', { state: 'detached' })
check(!(await page.locator('#care-sheet').count()), 'the close button closes it')

await page.click('#btn-play')
await page.waitForSelector('#care-sheet')
check(await page.locator('#care-sheet').isVisible(), "Let's Play! opens the care sheet")

// --- pet interaction changes state -----------------------------------------
section('pet interactions change state')
const beforeFeed = await state()
await page.click('#care-feed')
await page.waitForTimeout(250)
const afterFeed = await state()
check(afterFeed.food > beforeFeed.food, 'feeding raises the food meter')
check(afterFeed.pantry === beforeFeed.pantry - 1, 'feeding consumes one meal')
check(afterFeed.bond > beforeFeed.bond, 'feeding raises the bond')
check(afterFeed.xp > beforeFeed.xp, 'feeding grants growth XP')
check(afterFeed.careTotal === beforeFeed.careTotal + 1, 'the care counter went up')
check(await page.locator('.toast.show').isVisible(), 'a toast confirms the action')

check(await page.locator('#care-feed').isDisabled(), 'feeding goes on cooldown')
const meterWidth = await page.locator('.care-meters .meter-fill').first().evaluate((n) => n.style.width)
check(meterWidth !== '' && meterWidth !== '0%', 'the meter bar reflects the new value')

const beforePlay = await state()
await page.click('#care-play')
await page.waitForTimeout(250)
const afterPlay = await state()
check(afterPlay.mood > beforePlay.mood, 'playing raises the mood')
check(afterPlay.food < beforePlay.food, 'playing costs a little food')

// --- the To Do list is live -------------------------------------------------
section('daily list updates')
await page.click('#care-brush')
await page.waitForTimeout(200)
const ticks = await page.locator('.todo-row .tick.done').count()
check(ticks >= 2, 'the To Do card ticks off tasks as you play')
check(await page.locator('#claim-t_care').isVisible(), 'a finished task offers its reward')
const beforeClaim = await state()
await page.click('#claim-t_care')
await page.waitForTimeout(250)
check((await state()).coins > beforeClaim.coins, 'collecting a task pays coins')

// --- navigation -------------------------------------------------------------
section('navigation')
await dismissModals()
for (const [tab, selector] of [
  ['pets', '#pets-screen'], ['friends', '#friends-screen'], ['map', '#map-screen'],
  ['bag', '#bag-screen'], ['shop', '#shop-screen'], ['home', '#home-screen'],
]) {
  await page.click(`#nav-${tab}`)
  await page.waitForSelector(selector, { timeout: 4000 })
  check(await page.locator(selector).isVisible(), `the ${tab} tab opens its screen`)
}
for (const [rail, selector] of [
  ['daily', '#daily-screen'], ['missions', '#missions-screen'],
  ['activities', '#activities-screen'], ['shop', '#shop-screen'],
]) {
  await page.click('#nav-home')
  await page.waitForSelector('#home-screen')
  await page.click(`#rail-${rail}`)
  await page.waitForSelector(selector, { timeout: 4000 })
  check(await page.locator(selector).isVisible(), `the ${rail} shortcut opens its screen`)
}
await page.click('#nav-home'); await page.waitForSelector('#home-screen')
await page.click('.player-card'); await page.waitForSelector('#profile-screen')
check(await page.locator('#profile-screen').isVisible(), 'the player card opens the profile')

// --- shop: buying changes inventory and wallet ------------------------------
section('shop')
await dismissModals()
await page.click('#nav-shop')
await page.waitForSelector('#shop-screen')
const beforeBuy = await state()
await page.locator('#shop-fish_snack').getByRole('button').first().click()
await page.waitForTimeout(250)
const afterBuy = await state()
check(afterBuy.pantry === beforeBuy.pantry + 1, 'buying food adds it to the pantry')
check(afterBuy.coins < beforeBuy.coins, 'buying food costs coins')

await page.click('#tab-accessory')
await page.waitForTimeout(150)
check(await page.locator('#shop-acc_bow').isVisible(), 'shop tabs switch category')
await page.locator('#shop-acc_bow').getByRole('button').click()
await page.waitForTimeout(250)
check(await page.evaluate(() => window.__littlepaws.game.owns('acc_bow')), 'an accessory can be bought')
await page.locator('#shop-acc_bow').getByRole('button', { name: 'Wear' }).click()
await page.waitForTimeout(250)
check(await page.evaluate(() => window.__littlepaws.game.equipped('accessory') === 'acc_bow'),
  'a bought accessory can be worn')
await page.screenshot({ path: `${SHOTS}/04-shop.png` })

// --- the rescue mini-game ----------------------------------------------------
section('rescue mission')
await page.evaluate(() => { window.__littlepaws.game.save.chapter = 3; window.__littlepaws.game.persist() })
await page.click('#nav-home'); await page.waitForSelector('#home-screen')
await page.click('#rail-activities'); await page.waitForSelector('#activities-screen')
check((await page.getByRole('button', { name: 'Go find them' }).count()) > 0, 'a rescue chapter offers missions')
await page.getByRole('button', { name: 'Go find them' }).first().click()
await page.waitForSelector('#rescue-screen')
check(await page.locator('#rescue-screen').isVisible(), 'the rescue mission opens')
await page.screenshot({ path: `${SHOTS}/05-rescue.png` })

const beforeRescue = await state()
// Answer every round by trying each option; a wrong answer is harmless.
for (let guard = 0; guard < 60; guard += 1) {
  if (!(await page.locator('#rescue-screen').count())) break
  if (await page.getByRole('button', { name: /is safe/ }).count()) break
  const heading = await page.locator('#rescue-screen h2').first().textContent()
  const map = {
    'stomach growls': 'feed', 'looks away': 'play', 'dusty': 'bathe',
    'tangled': 'brush', 'drifting closed': 'sleep', 'favouring': 'heal',
  }
  const key = Object.keys(map).find((k) => heading.includes(k))
  if (!key) break
  await page.click(`#choice-${map[key]}`)
  await page.waitForTimeout(120)
  if (await page.locator('.modal-veil').count()) break
}
check((await state()).rescued > beforeRescue.rescued, 'completing the mission rescues the animal')
check(await page.locator('.modal-veil').isVisible(), 'a celebration modal appears')
await page.screenshot({ path: `${SHOTS}/06-rescued.png` })
await dismissModals()
check(!(await page.locator('.modal-veil').count()), 'the modal closes')

// --- taming and homing --------------------------------------------------------
section('sanctuary')
await dismissModals()
await page.click('#nav-friends')
await page.waitForSelector('#friends-screen')
check((await page.locator('.rail-btn, #friends-screen').count()) > 0, 'the sanctuary lists the rescue')
const beforeTame = await page.evaluate(() => {
  const g = window.__littlepaws.game
  return g.trust(g.sanctuaryIds()[0])
})
await page.click('#tame-tame_soothe')
await page.waitForTimeout(250)
const afterTame = await page.evaluate(() => {
  const g = window.__littlepaws.game
  return g.trust(g.sanctuaryIds()[0])
})
check(afterTame > beforeTame, 'soothing a rescue raises its trust')

await page.evaluate(() => {
  const g = window.__littlepaws.game
  g.save.library[g.sanctuaryIds()[0]].trust = 100
  g.emitChanged()
})
await page.waitForTimeout(200)
await page.click('#find-friend')
await page.waitForTimeout(250)
check((await page.getByRole('button', { name: 'They belong together' }).count()) === 3,
  'three people are offered')
check(await page.locator('#friends-screen img.art-friend').first().evaluate((n) => n.naturalWidth > 0),
  'the friend artwork decoded')
await page.screenshot({ path: `${SHOTS}/07-friends.png` })

const pair = await page.evaluate(() => {
  const g = window.__littlepaws.game
  const id = g.sanctuaryIds()[0]
  const right = g.destinedFriend(id)
  const wrong = g.friendCandidates(id).find((n) => n.id !== right).id
  return { id, right, wrong }
})
await page.locator(`#candidate-${pair.wrong}`).getByRole('button').click()
await page.waitForTimeout(300)
check(await page.evaluate(() => window.__littlepaws.game.homedCount() === 0),
  'the wrong person does not take the animal home')
check(await page.locator('.toast.show').isVisible(), 'and the game says so gently')
await page.locator(`#candidate-${pair.right}`).getByRole('button').click()
await page.waitForTimeout(300)
check(await page.evaluate(() => window.__littlepaws.game.homedCount() === 1),
  'the right person reunites with them')
await dismissModals()

// --- a casual activity ---------------------------------------------------------
section('mini-game')
await page.click('#nav-home'); await page.waitForSelector('#home-screen')
await page.click('#rail-activities'); await page.waitForSelector('#activities-screen')
check((await page.locator('.activity-grid .card').count()) >= 3, 'the Play hub offers activities')
await page.locator('#activity-bath').getByRole('button', { name: 'Start' }).click()
await page.waitForSelector('#play-field')
check((await page.locator('.target').count()) === 3, 'targets appear to tap')

const beforePlay2 = await state()
for (let i = 0; i < 40 && (await page.locator('.target').count()); i += 1) {
  await page.locator('.target').first().click()
  await page.waitForTimeout(40)
}
await page.waitForTimeout(300)
const afterPlay2 = await state()
check(afterPlay2.coins > beforePlay2.coins, 'finishing an activity pays coins')
check(afterPlay2.clean > beforePlay2.clean, 'a bath actually cleans your cat')
check(afterPlay2.careTotal > beforePlay2.careTotal, 'it counts as care')
await page.screenshot({ path: `${SHOTS}/09-minigame.png` })
await dismissModals()

// --- inbox --------------------------------------------------------------------
section('inbox')
await dismissModals()
await page.click('#nav-home'); await page.waitForSelector('#home-screen')
const unread = await page.evaluate(() => window.__littlepaws.game.unreadMail())
check(unread > 0, 'events wrote letters to the inbox')
check(await page.locator('.corner .dot').first().isVisible(), 'the inbox shows an unread badge')
await page.locator('.corner button').first().click()
await page.waitForSelector('#mail-screen')
check(await page.locator('#mail-screen').isVisible(), 'the inbox opens')
const claimable = await page.getByRole('button', { name: 'Collect' }).count()
check(claimable > 0, 'a gift is waiting')
const beforeGift = await state()
await page.getByRole('button', { name: 'Collect' }).first().click()
await page.waitForTimeout(250)
check((await state()).coins > beforeGift.coins, 'collecting a gift pays out')
await page.screenshot({ path: `${SHOTS}/08-mail.png` })

// --- persistence ----------------------------------------------------------------
section('saving')
await dismissModals()
const before = await state()
await page.reload({ waitUntil: 'networkidle' })
await page.waitForSelector('#home-screen')
const after = await state()
check(after.pet === before.pet, 'the pet survives a reload')
check(after.rescued === before.rescued, 'the library survives a reload')
check(Math.abs(after.coins - before.coins) < 400, 'the wallet survives a reload')
check(after.careTotal === before.careTotal, 'progress survives a reload')

// --- no console errors -----------------------------------------------------------
section('runtime health')
check(errors.length === 0, `no console errors (saw: ${errors.slice(0, 3).join(' | ')})`)

console.log(`\n${passed + failed} checks, ${failed} failed`)
console.log(`screenshots: ${SHOTS}`)
await browser.close()
process.exit(failed > 0 ? 1 : 0)
