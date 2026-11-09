import { test } from 'node:test'
import assert from 'node:assert/strict'
import { mkdirSync, mkdtempSync, rmSync, writeFileSync } from 'node:fs'
import { tmpdir } from 'node:os'
import { dirname, join } from 'node:path'
import { PNG } from 'pngjs'
import {
  DEFAULT_THRESHOLD,
  PIXEL_TOLERANCE,
  comparePngs,
  fontMounts,
  injectedCss,
  layoutFor,
  loadMaps,
  pageUrls,
  parity,
  parseArgs,
  passes,
  renderReport,
  requiredIds,
  selectEntries,
  staticServer,
  unmapped,
  validateMapFile,
} from './parity.mjs'

const INVENTORY = {
  commit: '8ab27715521cbd4f87ae6886cd989cbb678f6de7',
  pages: { button: {}, 'button-group': {}, chart: {} },
  examples: {
    'button-demo': { page: 'button', pages: ['button'] },
    'button-rtl': { page: 'button', pages: ['button'], direction: 'rtl' },
    'button-group-demo': {
      page: 'button-group',
      pages: ['button', 'button-group'],
      align: 'start',
    },
  },
  charts: [{ name: 'chart-area-default' }],
  blocks: [{ name: 'login-01' }],
}

function fixture(files, root = mkdtempSync(join(tmpdir(), 'parity-'))) {
  for (const [path, content] of Object.entries(files)) {
    mkdirSync(dirname(join(root, path)), { recursive: true })
    writeFileSync(join(root, path), typeof content === 'string' ? content : JSON.stringify(content))
  }
  return root
}

/** A solid `width`×`height` PNG, with the first `marked` pixels black. */
function png(width, height, marked = 0) {
  const image = new PNG({ width, height })
  for (let i = 0; i < width * height; i++) {
    image.data.set(i < marked ? [0, 0, 0, 255] : [255, 255, 255, 255], i * 4)
  }
  return PNG.sync.write(image)
}

const WHITE = [255, 255, 255, 255]
const BLACK = [10, 10, 10, 255] // shadcn's --foreground (light) and --background (dark)
const BORDER = [229, 229, 229, 255] // --border, oklch(0.922 0 0)
const MUTED = [245, 245, 245, 255] // --muted, --secondary and --accent, oklch(0.97 0 0)
const DARK_CARD = [23, 23, 23, 255] // --card (dark), oklch(0.205 0 0)
const DARK_BORDER = [35, 35, 35, 255] // --border (dark), 10% white over the dark background

/** A page to draw on: `width`×`height` of one colour. */
function page(width = 1280, height = 800, background = WHITE) {
  const image = new PNG({ width, height })
  for (let i = 0; i < image.data.length; i += 4) image.data.set(background, i)
  return image
}

function fill(image, x, y, width, height, rgba) {
  for (let row = y; row < y + height; row++) {
    for (let col = x; col < x + width; col++) image.data.set(rgba, (row * image.width + col) * 4)
  }
  return image
}

/** A 1px outline, like a CSS border. */
function outline(image, x, y, width, height, rgba) {
  fill(image, x, y, width, 1, rgba)
  fill(image, x, y + height - 1, width, 1, rgba)
  fill(image, x, y, 1, height, rgba)
  fill(image, x + width - 1, y, 1, height, rgba)
  return image
}

/** Lines of "text": short runs of solid pixels, as glyph stems are. */
function text(image, x, y, width, rgba, lines = 1) {
  for (let line = 0; line < lines; line++) {
    for (let col = x; col < x + width; col += 6) fill(image, col, y + line * 20, 3, 10, rgba)
  }
  return image
}

/** shadcn's card on a page: a bordered box with a title, a line of copy and a muted input. */
function card({
  background = WHITE,
  surface = WHITE,
  line = BORDER,
  muted = MUTED,
  ink = BLACK,
  bordered = true,
} = {}) {
  const image = page(1280, 800, background)
  fill(image, 460, 290, 360, 220, surface)
  if (bordered) outline(image, 460, 290, 360, 220, line)
  text(image, 484, 314, 140, ink)
  text(image, 484, 344, 280, ink, 2)
  fill(image, 484, 400, 312, 36, muted)
  outline(image, 484, 400, 312, 36, line)
  return PNG.sync.write(image)
}

const DARK = {
  background: BLACK,
  surface: DARK_CARD,
  line: DARK_BORDER,
  muted: [38, 38, 38, 255],
  ink: WHITE,
}

test('requiredIds lists every docs page example and every chart, not blocks', () => {
  assert.deepEqual(requiredIds(INVENTORY), [
    { id: 'button-demo', component: 'button' },
    { id: 'button-rtl', component: 'button' },
    { id: 'button-group-demo', component: 'button-group' },
    { id: 'chart-area-default', component: 'chart' },
  ])
})

test('validateMapFile accepts names, thresholds with reasons, and skips', () => {
  const { entries, errors } = validateMapFile(
    'button',
    {
      $comment: 'Button',
      examples: {
        'button-demo': 'button-demo',
        'button-rtl': { example: 'button-rtl', threshold: 0.03, reason: 'Arabic shaping differs.' },
        'button-group-demo': { skip: 'Shown on Button Group too; compared there.' },
      },
    },
    INVENTORY,
  )
  assert.deepEqual(errors, [])
  assert.deepEqual(entries, [
    {
      id: 'button-demo',
      component: 'button',
      example: 'button-demo',
      threshold: DEFAULT_THRESHOLD,
    },
    {
      id: 'button-rtl',
      component: 'button',
      example: 'button-rtl',
      threshold: 0.03,
      reason: 'Arabic shaping differs.',
    },
    {
      id: 'button-group-demo',
      component: 'button',
      skip: 'Shown on Button Group too; compared there.',
    },
  ])
})

test('validateMapFile reports what is wrong with an entry', () => {
  const { errors } = validateMapFile(
    'button',
    {
      extra: true,
      examples: {
        'no-such-example': 'x',
        'chart-area-default': 'chart-area-default',
        'button-demo': { example: 'button-demo', threshold: 0.05 },
        'button-rtl': { example: 'Button RTL', colour: 'red' },
        'button-group-demo': { skip: '' },
      },
    },
    INVENTORY,
  )
  assert.deepEqual(errors, [
    'parity/map/button.json: unknown key "extra"',
    'parity/map/button.json: "no-such-example" is not an upstream example',
    'parity/map/button.json: "chart-area-default" belongs in parity/map/chart.json',
    'parity/map/button.json: "button-demo": a threshold needs a "reason"',
    'parity/map/button.json: "button-rtl" has unknown keys: colour',
    'parity/map/button.json: "button-rtl": "example" must be a guide example\'s name (docs-app/app/examples)',
    'parity/map/button.json: "button-group-demo": "skip" must be the reason, as a sentence',
  ])
  assert.match(
    validateMapFile(
      'button',
      { examples: { 'button-demo': { example: 'a', reason: 'why' } } },
      INVENTORY,
    ).errors[0],
    /there is none/,
  )
  assert.match(
    validateMapFile(
      'button',
      { examples: { 'button-demo': { example: 'a', threshold: 2, reason: 'r' } } },
      INVENTORY,
    ).errors[0],
    /between 0 and 1/,
  )
  assert.match(validateMapFile('button', [], INVENTORY).errors[0], /expected an object/)
})

test('loadMaps reads parity/map/*.json, rejects unknown components and double mappings', () => {
  const root = fixture({
    'parity/map/button.json': {
      examples: { 'button-demo': 'button-demo', 'button-group-demo': 'button-group-demo' },
    },
    'parity/map/button-group.json': { examples: { 'button-group-demo': 'button-group-demo' } },
    'parity/map/blocks.json': { examples: { 'login-01': 'login-01' } },
    'parity/map/nonsense.json': { examples: {} },
    'parity/map/chart.json': '{ not json',
  })
  try {
    const { entries, errors } = loadMaps(INVENTORY, { root })
    assert.deepEqual(
      entries.map(entry => `${entry.component}:${entry.id}`),
      [
        'blocks:login-01',
        'button-group:button-group-demo',
        'button:button-demo',
        'button:button-group-demo',
      ],
    )
    assert.equal(errors.length, 3)
    assert.match(errors[0], /chart\.json: .*JSON/)
    assert.match(errors[1], /nonsense\.json: there is no upstream docs page "nonsense"/)
    assert.match(
      errors[2],
      /"button-group-demo" is mapped in both button-group\.json and button\.json/,
    )
  } finally {
    rmSync(root, { recursive: true, force: true })
  }
})

test('unmapped and selectEntries', () => {
  const entries = [
    { id: 'button-demo', component: 'button' },
    { id: 'chart-area-default', component: 'chart' },
  ]
  assert.deepEqual(unmapped(INVENTORY, entries), {
    button: ['button-rtl'],
    'button-group': ['button-group-demo'],
  })
  assert.deepEqual(selectEntries(entries, 'chart', INVENTORY), [entries[1]])
  assert.deepEqual(selectEntries(entries, 'button-demo, button-demo', INVENTORY), [entries[0]])
  assert.equal(selectEntries(entries, undefined, INVENTORY), entries)
  // A value that matches nothing mapped fails, so a typo can't pass by comparing nothing.
  assert.throws(
    () => selectEntries(entries, 'button-demo, buton', INVENTORY),
    /^Error: --only: there is no upstream example or docs page named "buton"$/,
  )
  assert.throws(
    () => selectEntries(entries, 'button-rtl,button-group', INVENTORY),
    /"button-rtl" has nothing mapped in parity\/map\/ yet; "button-group" has nothing mapped/,
  )
  assert.throws(() => selectEntries(entries, ' , ', INVENTORY), /names no component/)
})

test('layoutFor and pageUrls carry the docs page layout to both pages', () => {
  assert.deepEqual(layoutFor('button-rtl', INVENTORY), { dir: 'rtl', align: 'center' })
  assert.deepEqual(layoutFor('button-group-demo', INVENTORY), { dir: 'ltr', align: 'start' })
  assert.deepEqual(layoutFor('chart-area-default', INVENTORY), { dir: 'ltr', align: 'center' })
  assert.deepEqual(layoutFor('login-01', INVENTORY), { dir: 'ltr', align: 'start' })
  assert.deepEqual(
    pageUrls({
      referenceUrl: 'http://127.0.0.1:1/',
      joineryUrl: 'http://127.0.0.1:2/ember-joinery/guide/',
      entry: { id: 'button-rtl', example: 'button-rtl' },
      theme: 'dark',
      layout: { dir: 'rtl', align: 'center' },
    }),
    {
      upstream: 'http://127.0.0.1:1/button-rtl?theme=dark&dir=rtl&align=center',
      joinery:
        'http://127.0.0.1:2/ember-joinery/guide/parity/button-rtl?theme=dark&dir=rtl&align=center',
    },
  )
})

test('comparePngs counts differing pixels over the content box, and a size difference counts too', async () => {
  const same = await comparePngs(card(), card())
  assert.equal(same.diffPixels, 0)
  assert.equal(same.ratio, 0)
  assert.deepEqual(same.box, { x: 460, y: 290, width: 360, height: 220 })
  assert.deepEqual(same.backgrounds, { upstream: '#ffffff', joinery: '#ffffff' })
  assert.equal(same.blank, false)
  assert.equal(PNG.sync.read(same.diff).width, 360, 'the diff covers the box')
  assert.equal(PNG.sync.read(same.areas.upstream).height, 220)

  const some = await comparePngs(png(10, 10), png(10, 10, 5))
  assert.equal(some.diffPixels, 5)
  assert.deepEqual(some.box, { x: 0, y: 0, width: 5, height: 1 })
  assert.equal(some.ratio, 1)

  const taller = await comparePngs(png(10, 10, 1), png(10, 12, 1))
  assert.deepEqual([taller.width, taller.height], [10, 12])
  assert.deepEqual(taller.sizes, { upstream: [10, 10], joinery: [10, 12] })
  assert.deepEqual(taller.box, { x: 0, y: 0, width: 10, height: 12 }, 'the extra rows are content')
  assert.equal(taller.diffPixels, 20, 'the two extra rows')

  const blank = await comparePngs(png(10, 10), png(10, 10))
  assert.equal(blank.blank, true)
  assert.equal(blank.box, null)

  assert.ok(passes(0.01))
  assert.ok(!passes(0.0101))
  assert.ok(passes(0.03, 0.05))
})

test('an example against an empty stage fails', async () => {
  // button-demo: an outline button and an icon button, small in the middle of the page.
  const example = page()
  outline(example, 560, 382, 100, 36, BORDER)
  text(example, 580, 395, 60, BLACK)
  fill(example, 672, 382, 36, 36, BLACK)
  fill(example, 682, 392, 16, 16, WHITE)
  const empty = PNG.sync.write(page())
  const result = await comparePngs(PNG.sync.write(example), empty)
  assert.deepEqual(result.box, { x: 560, y: 382, width: 148, height: 36 })
  assert.ok(!passes(result.ratio), `${result.ratio} of the box differs`)
  assert.ok(
    result.diffPixels / (1280 * 800) < DEFAULT_THRESHOLD,
    'over the whole page it would have passed, which is why the box is what counts',
  )
  // The other way round too, and in dark.
  assert.ok(!passes((await comparePngs(empty, PNG.sync.write(example))).ratio))
  const dark = await comparePngs(card(DARK), PNG.sync.write(page(1280, 800, BLACK)))
  assert.ok(!passes(dark.ratio), `${dark.ratio} of the box differs (dark)`)
})

test('a border-only change fails, light and dark', async () => {
  const light = await comparePngs(card(), card({ bordered: false }))
  assert.deepEqual(light.box, { x: 460, y: 290, width: 360, height: 220 })
  assert.equal(light.diffPixels, 2 * (360 + 220) - 4, 'every pixel of the border, and nothing else')
  assert.ok(!passes(light.ratio), `${light.ratio} of the box differs`)

  const dark = await comparePngs(card(DARK), card({ ...DARK, bordered: false }))
  assert.equal(dark.diffPixels, 2 * (360 + 220) - 4)
  assert.ok(!passes(dark.ratio), `${dark.ratio} of the box differs (dark)`)
})

test("each of shadcn's token steps registers as a difference, and rounding noise doesn't", async () => {
  const swatch = (background, colour) =>
    PNG.sync.write(fill(page(40, 40, background), 10, 10, 20, 20, colour))
  for (const [background, a, b, what] of [
    [WHITE, WHITE, BORDER, 'white and --border'],
    [WHITE, WHITE, MUTED, 'white and --muted'],
    [BLACK, BLACK, DARK_BORDER, 'the dark background and its border'],
    [BLACK, BLACK, DARK_CARD, 'the dark background and --card'],
  ]) {
    const result = await comparePngs(swatch(background, a), swatch(background, b))
    assert.ok(result.diffPixels > 0, what)
  }
  const nearly = await comparePngs(swatch(WHITE, MUTED), swatch(WHITE, [243, 243, 243, 255]))
  assert.equal(nearly.diffPixels, 0, 'two levels of grey apart is the same colour')
  assert.ok(PIXEL_TOLERANCE < 0.1, "tighter than pixelmatch's default, which misses all of them")
})

test('comparePngs compares the whole page when the backgrounds differ', async () => {
  const result = await comparePngs(card(), card({ background: MUTED }))
  assert.deepEqual(result.box, { x: 0, y: 0, width: 1280, height: 800 })
  assert.deepEqual(result.backgrounds, { upstream: '#ffffff', joinery: '#f5f5f5' })
  assert.ok(!passes(result.ratio))
})

test('renderReport shows each comparison side by side', () => {
  const html = renderReport(
    [
      {
        id: 'button-demo',
        component: 'button',
        example: 'button-demo',
        theme: 'light',
        status: 'pass',
        ratio: 0.001,
        threshold: 0.01,
        box: { x: 560, y: 382, width: 148, height: 36 },
        backgrounds: { upstream: '#ffffff', joinery: '#ffffff' },
        images: {
          upstream: 'images/a.png',
          joinery: 'images/b.png',
          upstreamBox: 'images/a-box.png',
          joineryBox: 'images/b-box.png',
          diff: 'images/c.png',
        },
      },
      {
        id: 'card-demo',
        component: 'card',
        example: 'card-demo',
        theme: 'dark',
        status: 'fail',
        ratio: 0.5,
        threshold: 0.01,
        box: { x: 0, y: 0, width: 1280, height: 800 },
        backgrounds: { upstream: '#0a0a0a', joinery: '#ffffff' },
        images: {},
      },
      {
        id: 'button-rtl',
        component: 'button',
        example: 'button-rtl',
        theme: 'dark',
        status: 'error',
        error: 'No example named <x>',
        images: { upstream: 'images/d.png' },
      },
    ],
    {
      commit: INVENTORY.commit,
      skipped: [{ id: 'button-group-demo', skip: 'why' }],
      missing: { chart: ['chart-area-default'] },
    },
  )
  assert.match(
    html,
    /shadcn-ui\/ui 8ab2771: 1 of 3 comparisons pass; 1 mapped examples are skipped\./,
  )
  assert.match(
    html,
    /<img src="images\/b-box.png" alt="joinery" loading="lazy"><figcaption>joinery \(<a href="images\/b.png">full page<\/a>\)/,
  )
  assert.match(html, /0\.10% of the 148×36 content box differs \(at 560, 382\); threshold 1\.00%\./)
  assert.match(html, /The backgrounds differ \(upstream #0a0a0a, Joinery #ffffff\)/)
  assert.match(html, /No example named &lt;x&gt;/)
  assert.match(html, /<img src="images\/d.png" alt="upstream"/, 'an error shows the pages it got')
  assert.match(html, /<li>button-group-demo: why<\/li>/)
  assert.match(html, /<strong>chart<\/strong>: chart-area-default/)
})

test('injectedCss loads the fonts, fixes the scheme and stops motion', () => {
  const css = injectedCss('dark', 'http://127.0.0.1:4000/')
  assert.match(
    css,
    /^@import url\('http:\/\/127\.0\.0\.1:4000\/__parity\/fonts\/geist\/index.css'\);/,
  )
  assert.match(
    css,
    /@import url\('http:\/\/127\.0\.0\.1:4000\/__parity\/fonts\/noto-sans-hebrew\/index.css'\);/,
  )
  assert.match(css, /color-scheme: dark !important/)
  assert.match(css, /animation-duration: 0s !important/)
})

test("fontMounts serves the parity app's fonts, and says what to install when they are missing", () => {
  const root = fixture({
    'parity/node_modules/@fontsource-variable/geist/index.css': '',
    'parity/node_modules/@fontsource-variable/geist-mono/index.css': '',
  })
  try {
    assert.throws(
      () => fontMounts(root),
      /fonts are missing \(noto-sans-arabic, noto-sans-hebrew\); run `pnpm --dir parity install`/,
    )
    fixture(
      {
        'parity/node_modules/@fontsource-variable/noto-sans-arabic/index.css': '',
        'parity/node_modules/@fontsource-variable/noto-sans-hebrew/index.css': '',
      },
      root,
    )
    assert.deepEqual(
      fontMounts(root).map(mount => mount.prefix),
      [
        '/__parity/fonts/geist/',
        '/__parity/fonts/geist-mono/',
        '/__parity/fonts/noto-sans-arabic/',
        '/__parity/fonts/noto-sans-hebrew/',
      ],
    )
  } finally {
    rmSync(root, { recursive: true, force: true })
  }
})

test('parseArgs', () => {
  assert.deepEqual(parseArgs([]), {
    requireComplete: false,
    build: true,
    themes: ['light', 'dark'],
  })
  assert.deepEqual(
    parseArgs(['--require-complete', '--no-build', '--only', 'button', '--themes', 'dark']),
    {
      requireComplete: true,
      build: false,
      only: 'button',
      themes: ['dark'],
    },
  )
  assert.throws(() => parseArgs(['--themes', 'sepia']), /unknown theme/)
  assert.throws(() => parseArgs(['--only']), /needs a value/)
  assert.throws(() => parseArgs(['--fast']), /unknown option/)
})

test('staticServer serves files, falls back to the app, and stays in its folder', async () => {
  const root = fixture({
    'app/index.html': '<p>app</p>',
    'app/assets/a.js': 'x',
    'secret.txt': 'no',
  })
  const server = await staticServer([
    { prefix: '/guide/', dir: join(root, 'app'), fallback: join(root, 'app/index.html') },
  ])
  const base = `http://127.0.0.1:${server.address().port}`
  try {
    const asset = await fetch(`${base}/guide/assets/a.js`)
    assert.equal(asset.headers.get('content-type'), 'text/javascript')
    assert.equal(asset.headers.get('access-control-allow-origin'), '*', 'fonts load cross-origin')
    assert.equal(await asset.text(), 'x')
    assert.equal(await (await fetch(`${base}/guide/parity/button-demo`)).text(), '<p>app</p>')
    // An encoded slash survives URL parsing, so this reaches the server as /guide/../secret.txt.
    assert.equal((await fetch(`${base}/guide/..%2Fsecret.txt`)).status, 403)
    assert.equal((await fetch(`${base}/elsewhere`)).status, 404)
  } finally {
    server.close()
    rmSync(root, { recursive: true, force: true })
  }
})

test('a run with nothing mapped passes, unless every example must be mapped', async () => {
  const root = fixture({ 'upstream/inventory.json': INVENTORY })
  try {
    const logs = []
    const log = line => logs.push(line)
    assert.equal(await parity(parseArgs([]), { root, log }), 0)
    assert.match(logs.at(-1), /nothing to compare \(0 mapped; 4 of 4 upstream examples unmapped\)/)
    assert.equal(await parity(parseArgs(['--require-complete']), { root, log }), 1)
    assert.ok(logs.includes("parity: 4 upstream examples aren't mapped (--require-complete):"))

    mkdirSync(join(root, 'parity/map'), { recursive: true })
    writeFileSync(join(root, 'parity/map/button.json'), JSON.stringify({ examples: { nope: 'x' } }))
    assert.equal(await parity(parseArgs([]), { root, log }), 1)
    assert.match(logs.at(-1), /the map has errors/)
  } finally {
    rmSync(root, { recursive: true, force: true })
  }
})
