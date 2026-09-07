import { defineConfig } from 'vite'
import { viteSingleFile } from 'vite-plugin-singlefile'
import path from 'node:path'

const repoRoot = path.resolve(import.meta.dirname, '..')

export default defineConfig(({ command }) => ({
  base: './',
  // The repo's /assets folder is served at the site root, so art dropped into
  // assets/pets/ragdoll.png is reachable at /pets/ragdoll.png with no config.
  publicDir: path.resolve(repoRoot, 'assets'),
  // The game content lives in /data at the repo root and is shared with the
  // Godot build, so the dev server needs to read one level up.
  server: { host: '0.0.0.0', port: 5173, fs: { allow: [repoRoot] } },
  // The production build is a single self-contained HTML file, so it can be
  // opened straight from disk or published anywhere static.
  plugins: command === 'build' ? [viteSingleFile()] : [],
  build: { outDir: 'dist', cssCodeSplit: false, assetsInlineLimit: 100_000_000 },
}))
