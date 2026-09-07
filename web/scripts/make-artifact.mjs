// Turns the single-file production build into a page the Artifact host can
// publish: it supplies its own <!doctype>/<html>/<head>/<body> skeleton, so we
// hand it the title, styles and body content only.
import { readFileSync, writeFileSync } from 'node:fs'
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
const out = [`<title>${title}</title>`, ...styles, body.trim(), ...scripts].join('\n') + '\n' 
const target = path.join(distDir, 'artifact.html')
writeFileSync(target, out)
console.log(`wrote ${target} (${(out.length / 1024).toFixed(1)} kB)`)
