#!/usr/bin/env node
// Writes the meta.json of each guide section whose pages are listed A–Z, from the pages
// present, so units adding pages in parallel never edit a shared list. Kolay reads meta.json to
// order a section's pages and fails the build if the list misses one, so these files are build
// output: they are gitignored, and docs-app's Vite config regenerates them on every build, test
// run and dev server start. See "Generated files" in CONTRIBUTING.md.
//
//   node scripts/gen-guide-meta.mjs     regenerates them alone
//
// A section's index.md (its overview) needs no entry: Kolay always puts it first. The sections
// read in a fixed order (Getting started, and the sections themselves in app/templates/meta.json)
// keep hand-written meta.json files.

import { existsSync, readFileSync, readdirSync, writeFileSync } from 'node:fs'
import { dirname, join, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'

/** The guide sections listed A–Z, like ui.shadcn.com's components. */
export const ALPHABETICAL_SECTIONS = [
  'components',
  'primitives',
  'charts',
  'blocks',
  'formwright',
  'reference',
]

const PAGE_EXTENSIONS = ['.gjs.md', '.gts.md', '.md']

const repoRoot = resolve(dirname(fileURLToPath(import.meta.url)), '..')
export const TEMPLATES_DIR = join(repoRoot, 'docs-app', 'app', 'templates')

/** `alert-dialog.md` → `alert-dialog`; anything that isn't a page → undefined. */
export function pageName(file) {
  const ext = PAGE_EXTENSIONS.find(e => file.endsWith(e))
  return ext ? file.slice(0, -ext.length) : undefined
}

/** The pages and sub-folders of a section, A–Z, without its index page. */
export function sectionOrder(dir) {
  const names = new Set()
  for (const entry of readdirSync(dir, { withFileTypes: true })) {
    if (entry.name.startsWith('.') || entry.name.startsWith('_')) continue
    const name = entry.isDirectory() ? entry.name : pageName(entry.name)
    if (name && name !== 'index') names.add(name)
  }
  return [...names].sort((a, b) => (a < b ? -1 : a > b ? 1 : 0))
}

export function metaFor(dir) {
  return `${JSON.stringify({ order: sectionOrder(dir) }, null, 2)}\n`
}

/**
 * Writes `<section>/meta.json` for each alphabetical section that exists under `templatesDir`,
 * touching only the files whose contents change (so a dev server's watcher stays quiet).
 * Returns the paths it wrote.
 */
export function writeGuideMeta({
  templatesDir = TEMPLATES_DIR,
  sections = ALPHABETICAL_SECTIONS,
} = {}) {
  const written = []
  for (const section of sections) {
    const dir = join(templatesDir, section)
    if (!existsSync(dir)) continue
    const file = join(dir, 'meta.json')
    const contents = metaFor(dir)
    if (existsSync(file) && readFileSync(file, 'utf8') === contents) continue
    writeFileSync(file, contents)
    written.push(file)
  }
  return written
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  for (const file of writeGuideMeta()) console.log(`wrote ${file}`)
}
