#!/usr/bin/env node
/* global document, requestAnimationFrame -- the page functions run in the browser */
// `pnpm parity`: screenshots each mapped upstream example in shadcn/ui's own rendering (the
// reference app in parity/) and in Joinery's (the guide's `/parity/<name>` route), in light and
// dark, and compares them pixel by pixel. See "Parity" in CONTRIBUTING.md.
//
//   pnpm parity                           every example mapped in parity/map/*.json
//   pnpm parity --only button,card-demo   just these components or upstream example ids (each must
//                                         name something mapped)
//   pnpm parity --require-complete        also fail when an upstream example isn't mapped
//
// Before a run: `node scripts/upstream.mjs fetch`, `pnpm --dir parity install`, `pnpm build` and
// `pnpm guide:build`. The script builds the reference app itself (for the examples it compares)
// unless --no-build is given; `--reference-url` and `--joinery-url` point it at servers that are
// already running instead. With nothing mapped it has nothing to compare, and passes without
// needing any of that.
//
// Each comparison loads both pages at the same fixed viewport, with the same fonts (the parity
// app's @fontsource packages, served by a server of this script's own on every run, so they load
// whichever servers the pages come from, and injected into both pages; a font that doesn't load
// is an error, not a fallback), every image on the page loaded (or failed) first, animations and
// transitions off, and `prefers-reduced-motion`.
// The diff is measured over the content's bounding box (everything on either page that isn't
// the background; see "Comparing screenshots" below), and a diff over the example's threshold
// (1% of the box's pixels unless its map entry sets one, with a reason) fails. The HTML report,
// with the compared areas and their diff side by side, goes to parity-report/.
//
// The browser is playwright-core's own Chromium build (`pnpm exec playwright-core install
// chromium`, as CI does, or one preinstalled under PLAYWRIGHT_BROWSERS_PATH for the same
// version). PARITY_CHROMIUM points it at another Chromium binary instead; the screenshots then
// differ from CI's, so use it only to look at a comparison, not to set thresholds.

import { spawnSync } from 'node:child_process'
import { createServer } from 'node:http'
import {
  existsSync,
  mkdirSync,
  readFileSync,
  readdirSync,
  rmSync,
  statSync,
  writeFileSync,
} from 'node:fs'
import { basename, dirname, extname, join, normalize, resolve, sep } from 'node:path'
import { fileURLToPath } from 'node:url'

export const repoRoot = resolve(dirname(fileURLToPath(import.meta.url)), '..')
export const MAP_DIR = 'parity/map'
export const REPORT_DIR = 'parity-report'
export const DEFAULT_THRESHOLD = 0.01
/**
 * pixelmatch's per-pixel colour tolerance (its default is 0.1). At 0.03 two colours match when
 * they are within about 8 levels of grey of each other, so the smallest step in shadcn's
 * neutral theme still registers: white against `--muted` (#f5f5f5, 10 levels) or `--border`
 * (#e5e5e5), and the dark background against its 10%-white border. pixelmatch at 0.1 treats
 * all of those as equal, which hides every border, separator, input outline and muted fill.
 */
export const PIXEL_TOLERANCE = 0.03
export const VIEWPORT = { width: 1280, height: 800 }
export const THEMES = ['light', 'dark']
/** Where the Joinery guide is served from, as `pnpm guide:build` builds it. */
export const GUIDE_BASE = '/ember-joinery/guide/'

// ---------------------------------------------------------------------------------------------
// The map: parity/map/<component>.json

/**
 * Every upstream id `--require-complete` expects a mapping for, with the component (docs page)
 * that owns it: each docs page's examples and the charts gallery. Joinery ports a subset of the
 * blocks, so blocks can be mapped but are never required.
 */
export function requiredIds(inventory) {
  const ids = Object.entries(inventory.examples).map(([id, example]) => ({
    id,
    component: example.page,
  }))
  for (const chart of inventory.charts) ids.push({ id: chart.name, component: 'chart' })
  return ids
}

/** The components (map file names) an upstream id may be mapped under, or null if unknown. */
function componentsFor(id, inventory) {
  if (inventory.examples[id]) return inventory.examples[id].pages
  if (inventory.charts.some(chart => chart.name === id)) return ['chart']
  if (inventory.blocks.some(block => block.name === id)) return ['blocks']
  return null
}

/**
 * The direction and alignment an upstream id is shown with on its docs page, and its style when
 * that isn't Nova (the Code Block and chat pages show theirs in Rhea). The reference app renders
 * each example in its page's style already; the guide's route needs `?style=` to match.
 */
export function layoutFor(id, inventory) {
  const example = inventory.examples[id]
  if (example) {
    const layout = { dir: example.direction ?? 'ltr', align: example.align ?? 'center' }
    if (example.style && example.style !== 'nova') layout.style = example.style
    return layout
  }
  return {
    dir: 'ltr',
    align: inventory.blocks.some(block => block.name === id) ? 'start' : 'center',
  }
}

const ENTRY_KEYS = new Set(['example', 'threshold', 'reason', 'skip'])

/**
 * Checks one map file's JSON and returns its entries. A value is the Joinery example's name, or
 * `{ example, threshold?, reason? }`, or `{ skip: reason }` for an example that can't be compared
 * (it still counts as mapped). A threshold needs a reason.
 */
export function validateMapFile(component, json, inventory) {
  const errors = []
  const entries = []
  const where = `${MAP_DIR}/${component}.json`
  if (!json || typeof json !== 'object' || Array.isArray(json)) {
    return { entries, errors: [`${where}: expected an object with "examples"`] }
  }
  for (const key of Object.keys(json)) {
    if (key !== 'examples' && key !== '$comment') errors.push(`${where}: unknown key "${key}"`)
  }
  const examples = json.examples ?? {}
  if (typeof examples !== 'object' || Array.isArray(examples)) {
    return { entries, errors: [...errors, `${where}: "examples" must be an object`] }
  }
  for (const [id, value] of Object.entries(examples)) {
    const owners = componentsFor(id, inventory)
    if (!owners) {
      errors.push(`${where}: "${id}" is not an upstream example`)
      continue
    }
    if (!owners.includes(component)) {
      errors.push(
        `${where}: "${id}" belongs in ${owners.map(o => `${MAP_DIR}/${o}.json`).join(' or ')}`,
      )
      continue
    }
    const entry = typeof value === 'string' ? { example: value } : value
    if (!entry || typeof entry !== 'object' || Array.isArray(entry)) {
      errors.push(`${where}: "${id}" must map to an example name or an object`)
      continue
    }
    const unknown = Object.keys(entry).filter(key => !ENTRY_KEYS.has(key))
    if (unknown.length) errors.push(`${where}: "${id}" has unknown keys: ${unknown.join(', ')}`)
    if (entry.skip !== undefined) {
      if (typeof entry.skip !== 'string' || !entry.skip.trim()) {
        errors.push(`${where}: "${id}": "skip" must be the reason, as a sentence`)
      }
      entries.push({ id, component, skip: entry.skip })
      continue
    }
    if (typeof entry.example !== 'string' || !/^[a-z0-9][a-z0-9-]*$/.test(entry.example)) {
      errors.push(
        `${where}: "${id}": "example" must be a guide example's name (docs-app/app/examples)`,
      )
      continue
    }
    if (entry.threshold !== undefined) {
      if (typeof entry.threshold !== 'number' || !(entry.threshold > 0 && entry.threshold < 1)) {
        errors.push(`${where}: "${id}": "threshold" is a fraction of the pixels, between 0 and 1`)
      }
      if (typeof entry.reason !== 'string' || !entry.reason.trim()) {
        errors.push(`${where}: "${id}": a threshold needs a "reason"`)
      }
    } else if (entry.reason !== undefined) {
      errors.push(`${where}: "${id}": "reason" explains a threshold, and there is none`)
    }
    entries.push({
      id,
      component,
      example: entry.example,
      threshold: entry.threshold ?? DEFAULT_THRESHOLD,
      ...(entry.reason && { reason: entry.reason }),
    })
  }
  return { entries, errors }
}

/** Every map file, validated: their entries, and the errors across all of them. */
export function loadMaps(inventory, { root = repoRoot } = {}) {
  const dir = join(root, MAP_DIR)
  const entries = []
  const errors = []
  const components = new Set([...Object.keys(inventory.pages), 'chart', 'blocks'])
  const files = existsSync(dir)
    ? readdirSync(dir)
        .filter(name => name.endsWith('.json'))
        .sort()
    : []
  for (const file of files) {
    const component = basename(file, '.json')
    if (!components.has(component)) {
      errors.push(`${MAP_DIR}/${file}: there is no upstream docs page "${component}"`)
      continue
    }
    let json
    try {
      json = JSON.parse(readFileSync(join(dir, file), 'utf8'))
    } catch (error) {
      errors.push(`${MAP_DIR}/${file}: ${error.message}`)
      continue
    }
    const result = validateMapFile(component, json, inventory)
    entries.push(...result.entries)
    errors.push(...result.errors)
  }
  const seen = new Map()
  for (const entry of entries) {
    if (seen.has(entry.id)) {
      errors.push(
        `"${entry.id}" is mapped in both ${seen.get(entry.id)}.json and ${entry.component}.json`,
      )
    } else {
      seen.set(entry.id, entry.component)
    }
  }
  return { entries, errors }
}

/** The upstream ids `--require-complete` would fail on, by component. */
export function unmapped(inventory, entries) {
  const mapped = new Set(entries.map(entry => entry.id))
  const missing = {}
  for (const { id, component } of requiredIds(inventory)) {
    if (!mapped.has(id)) (missing[component] ??= []).push(id)
  }
  return missing
}

/**
 * `--only a,b`: the entries whose id or component is listed. A value that names nothing mapped
 * throws, saying whether it is unmapped or unknown, so a typo can't pass by comparing nothing.
 */
export function selectEntries(entries, only, inventory) {
  if (only === undefined) return entries
  const wanted = [
    ...new Set(
      only
        .split(',')
        .map(value => value.trim())
        .filter(Boolean),
    ),
  ]
  if (!wanted.length) throw new Error('--only names no component or upstream example')
  const named = value => entries.some(entry => entry.id === value || entry.component === value)
  const unmatched = wanted.filter(value => !named(value))
  if (unmatched.length) {
    const known = value =>
      Boolean(inventory?.pages?.[value]) ||
      value === 'chart' ||
      value === 'blocks' ||
      (inventory ? componentsFor(value, inventory) !== null : false)
    const reasons = unmatched.map(value =>
      known(value)
        ? `"${value}" has nothing mapped in ${MAP_DIR}/ yet`
        : `there is no upstream example or docs page named "${value}"`,
    )
    throw new Error(`--only: ${reasons.join('; ')}`)
  }
  return entries.filter(entry => wanted.includes(entry.id) || wanted.includes(entry.component))
}

// ---------------------------------------------------------------------------------------------
// Comparing screenshots
//
// Most of a parity page is the stage's background, the same on both sides, so a ratio over the
// whole page says nothing: an empty stage would score well under 1% against most examples.
// The ratio is taken over the content's bounding box instead: the smallest box holding every
// pixel, on either side, that isn't the page's background. The per-pixel tolerance is low
// enough that a 1px `--border` line and a `--muted` fill register (both are a few per cent off
// the background), while pixelmatch's anti-aliasing check still keeps text edges out of the count.

/** A copy of `png` on a `width`×`height` canvas; the added area is magenta, so it always differs. */
export function padPng(PNG, png, width, height) {
  if (png.width === width && png.height === height) return png
  const out = new PNG({ width, height })
  for (let i = 0; i < out.data.length; i += 4) out.data.set([255, 0, 255, 255], i)
  PNG.bitblt(png, out, 0, 0, png.width, png.height, 0, 0)
  return out
}

/** The colour most of an image's edge pixels have, as RGBA: the page's background. */
export function backgroundOf(png) {
  const { width, height, data } = png
  const counts = new Map()
  const count = (x, y) => {
    const value = data.readUInt32BE((y * width + x) * 4)
    counts.set(value, (counts.get(value) ?? 0) + 1)
  }
  for (let x = 0; x < width; x++) {
    count(x, 0)
    count(x, height - 1)
  }
  for (let y = 1; y < height - 1; y++) {
    count(0, y)
    count(width - 1, y)
  }
  let best = 0
  let most = -1
  for (const [value, n] of counts) {
    if (n > most) [best, most] = [value, n]
  }
  return [best >>> 24, (best >>> 16) & 255, (best >>> 8) & 255, best & 255]
}

const hex = rgba =>
  `#${rgba
    .slice(0, 3)
    .map(c => c.toString(16).padStart(2, '0'))
    .join('')}`

/** A `width`×`height` image of one colour. */
function solid(PNG, width, height, rgba) {
  const png = new PNG({ width, height })
  for (let i = 0; i < png.data.length; i += 4) png.data.set(rgba, i)
  return png
}

/**
 * The smallest box holding every pixel of `png` that differs from `background` by more than
 * `tolerance` (pixelmatch's colour distance, anti-aliased pixels included), or null if none does.
 */
function contentBox(PNG, pixelmatch, png, background, tolerance) {
  const { width, height } = png
  const mask = new PNG({ width, height })
  const plain = solid(PNG, width, height, background)
  pixelmatch(png.data, plain.data, mask.data, width, height, {
    threshold: tolerance,
    includeAA: true,
    diffMask: true,
  })
  let [left, top, right, bottom] = [width, height, -1, -1]
  for (let y = 0; y < height; y++) {
    for (let x = 0; x < width; x++) {
      if (!mask.data[(y * width + x) * 4 + 3]) continue
      if (x < left) left = x
      if (x > right) right = x
      if (y < top) top = y
      bottom = y
    }
  }
  return right < 0 ? null : { x: left, y: top, width: right - left + 1, height: bottom - top + 1 }
}

function unionBox(a, b) {
  if (!a || !b) return a ?? b
  const x = Math.min(a.x, b.x)
  const y = Math.min(a.y, b.y)
  return {
    x,
    y,
    width: Math.max(a.x + a.width, b.x + b.width) - x,
    height: Math.max(a.y + a.height, b.y + b.height) - y,
  }
}

function crop(PNG, png, box) {
  const out = new PNG({ width: box.width, height: box.height })
  PNG.bitblt(png, out, box.x, box.y, box.width, box.height, 0, 0)
  return out
}

/**
 * Compares two PNG buffers over the content's bounding box: the union of the boxes holding each
 * side's non-background pixels. Different sizes are compared on the larger canvas, and the
 * extra area counts as content that differs. When the two backgrounds differ, the whole canvas
 * is compared instead, so a wrong page colour fails. Returns the diff ratio (differing pixels
 * over the box's), the box, and the box's three images (upstream, joinery, diff). With nothing
 * but background on either side, `blank` is true and there is nothing to compare.
 */
export async function comparePngs(upstream, joinery, { tolerance = PIXEL_TOLERANCE } = {}) {
  const { PNG } = await import('pngjs')
  const { default: pixelmatch } = await import('pixelmatch')
  const a = PNG.sync.read(upstream)
  const b = PNG.sync.read(joinery)
  const width = Math.max(a.width, b.width)
  const height = Math.max(a.height, b.height)
  const paddedA = padPng(PNG, a, width, height)
  const paddedB = padPng(PNG, b, width, height)
  const backgrounds = { upstream: backgroundOf(a), joinery: backgroundOf(b) }
  const sameBackground =
    pixelmatch(
      solid(PNG, 1, 1, backgrounds.upstream).data,
      solid(PNG, 1, 1, backgrounds.joinery).data,
      null,
      1,
      1,
      { threshold: tolerance, includeAA: true },
    ) === 0
  const box = sameBackground
    ? unionBox(
        contentBox(PNG, pixelmatch, paddedA, backgrounds.upstream, tolerance),
        contentBox(PNG, pixelmatch, paddedB, backgrounds.joinery, tolerance),
      )
    : { x: 0, y: 0, width, height }
  const result = {
    width,
    height,
    sizes: { upstream: [a.width, a.height], joinery: [b.width, b.height] },
    backgrounds: { upstream: hex(backgrounds.upstream), joinery: hex(backgrounds.joinery) },
    box,
  }
  if (!box) return { ...result, blank: true, diffPixels: 0, ratio: 0 }
  const areaA = crop(PNG, paddedA, box)
  const areaB = crop(PNG, paddedB, box)
  const diff = new PNG({ width: box.width, height: box.height })
  const diffPixels = pixelmatch(areaA.data, areaB.data, diff.data, box.width, box.height, {
    threshold: tolerance,
  })
  return {
    ...result,
    blank: false,
    diffPixels,
    ratio: diffPixels / (box.width * box.height),
    areas: { upstream: PNG.sync.write(areaA), joinery: PNG.sync.write(areaB) },
    diff: PNG.sync.write(diff),
  }
}

/** Whether a comparison passes its entry's threshold. */
export function passes(ratio, threshold = DEFAULT_THRESHOLD) {
  return ratio <= threshold
}

// ---------------------------------------------------------------------------------------------
// The report

const ESCAPES = { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }
const escapeHtml = value => String(value).replace(/[&<>"']/g, char => ESCAPES[char])
const percent = ratio => `${(ratio * 100).toFixed(2)}%`

const boxSize = box => `${box.width}×${box.height}`

function figure(src, caption, full) {
  if (!src) return `<figure><figcaption>${caption}: none</figcaption></figure>`
  const link = full ? ` (<a href="${escapeHtml(full)}">full page</a>)` : ''
  return `<figure><img src="${escapeHtml(src)}" alt="${caption}" loading="lazy"><figcaption>${caption}${link}</figcaption></figure>`
}

function reportRow(result) {
  const images = result.images ?? {}
  // A comparison shows the area it compared, each linking to its whole page; an error shows
  // whichever whole pages it got.
  const figures = result.box
    ? [
        figure(images.upstreamBox, 'upstream', images.upstream),
        figure(images.joineryBox, 'joinery', images.joinery),
        figure(images.diff, 'diff'),
      ]
    : [
        figure(images.upstream, 'upstream'),
        figure(images.joinery, 'joinery'),
        figure(undefined, 'diff'),
      ]
  const backgrounds =
    result.backgrounds && result.backgrounds.upstream !== result.backgrounds.joinery
      ? ` The backgrounds differ (upstream ${escapeHtml(result.backgrounds.upstream)}, Joinery ${escapeHtml(result.backgrounds.joinery)}).`
      : ''
  const detail = result.error
    ? `<p class="error">${escapeHtml(result.error)}</p>`
    : `<p>${percent(result.ratio)} of the ${boxSize(result.box)} content box differs (at ${result.box.x}, ${result.box.y}); threshold ${percent(result.threshold)}${
        result.reason ? ` (${escapeHtml(result.reason)})` : ''
      }.${backgrounds}</p>`
  const title = `${escapeHtml(result.id)} <small>${escapeHtml(result.theme)} · ${escapeHtml(result.component)} → ${escapeHtml(result.example)}</small>`
  return `<section class="${result.status}" id="${escapeHtml(`${result.id}-${result.theme}`)}">
  <h2><span class="status">${result.status}</span> ${title}</h2>
  ${detail}
  <div class="images">${figures.join('')}</div>
</section>`
}

/** The side-by-side HTML report. Image paths are relative to the report folder. */
export function renderReport(results, { commit, skipped = [], missing = {} } = {}) {
  const passed = results.filter(result => result.status === 'pass').length
  const missingList = Object.entries(missing)
    .map(
      ([component, ids]) =>
        `<li><strong>${escapeHtml(component)}</strong>: ${ids.map(escapeHtml).join(', ')}</li>`,
    )
    .join('')
  const skippedList = skipped
    .map(entry => `<li>${escapeHtml(entry.id)}: ${escapeHtml(entry.skip)}</li>`)
    .join('')
  return `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Joinery parity report</title>
<style>
  :root { color-scheme: light dark; font: 14px/1.5 system-ui, sans-serif; }
  body { margin: 2rem; }
  section { border-top: 1px solid #8884; padding: 1rem 0; }
  h2 { font-size: 1rem; margin: 0 0 0.25rem; }
  small { font-weight: normal; opacity: 0.7; }
  .status { display: inline-block; min-width: 3.5em; padding: 0 0.4em; border-radius: 4px; font-size: 0.8rem; text-transform: uppercase; }
  .pass .status { background: #1a7f37; color: white; }
  .fail .status, .error .status { background: #cf222e; color: white; }
  .images { display: grid; grid-template-columns: repeat(3, 1fr); gap: 0.75rem; }
  figure { margin: 0; }
  img { max-width: 100%; border: 1px solid #8884; }
  p.error { color: #cf222e; white-space: pre-wrap; }
</style>
</head>
<body>
<h1>Joinery parity report</h1>
<p>shadcn-ui/ui ${escapeHtml(commit ? commit.slice(0, 7) : 'unknown')}: ${passed} of ${results.length} comparisons pass${
    skipped.length ? `; ${skipped.length} mapped examples are skipped` : ''
  }.</p>
${missingList ? `<details><summary>Not mapped yet</summary><ul>${missingList}</ul></details>` : ''}
${skippedList ? `<details><summary>Skipped</summary><ul>${skippedList}</ul></details>` : ''}
${results.map(reportRow).join('\n')}
</body>
</html>
`
}

// ---------------------------------------------------------------------------------------------
// Pages, servers and the browser

/** The faces both pages load, each with a string to load it for (Arabic and Hebrew for RTL). */
export const FONTS = [
  { name: 'geist', family: 'Geist Variable', text: 'a' },
  { name: 'geist-mono', family: 'Geist Mono Variable', text: 'a' },
  { name: 'noto-sans-arabic', family: 'Noto Sans Arabic Variable', text: 'ع' },
  { name: 'noto-sans-hebrew', family: 'Noto Sans Hebrew Variable', text: 'א' },
]

/**
 * The CSS both pages get before a screenshot: the same fonts (from the font server at
 * `fontsUrl`), no motion, a fixed scheme.
 */
export function injectedCss(theme, fontsUrl = '', fonts = FONTS) {
  const origin = fontsUrl.replace(/\/$/, '')
  return `${fonts.map(font => `@import url('${origin}/__parity/fonts/${font.name}/index.css');`).join('\n')}
:root {
  --font-sans: 'Geist Variable', sans-serif !important;
  --font-heading: 'Geist Variable', sans-serif !important;
  --font-mono: 'Geist Mono Variable', monospace !important;
  --font-ar: 'Noto Sans Arabic Variable', 'Geist Variable', sans-serif !important;
  --font-he: 'Noto Sans Hebrew Variable', 'Geist Variable', sans-serif !important;
  color-scheme: ${theme} !important;
}
[data-parity] { font-family: var(--font-sans) !important; }
[data-parity][dir='rtl'] { font-family: var(--font-ar) !important; }
*, *::before, *::after {
  animation-duration: 0s !important;
  animation-delay: 0s !important;
  transition-duration: 0s !important;
  transition-delay: 0s !important;
  caret-color: transparent !important;
}
`
}

/** The two URLs one comparison screenshots. */
export function pageUrls({ referenceUrl, joineryUrl, entry, theme, layout }) {
  const query = new URLSearchParams({ theme, dir: layout.dir, align: layout.align }).toString()
  const style = layout.style ? `&${new URLSearchParams({ style: layout.style })}` : ''
  return {
    upstream: `${referenceUrl.replace(/\/$/, '')}/${encodeURIComponent(entry.id)}?${query}`,
    joinery: `${joineryUrl.replace(/\/$/, '')}/parity/${encodeURIComponent(entry.example)}?${query}${style}`,
  }
}

const TYPES = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'text/javascript',
  '.mjs': 'text/javascript',
  '.css': 'text/css',
  '.json': 'application/json',
  '.svg': 'image/svg+xml',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.webp': 'image/webp',
  '.woff2': 'font/woff2',
  '.woff': 'font/woff',
  '.ico': 'image/x-icon',
  '.wasm': 'application/wasm',
}

/**
 * A static file server. `mounts` maps URL prefixes to folders; a path with no file falls back
 * to the mount's `fallback` (an app's index.html), as a SPA host does. Listens on a free port.
 */
export function staticServer(mounts) {
  const sorted = [...mounts].sort((a, b) => b.prefix.length - a.prefix.length)
  const server = createServer((request, response) => {
    const path = decodeURIComponent(new URL(request.url, 'http://localhost').pathname)
    const mount = sorted.find(
      m => path === m.prefix.replace(/\/$/, '') || path.startsWith(m.prefix),
    )
    if (!mount) {
      response.writeHead(404).end('not found')
      return
    }
    const root = resolve(mount.dir)
    let file = resolve(root, normalize(path.slice(mount.prefix.length)).replace(/^[/\\]+/, ''))
    if (file !== root && !file.startsWith(root + sep)) {
      response.writeHead(403).end('forbidden')
      return
    }
    if (existsSync(file) && statSync(file).isDirectory()) file = join(file, 'index.html')
    if (!existsSync(file)) {
      if (!mount.fallback) {
        response.writeHead(404).end('not found')
        return
      }
      file = mount.fallback
    }
    response.writeHead(200, {
      'content-type': TYPES[extname(file)] ?? 'application/octet-stream',
      'cache-control': 'no-store',
      // The font server serves pages on other origins, and fonts need CORS.
      'access-control-allow-origin': '*',
    })
    response.end(readFileSync(file))
  })
  return new Promise(done => server.listen(0, '127.0.0.1', () => done(server)))
}

const urlOf = (server, path = '/') => `http://127.0.0.1:${server.address().port}${path}`

/** The fonts both pages load, from the parity app's @fontsource packages. */
export function fontMounts(root = repoRoot, fonts = FONTS) {
  const packages = join(root, 'parity', 'node_modules', '@fontsource-variable')
  const mounts = fonts.map(font => ({
    prefix: `/__parity/fonts/${font.name}/`,
    dir: join(packages, font.name),
  }))
  const missing = mounts.filter(mount => !existsSync(join(mount.dir, 'index.css')))
  if (missing.length) {
    throw new Error(
      `the parity fonts are missing (${missing.map(m => basename(m.dir)).join(', ')}); run \`pnpm --dir parity install\``,
    )
  }
  return mounts
}

function run(command, args, options = {}) {
  const result = spawnSync(command, args, { stdio: 'inherit', cwd: repoRoot, ...options })
  if (result.status !== 0) throw new Error(`${command} ${args.join(' ')} failed`)
}

/** The reference app is ready when it says so; Joinery's when its stage is there. */
const referenceReady = () => document.documentElement.dataset.parityReady !== undefined
const joineryReady = () => Boolean(document.querySelector('[data-parity], [data-parity-missing]'))

/** How long a page's images may take to load, in milliseconds. */
export const IMAGE_TIMEOUT = 30_000

/**
 * Runs in the page: waits until every `<img>` has loaded (or failed) and been decoded, and
 * returns those still loading after `timeout`. An example's images start loading only when the
 * app renders it, after the page's load event, and neither app waits for them before it says
 * it's ready, so without this a screenshot could catch one side with its image and the other
 * without. A lazy image is made eager, since a full-page screenshot shows it. One that fails to
 * load counts as settled: the browser draws it broken on both sides alike.
 */
function settleImages(timeout) {
  const images = [...document.images]
  for (const image of images) if (image.loading === 'lazy') image.loading = 'eager'
  const settled = image =>
    (image.complete
      ? Promise.resolve()
      : new Promise(done => {
          image.addEventListener('load', done, { once: true })
          image.addEventListener('error', done, { once: true })
        })
    ).then(() => image.decode().catch(() => {}))
  const late = new Promise(done => setTimeout(done, timeout))
  return Promise.race([Promise.all(images.map(settled)), late]).then(() =>
    images.filter(image => !image.complete).map(image => image.currentSrc || image.src),
  )
}

/** Opens a page, waits until it has rendered, and screenshots it. */
async function screenshot(context, url, { theme, ready, fontsUrl, fonts }) {
  const page = await context.newPage()
  const errors = []
  page.on('pageerror', error => errors.push(error.message))
  try {
    await page.goto(url, { waitUntil: 'load', timeout: 60_000 })
    await page.waitForFunction(ready, null, { timeout: 30_000 })
    const failed = await page.$('[data-parity-missing], [data-parity-error]')
    if (failed)
      throw new Error((await failed.textContent())?.trim() || 'the page reported an error')
    await page.addStyleTag({ content: injectedCss(theme, fontsUrl, fonts) })
    const loading = await page.evaluate(settleImages, IMAGE_TIMEOUT)
    if (loading.length) throw new Error(`these images didn't finish loading: ${loading.join(', ')}`)
    const unloaded = await page.evaluate(async fonts => {
      // The injected faces load on use; load them now so the screenshot never catches a fallback.
      // A face that fails to load rejects without saying which, so each is caught on its own.
      const faces = await Promise.all(
        fonts.map(font =>
          document.fonts.load(`400 16px "${font.family}"`, font.text).catch(() => []),
        ),
      )
      await document.fonts.ready
      await new Promise(done => requestAnimationFrame(() => requestAnimationFrame(done)))
      return fonts.filter((_font, index) => !faces[index].length).map(font => font.family)
    }, fonts)
    if (unloaded.length) throw new Error(`these fonts didn't load: ${unloaded.join(', ')}`)
    return await page.screenshot({ fullPage: true, animations: 'disabled', caret: 'hide' })
  } catch (error) {
    throw new Error(`${url}: ${error.message}${errors.length ? `\n${errors.join('\n')}` : ''}`, {
      cause: error,
    })
  } finally {
    await page.close()
  }
}

export function parseArgs(argv) {
  const options = { requireComplete: false, build: true, themes: THEMES }
  for (let i = 0; i < argv.length; i++) {
    const arg = argv[i]
    const value = () => {
      const next = argv[++i]
      if (next === undefined) throw new Error(`${arg} needs a value`)
      return next
    }
    if (arg === '--require-complete') options.requireComplete = true
    else if (arg === '--no-build') options.build = false
    else if (arg === '--only') options.only = value()
    else if (arg === '--report') options.report = value()
    else if (arg === '--reference-url') options.referenceUrl = value()
    else if (arg === '--joinery-url') options.joineryUrl = value()
    else if (arg === '--themes') options.themes = value().split(',')
    else throw new Error(`unknown option ${arg}`)
  }
  for (const theme of options.themes) {
    if (!THEMES.includes(theme)) throw new Error(`unknown theme ${theme}`)
  }
  return options
}

async function startReference(options, compared, log, root) {
  if (!existsSync(join(root, 'parity', 'node_modules'))) {
    throw new Error('parity/node_modules is missing; run `pnpm --dir parity install`')
  }
  if (options.build) {
    log(`parity: building the reference app for ${compared.length} examples`)
    run('pnpm', ['--dir', 'parity', 'run', 'build'], {
      cwd: root,
      env: {
        ...process.env,
        PARITY_EXAMPLES: compared.map(entry => entry.id).join(','),
        PARITY_QUIET: '1',
      },
    })
  }
  const dist = join(root, 'parity', 'dist')
  if (!existsSync(join(dist, 'index.html')))
    throw new Error('parity/dist is missing; run without --no-build')
  return staticServer([{ prefix: '/', dir: dist, fallback: join(dist, 'index.html') }])
}

async function startJoinery(root) {
  const site = join(root, 'docs', 'site')
  const guide = join(site, 'guide')
  if (!existsSync(join(guide, 'index.html'))) {
    throw new Error('docs/site/guide is missing; run `pnpm build && pnpm guide:build`')
  }
  return staticServer([
    { prefix: GUIDE_BASE, dir: guide, fallback: join(guide, 'index.html') },
    { prefix: '/ember-joinery/', dir: site },
  ])
}

/**
 * The whole run. Returns the process exit code. `fonts` replaces the faces both pages load
 * (the script's own tests use it; a real run loads FONTS).
 */
export async function parity(options, { log = console.log, root = repoRoot, fonts = FONTS } = {}) {
  const inventory = JSON.parse(readFileSync(join(root, 'upstream', 'inventory.json'), 'utf8'))
  const { entries, errors } = loadMaps(inventory, { root })
  if (errors.length) {
    log(`parity: the map has errors:\n  ${errors.join('\n  ')}`)
    return 1
  }
  const missing = unmapped(inventory, entries)
  const missingCount = Object.values(missing).reduce((sum, ids) => sum + ids.length, 0)
  let code = 0
  if (options.requireComplete && missingCount) {
    log(`parity: ${missingCount} upstream examples aren't mapped (--require-complete):`)
    for (const [component, ids] of Object.entries(missing)) log(`  ${component}: ${ids.join(', ')}`)
    code = 1
  }

  let selected
  try {
    selected = selectEntries(entries, options.only, inventory)
  } catch (error) {
    log(`parity: ${error.message}`)
    return 1
  }
  const skipped = selected.filter(entry => entry.skip)
  const compared = selected.filter(entry => !entry.skip)
  if (!compared.length) {
    const total = requiredIds(inventory).length
    log(
      `parity: nothing to compare (${entries.length} mapped; ${missingCount} of ${total} upstream examples unmapped).`,
    )
    return code
  }

  const servers = []
  let browser
  try {
    // The fonts come from a server of their own, whichever servers the pages come from.
    const fontServer = await staticServer(fontMounts(root, fonts))
    servers.push(fontServer)
    const fontsUrl = urlOf(fontServer, '')
    let referenceUrl = options.referenceUrl
    if (!referenceUrl) {
      const server = await startReference(options, compared, log, root)
      servers.push(server)
      referenceUrl = urlOf(server)
    }
    let joineryUrl = options.joineryUrl
    if (!joineryUrl) {
      const server = await startJoinery(root)
      servers.push(server)
      joineryUrl = urlOf(server, GUIDE_BASE)
    }

    const { chromium } = await import('playwright-core')
    browser = await chromium.launch({
      executablePath: process.env.PARITY_CHROMIUM || undefined,
      args: ['--font-render-hinting=none', '--disable-lcd-text', '--force-color-profile=srgb'],
    })

    const reportDir = resolve(root, options.report ?? REPORT_DIR)
    rmSync(reportDir, { recursive: true, force: true })
    mkdirSync(join(reportDir, 'images'), { recursive: true })
    const results = []
    for (const theme of options.themes) {
      const context = await browser.newContext({
        viewport: VIEWPORT,
        deviceScaleFactor: 1,
        colorScheme: theme,
        reducedMotion: 'reduce',
        locale: 'en-US',
        timezoneId: 'UTC',
      })
      for (const entry of compared) {
        const urls = pageUrls({
          referenceUrl,
          joineryUrl,
          entry,
          theme,
          layout: layoutFor(entry.id, inventory),
        })
        const base = {
          id: entry.id,
          component: entry.component,
          example: entry.example,
          theme,
          threshold: entry.threshold,
          ...(entry.reason && { reason: entry.reason }),
        }
        const file = kind => `images/${entry.id}-${theme}-${kind}.png`
        try {
          const upstream = await screenshot(context, urls.upstream, {
            theme,
            ready: referenceReady,
            fontsUrl,
            fonts,
          })
          writeFileSync(join(reportDir, file('upstream')), upstream)
          const joinery = await screenshot(context, urls.joinery, {
            theme,
            ready: joineryReady,
            fontsUrl,
            fonts,
          })
          writeFileSync(join(reportDir, file('joinery')), joinery)
          const comparison = await comparePngs(upstream, joinery)
          if (comparison.blank) {
            throw new Error(
              `neither page shows anything but its background (${comparison.backgrounds.upstream}), so there is nothing to compare`,
            )
          }
          writeFileSync(join(reportDir, file('upstream-box')), comparison.areas.upstream)
          writeFileSync(join(reportDir, file('joinery-box')), comparison.areas.joinery)
          writeFileSync(join(reportDir, file('diff')), comparison.diff)
          const status = passes(comparison.ratio, entry.threshold) ? 'pass' : 'fail'
          results.push({
            ...base,
            status,
            ratio: comparison.ratio,
            box: comparison.box,
            sizes: comparison.sizes,
            backgrounds: comparison.backgrounds,
            images: {
              upstream: file('upstream'),
              joinery: file('joinery'),
              upstreamBox: file('upstream-box'),
              joineryBox: file('joinery-box'),
              diff: file('diff'),
            },
          })
          log(
            `  ${status === 'pass' ? 'ok  ' : 'FAIL'} ${entry.id} (${theme}): ${percent(comparison.ratio)} of ${boxSize(comparison.box)}`,
          )
        } catch (error) {
          const images = Object.fromEntries(
            ['upstream', 'joinery']
              .filter(kind => existsSync(join(reportDir, file(kind))))
              .map(kind => [kind, file(kind)]),
          )
          results.push({ ...base, status: 'error', error: error.message, images })
          log(`  ERR  ${entry.id} (${theme}): ${error.message}`)
        }
      }
      await context.close()
    }

    writeFileSync(
      join(reportDir, 'index.html'),
      renderReport(results, { commit: inventory.commit, skipped, missing }),
    )
    const summary = { commit: inventory.commit, results, skipped, missing }
    writeFileSync(join(reportDir, 'results.json'), `${JSON.stringify(summary, null, 2)}\n`)
    const failures = results.filter(result => result.status !== 'pass')
    log(
      `parity: ${results.length - failures.length} of ${results.length} comparisons pass` +
        `${skipped.length ? `, ${skipped.length} skipped` : ''}; report: ${join(reportDir, 'index.html')}`,
    )
    return failures.length ? 1 : code
  } finally {
    await browser?.close()
    for (const server of servers) server.close()
  }
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  try {
    process.exitCode = await parity(parseArgs(process.argv.slice(2)))
  } catch (error) {
    console.error(`parity: ${error.message}`)
    process.exitCode = 1
  }
}
