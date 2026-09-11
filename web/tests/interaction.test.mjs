// Plays the Sprint 1 loop in a real browser and checks the Definition of Done,
// step by step, in order.
//
//   npm run dev          (in web/)
//   npm test
import { chromium } from 'playwright'
import { existsSync, mkdirSync } from 'node:fs'

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
const step = (n, title) => console.log(`\n${n}. ${title}`)

// Playwright's own Chromium unless a prebuilt one is pointed at, so this runs
// on any machine.
const browserPath = process.env.CHROMIUM_PATH
const browser = await chromium.launch({
  ...(browserPath && existsSync(browserPath) ? { executablePath: browserPath } : {}),
  args: ['--no-sandbox'],
})
const page = await browser.newPage({ viewport: { width: 1440, height: 810 } })
const errors = []
const note = (message) => errors.push(message)
page.on('pageerror', (e) => note(String(e)))
page.on('console', (m) => { if (m.type() === 'error') note(`${m.text()} ${m.location?.().url ?? ''}`) })
page.on('requestfailed', (r) => note(`request failed: ${r.url()}`))

const save = () => page.evaluate(() => window.__littlepaws.game.save)
const decoded = (selector) => page.locator(selector).first()
  .evaluate((n) => n.complete && n.naturalWidth > 0)

// ---------------------------------------------------------------------------
step(1, 'Open the game')
await page.goto(URL, { waitUntil: 'networkidle' })
await page.evaluate(() => localStorage.clear())
await page.reload({ waitUntil: 'networkidle' })
check(await page.locator('#onboarding').isVisible(), 'the game opens on the naming screen')
await page.fill('#pet-name', 'Mochi')
await page.click('#begin')
await page.waitForSelector('#home-screen')

step(2, 'See my pet at Home')
check(await page.locator('#home-screen').isVisible(), 'Home renders')
check(await decoded('#pet-tap img'), 'the pet artwork decoded in the browser')
check((await page.locator('.name-tag').textContent()).includes('Mochi'),
  'the pet carries the name I typed')
check((await page.locator('.actions button').count()) === 3, 'Home offers exactly three actions')
check(await page.locator('#act-pet').isVisible()
  && await page.locator('#act-play').isVisible()
  && await page.locator('#act-explore').isVisible(), 'Pet, Play and Explore are all there')
await page.screenshot({ path: `${SHOTS}/01-home.png` })

step(3, 'Interact with my pet')
const heroBefore = await page.locator('#pet-tap img').getAttribute('src')
await page.click('#act-pet')
await page.waitForTimeout(250)
check(await page.locator('.toast.show').isVisible(), 'petting her says something back')
check((await page.locator('#pet-tap img').getAttribute('src')) !== heroBefore, 'and she visibly reacts')
check((await save()).pets === 1, 'the stroke was recorded')
check((await page.locator('.spark').count()) > 0, 'little hearts float up')
await page.waitForTimeout(2500)
check((await page.locator('#pet-tap img').getAttribute('src')) === heroBefore, 'then she settles back')

step(4, 'Play one mini-game')
await page.click('#act-play')
await page.waitForSelector('#play-field')
check(await page.locator('.chaser').isVisible(), 'my pet is in the mini-game')
check((await page.locator('.ribbon').count()) === 3, 'there are ribbons to chase')
const boxes = await page.locator('.ribbon').evaluateAll((nodes) => nodes.map((n) => {
  const r = n.getBoundingClientRect()
  return { left: r.left, right: r.right, top: r.top, bottom: r.bottom }
}))
const overlapping = boxes.some((a, i) => boxes.some((b, j) => i !== j
  && a.left < b.right && b.left < a.right && a.top < b.bottom && b.top < a.bottom))
check(!overlapping, 'and none of them overlap')
await page.screenshot({ path: `${SHOTS}/02-play.png` })

const chaserBefore = await page.locator('.chaser').getAttribute('style')
await page.locator('.ribbon').first().click()
await page.waitForTimeout(200)
check((await page.locator('.chaser').getAttribute('style')) !== chaserBefore,
  'my pet chases the ribbon I tapped')
for (let i = 0; i < 20 && !(await page.locator('#play-done').count()); i += 1) {
  const ribbon = page.locator('.ribbon').first()
  if (await ribbon.count()) { await ribbon.click(); await page.waitForTimeout(60) }
}
check(await page.locator('#play-done').isVisible(), 'the round ends on its own')

step(5, 'Receive a reward')
check((await save()).treat === true, 'the round leaves a treat for her')
await page.click('#play-home')
await page.waitForSelector('#home-screen')
check(await page.locator('#treat').isVisible(), 'the treat is waiting at Home')
await page.click('#treat')
await page.waitForTimeout(250)
check((await save()).treat === false, 'and she can be given it')
check(!(await page.locator('#treat').count()), 'the treat is gone once given')

step(6, 'Go to one exploration location')
await page.click('#act-explore')
await page.waitForSelector('#park-screen')
check(await page.locator('#park-screen').isVisible(), 'the park opens')
const backdrop = await page.locator('#scene').evaluate((n) => getComputedStyle(n).backgroundImage)
check(backdrop.includes('park') || backdrop.includes('data:image/'), 'and it looks like somewhere else')

step(7, 'Meet another pet')
check((await page.locator('.meeting figure').count()) === 2, 'two pets are on screen')
check(await decoded('.meeting img'), 'their artwork decoded')
check((await page.locator('#park-speech').textContent()).trim().length > 10, 'the game says who is there')
await page.screenshot({ path: `${SHOTS}/03-park.png` })

step(8, 'Make the two pets interact')
await page.click('#introduce')
await page.waitForTimeout(700)
check(await page.locator('#meeting.playing').isVisible(), 'the two pets play together')

step(9, 'See that they became friends')
await page.waitForSelector('#celebration', { timeout: 6000 })
check((await page.locator('#celebration').textContent()).includes('made a new friend'),
  'the game says they became friends')
check((await page.locator('#celebration .pair img').count()) === 2, 'and shows the pair')
check((await save()).friends.length === 1, 'the friendship is recorded')
await page.screenshot({ path: `${SHOTS}/04-friends.png` })
await page.click('#celebration-ok')
await page.waitForTimeout(300)
check(!(await page.locator('#celebration').count()), 'the moment can be dismissed')

step(10, 'Unlock one memory')
const memories = (await save()).memories
check(memories.length >= 2, 'a memory was written')
check(memories.some((m) => m.id.startsWith('friends-')), 'including one for the new friendship')
await page.click('#park-home')
await page.waitForSelector('#home-screen')
await page.click('#to-memories')
await page.waitForSelector('#memories-screen')
check((await page.locator('.memory').count()) === memories.length, 'and it is on the Memories screen')
await page.screenshot({ path: `${SHOTS}/05-memories.png` })

step(11, 'Return Home')
await page.click('#memories-home')
await page.waitForSelector('#home-screen')
check(await page.locator('#home-screen').isVisible(), 'Memories leads back Home')
await page.click('#to-pets')
await page.waitForSelector('#pets-screen')
check((await page.locator('.pet-card').count()) === 5, 'the collection shows five slots')
check((await page.locator('.pet-portrait.unknown').count()) === 3, 'three are still unknown')
await page.screenshot({ path: `${SHOTS}/06-pets.png` })
await page.click('#pets-home')
await page.waitForSelector('#home-screen')
check(await page.locator('#home-screen').isVisible(), 'Pets leads back Home')

step(12, 'Repeat the loop')
await page.click('#act-pet')
await page.waitForTimeout(200)
check((await save()).pets === 2, 'my pet can be petted again')
await page.click('#act-explore')
await page.waitForSelector('#park-screen')
check(await page.locator('#introduce').isEnabled(), 'the park offers a new pet to meet')
await page.click('#introduce')
await page.waitForSelector('#celebration', { timeout: 6000 })
check((await save()).friends.length === 2, 'a second pet can be befriended')
await page.click('#celebration-ok')
await page.waitForTimeout(300)

console.log('\n— and the things that must not be true —')
await page.click('#park-home')
await page.waitForSelector('#home-screen')
check(!(await page.locator('button:disabled').count()), 'no dead buttons on Home')
check(await page.evaluate(() => {
  const s = document.getElementById('stage')
  return s.scrollWidth <= s.clientWidth + 1 && s.scrollHeight <= s.clientHeight + 1
}), 'nothing overflows the 16:9 stage')
check(await page.evaluate(() => document.body.scrollHeight <= window.innerHeight),
  'the page never needs scrolling')

const before = await save()
await page.reload({ waitUntil: 'networkidle' })
await page.waitForSelector('#home-screen')
const after = await save()
check(after.petName === before.petName && after.friends.length === before.friends.length,
  'progress survives a reload')
check(errors.length === 0, `no console errors (saw: ${errors.slice(0, 3).join(' | ')})`)

console.log(`\n${passed + failed} checks, ${failed} failed`)
console.log(`screenshots: ${SHOTS}`)
await browser.close()
process.exit(failed > 0 ? 1 : 0)
