// Turns the single-file production build into a page the Artifact host can
// publish: it supplies its own <!doctype>/<html>/<head>/<body> skeleton, so we
// hand it the title, styles and body content only.
import { existsSync, readFileSync, writeFileSync } from 'node:fs'
import path from 'node:path'

const distDir = path.resolve(import.meta.dirname, '..', 'dist')
const html = readFileSync(path.join(distDir, 'index.html'), 'utf8')

const pick = (re, label) => {
  const match = html.match(re)
  if (!match) throw new Error(`make-artifact: could not find ${label} in the build`)
  return match
}

const title = pick(/<title>([\s\S]*?)<\/title>/, 'the title')[1]
// vite-plugin-singlefile inlines both the stylesheet and the module script
// into <head>; the body is left holding only the mount point.
const styles = [...html.matchAll(/<style[^>]*>[\s\S]*?<\/style>/g)].map((m) => m[0])
const scripts = [...html.matchAll(/<script[^>]*>[\s\S]*?<\/script>/g)].map((m) => m[0])
const body = pick(/<body[^>]*>([\s\S]*)<\/body>/, 'the body')[1]

if (!styles.length) throw new Error('make-artifact: no inlined stylesheet — did vite-plugin-singlefile run?')
if (!scripts.length) throw new Error('make-artifact: no inlined script — did vite-plugin-singlefile run?')

// Mount point first, script last, so the game boots against a ready DOM.
let out = [`<title>${title}</title>`, ...styles, body.trim(), ...scripts].join('\n') + '\n'

// Artwork lives in web/public and is copied beside the bundle by a normal
// build, but an artifact is a single file: inline every piece it references.
const MIME = { '.png': 'image/png', '.jpg': 'image/jpeg', '.jpeg': 'image/jpeg',
  '.webp': 'image/webp', '.svg': 'image/svg+xml' }
const publicDir = path.resolve(import.meta.dirname, '..', 'public')
const referenced = [...new Set(out.match(/\/art\/[\w/.-]+?\.(?:png|jpe?g|webp|svg)/g) ?? [])]
let inlined = 0
for (const url of referenced) {
  const file = path.join(publicDir, url.replace(/^\//, ''))
  if (!existsSync(file)) {
    console.warn(`make-artifact: referenced but missing — ${url}`)
    continue
  }
  const mime = MIME[path.extname(file).toLowerCase()] ?? 'application/octet-stream'
  const data = `data:${mime};base64,${readFileSync(file).toString('base64')}`
  out = out.split(url).join(data)
  inlined += 1
}
if (inlined !== referenced.length) {
  throw new Error(`make-artifact: ${referenced.length - inlined} artwork files could not be inlined`)
}
console.log(`inlined ${inlined} artwork files`)
const target = path.join(distDir, 'artifact.html')
writeFileSync(target, out)
console.log(`wrote ${target} (${(out.length / 1024).toFixed(1)} kB)`)
