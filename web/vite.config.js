import { defineConfig } from 'vite'
import { viteSingleFile } from 'vite-plugin-singlefile'

export default defineConfig(({ command }) => ({
  base: './',
  // web/public holds the processed artwork (tools/prepare_art.py builds it from
  // the originals in /assets), served at /art/... in dev and copied beside the
  // bundle in a build.
  publicDir: 'public',
  server: { host: '0.0.0.0', port: 5173 },
  // The production build is a single self-contained HTML file.
  plugins: command === 'build' ? [viteSingleFile()] : [],
  build: { outDir: 'dist', cssCodeSplit: false, assetsInlineLimit: 100_000_000 },
}))
