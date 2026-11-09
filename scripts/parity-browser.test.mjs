// The browser half of scripts/parity.mjs, run for real: two static fixture sites stand in for
// the reference app and the Joinery guide, and `parity()` screenshots them in Chromium, as
// `pnpm parity` does. They draw with boxes, not text, so no font has to be installed.
//
// It needs a Chromium: playwright-core's own (`pnpm exec playwright-core install chromium`, or
// one under PLAYWRIGHT_BROWSERS_PATH), PARITY_CHROMIUM, CHROME_BIN, or a system Chrome. With none,
// it skips, unless PARITY_REQUIRE_BROWSER=1 (as parity.yml sets), which makes that a failure.

import { test } from 'node:test'
import assert from 'node:assert/strict'
import { existsSync, mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from 'node:fs'
import { createServer } from 'node:http'
import { tmpdir } from 'node:os'
import { dirname, join } from 'node:path'
import { chromium } from 'playwright-core'
import { parity, parseArgs, staticServer } from './parity.mjs'

/** The Chromium to use: '' for playwright-core's own, a path, or null if there is none. */
function findChromium() {
  if (process.env.PARITY_CHROMIUM) return process.env.PARITY_CHROMIUM
  try {
    if (existsSync(chromium.executablePath())) return ''
  } catch {
    // playwright-core doesn't know this platform's build; look for a system one.
  }
  const candidates = [
    process.env.CHROME_BIN,
    '/usr/bin/google-chrome',
    '/usr/bin/chromium',
    '/usr/bin/chromium-browser',
  ]
  return candidates.find(path => path && existsSync(path)) ?? null
}

const browser = findChromium()
const skip =
  browser === null && process.env.PARITY_REQUIRE_BROWSER !== '1'
    ? 'no Chromium found; run `pnpm exec playwright-core install chromium`'
    : false

const INVENTORY = {
  commit: '8ab27715521cbd4f87ae6886cd989cbb678f6de7',
  pages: { button: {} },
  examples: Object.fromEntries(
    ['button-demo', 'button-outline', 'button-secondary', 'button-ghost', 'button-broken'].map(
      id => [id, { page: 'button', pages: ['button'] }],
    ),
  ),
  charts: [],
  blocks: [],
}

/** Both sites' page: an outlined "button" (a box with a bar for its label), light or dark. */
const PAGE = script => `<!doctype html>
<html>
<head>
<meta charset="utf-8">
<style>
  body { margin: 0; background: #fff; }
  .dark body { background: #0a0a0a; }
  [data-parity] { display: flex; align-items: center; justify-content: center; box-sizing: border-box; min-height: 100vh; padding: 40px; }
  .button { display: block; width: 120px; height: 34px; border: 1px solid #e5e5e5; border-radius: 8px; }
  .dark .button { border-color: rgb(255 255 255 / 10%); }
  .button.no-border { border-color: transparent; }
  .label { display: block; height: 10px; margin: 12px 30px; background: #0a0a0a; }
  .dark .label { background: #fafafa; }
</style>
</head>
<body>
<script>
  if (new URLSearchParams(location.search).get('theme') === 'dark') {
    document.documentElement.classList.add('dark')
  }
  const name = decodeURIComponent(location.pathname.split('/').filter(Boolean).pop() ?? '')
  const stage = (id, button) => '<div data-parity="' + id + '">' + button + '</div>'
  const button = (extra = '') => '<span class="button ' + extra + '"><span class="label"></span></span>'
  ${script}
</script>
</body>
</html>
`

/** The reference app: every id is the same button, except one that throws, as React's would. */
const REFERENCE = PAGE(`
  setTimeout(() => {
    if (name === 'button-broken') {
      document.body.innerHTML = '<p data-parity-error="button-broken">button-broken threw: boom</p>'
      document.documentElement.dataset.parityReady = 'error'
      throw new Error('boom')
    }
    document.body.innerHTML = stage(name, button())
    document.documentElement.dataset.parityReady = 'true'
  }, 50)
`)

/**
 * The guide's /parity/<name>: the same button, one without its border, one with a second button
 * beside it, an empty stage, or none.
 */
const JOINERY = PAGE(`
  setTimeout(() => {
    const examples = {
      same: button(),
      'no-border': button('no-border'),
      beside: button() + button('extra'),
      empty: '',
    }
    document.body.innerHTML =
      name in examples
        ? stage(name, examples[name])
        : '<p data-parity-missing="' + name + '">No example named “' + name + '”.</p>'
  }, 50)
`)

function fixture(files) {
  const root = mkdtempSync(join(tmpdir(), 'parity-browser-'))
  for (const [path, content] of Object.entries(files)) {
    mkdirSync(dirname(join(root, path)), { recursive: true })
    writeFileSync(join(root, path), typeof content === 'string' ? content : JSON.stringify(content))
  }
  return root
}

/** Runs `parity()` on a fixture root against the two sites, with no fonts but `fonts`. */
async function run(argv, { map, fonts = [], files = {} }) {
  const root = fixture({
    'upstream/inventory.json': INVENTORY,
    'parity/map/button.json': { examples: map },
    'reference/index.html': REFERENCE,
    'guide/index.html': JOINERY,
    ...files,
  })
  const reference = await staticServer([
    { prefix: '/', dir: join(root, 'reference'), fallback: join(root, 'reference/index.html') },
  ])
  const guide = await staticServer([
    { prefix: '/guide/', dir: join(root, 'guide'), fallback: join(root, 'guide/index.html') },
  ])
  const url = (server, path = '') => `http://127.0.0.1:${server.address().port}${path}`
  const before = process.env.PARITY_CHROMIUM
  if (browser) process.env.PARITY_CHROMIUM = browser
  const logs = []
  try {
    const code = await parity(
      parseArgs([
        '--no-build',
        '--reference-url',
        url(reference),
        '--joinery-url',
        url(guide, '/guide/'),
        ...argv,
      ]),
      { root, fonts, log: line => logs.push(line) },
    )
    const report = join(root, 'parity-report')
    const results = existsSync(join(report, 'results.json'))
      ? JSON.parse(readFileSync(join(report, 'results.json'), 'utf8')).results
      : []
    return { code, logs, results, report }
  } finally {
    if (before === undefined) delete process.env.PARITY_CHROMIUM
    else process.env.PARITY_CHROMIUM = before
    reference.close()
    guide.close()
    rmSync(root, { recursive: true, force: true })
  }
}

const byKey = results =>
  Object.fromEntries(results.map(result => [`${result.id} ${result.theme}`, result]))

test(
  'a run screenshots both sides in light and dark, and fails what differs',
  { skip, timeout: 120_000 },
  async () => {
    assert.notEqual(browser, null, 'PARITY_REQUIRE_BROWSER=1, and no Chromium was found')
    const { code, logs, results } = await run([], {
      map: {
        'button-demo': 'same',
        'button-outline': 'no-border',
        'button-secondary': 'empty',
        'button-ghost': 'not-ported',
        'button-broken': 'same',
      },
    })
    assert.equal(code, 1)
    const result = byKey(results)
    assert.equal(results.length, 10, 'five examples, in two themes')
    for (const theme of ['light', 'dark']) {
      const same = result[`button-demo ${theme}`]
      assert.equal(same.status, 'pass', `${theme}: the same rendering passes`)
      assert.equal(same.ratio, 0)
      assert.deepEqual(same.box, { x: 579, y: 382, width: 122, height: 36 }, 'the button, no more')
      assert.ok(same.images.upstreamBox && same.images.joineryBox && same.images.diff)

      const border = result[`button-outline ${theme}`]
      assert.equal(border.status, 'fail', `${theme}: a missing 1px border fails`)
      assert.ok(border.ratio > 0.05, `${theme}: ${border.ratio}`)

      const empty = result[`button-secondary ${theme}`]
      assert.equal(empty.status, 'fail', `${theme}: an empty stage fails`)

      const missing = result[`button-ghost ${theme}`]
      assert.equal(missing.status, 'error')
      assert.match(missing.error, /parity\/not-ported\?.*: No example named “not-ported”\./)
      assert.ok(missing.images.upstream, 'the upstream page it got is kept')

      const broken = result[`button-broken ${theme}`]
      assert.equal(broken.status, 'error')
      assert.match(broken.error, /button-broken threw: boom\nboom$/, 'with the page error')
    }
    assert.match(logs.at(-1), /^parity: 2 of 10 comparisons pass; report: /)
    assert.ok(logs.includes('  ok   button-demo (dark): 0.00% of 122×36'))
  },
)

test('--only compares just what it names', { skip, timeout: 60_000 }, async () => {
  const map = { 'button-demo': 'same', 'button-outline': 'no-border' }
  const { code, results } = await run(['--only', 'button-demo', '--themes', 'dark'], { map })
  assert.equal(code, 0)
  assert.deepEqual(
    results.map(result => [result.id, result.theme, result.status]),
    [['button-demo', 'dark', 'pass']],
  )
  const typo = await run(['--only', 'buton-demo'], { map })
  assert.equal(typo.code, 1)
  assert.match(typo.logs.at(-1), /no upstream example or docs page named "buton-demo"/)
})

test(
  "a font that doesn't load is an error, not a fallback",
  { skip, timeout: 60_000 },
  async () => {
    const { code, results } = await run(['--themes', 'light'], {
      map: { 'button-demo': 'same' },
      fonts: [{ name: 'broken', family: 'Broken Face', text: 'a' }],
      files: {
        'parity/node_modules/@fontsource-variable/broken/index.css':
          "@font-face { font-family: 'Broken Face'; src: url(./missing.woff2) format('woff2'); }",
      },
    })
    assert.equal(code, 1)
    assert.equal(results[0].status, 'error')
    assert.match(results[0].error, /: these fonts didn't load: Broken Face$/)
  },
)

test('a screenshot waits for the images on the page', { skip, timeout: 60_000 }, async () => {
  // The reference page shows a dark 120×34 image that arrives 700ms after the page asks for it,
  // well after the page says it is ready; the guide draws the same box with CSS. Caught before
  // the image, the reference page would show nothing, and the comparison would fail.
  const svg =
    '<svg xmlns="http://www.w3.org/2000/svg" width="120" height="34"><rect width="120" height="34" fill="#0a0a0a"/></svg>'
  const slow = createServer((_request, response) => {
    setTimeout(() => {
      response.writeHead(200, { 'content-type': 'image/svg+xml', 'cache-control': 'no-store' })
      response.end(svg)
    }, 700)
  })
  await new Promise(done => slow.listen(0, '127.0.0.1', done))
  const src = `http://127.0.0.1:${slow.address().port}/photo.svg`
  try {
    const { code, results } = await run(['--themes', 'light'], {
      map: { 'button-demo': 'same' },
      files: {
        'reference/index.html': PAGE(`
          setTimeout(() => {
            document.body.innerHTML = stage(name, '<img src="${src}" width="120" height="34" alt="">')
            document.documentElement.dataset.parityReady = 'true'
          }, 50)
        `),
        'guide/index.html': PAGE(`
          setTimeout(() => {
            const box = '<span style="display: block; width: 120px; height: 34px; background: #0a0a0a"></span>'
            document.body.innerHTML = stage(name, box)
          }, 50)
        `),
      },
    })
    assert.deepEqual(
      results.map(result => [result.id, result.status, result.ratio]),
      [['button-demo', 'pass', 0]],
    )
    assert.equal(code, 0)
  } finally {
    slow.close()
  }
})

test(
  'a screenshot waits for images loaded off the page, and what renders once they load',
  { skip, timeout: 60_000 },
  async () => {
    // As Radix's Avatar (and Joinery's) do, the reference page loads its image with
    // `new Image()`, off the page, and shows a light fallback until it arrives, 700ms after the
    // page asks for it; then it swaps in an <img>. The page has no <img> while it waits, so only
    // a wait that follows every image given a source, in the page or not, catches it; caught
    // early, the reference page would show the fallback, and the comparison would fail.
    const svg =
      '<svg xmlns="http://www.w3.org/2000/svg" width="120" height="34"><rect width="120" height="34" fill="#0a0a0a"/></svg>'
    const slow = createServer((_request, response) => {
      setTimeout(() => {
        response.writeHead(200, { 'content-type': 'image/svg+xml', 'cache-control': 'no-store' })
        response.end(svg)
      }, 700)
    })
    await new Promise(done => slow.listen(0, '127.0.0.1', done))
    const src = `http://127.0.0.1:${slow.address().port}/photo.svg`
    try {
      const { code, results } = await run(['--themes', 'light'], {
        map: { 'button-demo': 'same' },
        files: {
          'reference/index.html': PAGE(`
            setTimeout(() => {
              const fallback = '<span style="display: block; width: 120px; height: 34px; background: #e5e5e5"></span>'
              document.body.innerHTML = stage(name, fallback)
              const image = new Image()
              image.addEventListener('load', () => {
                document.querySelector('[data-parity]').innerHTML =
                  '<img src="${src}" width="120" height="34" alt="" style="display: block">'
              })
              image.src = '${src}'
              document.documentElement.dataset.parityReady = 'true'
            }, 50)
          `),
          'guide/index.html': PAGE(`
            setTimeout(() => {
              const box = '<span style="display: block; width: 120px; height: 34px; background: #0a0a0a"></span>'
              document.body.innerHTML = stage(name, box)
            }, 50)
          `),
        },
      })
      assert.deepEqual(
        results.map(result => [result.id, result.status, result.ratio]),
        [['button-demo', 'pass', 0]],
      )
      assert.equal(code, 0)
    } finally {
      slow.close()
    }
  },
)

test(
  'a region compares only the element it selects, on each page',
  { skip, timeout: 60_000 },
  async () => {
    const { code, results } = await run(['--themes', 'light'], {
      map: {
        // Joinery's page has a second button beside the first, outside the region.
        'button-outline': { example: 'beside', region: '.button' },
        'button-ghost': 'beside',
        'button-secondary': { example: 'same', region: '.no-such-thing' },
      },
    })
    assert.equal(code, 1)
    const result = byKey(results)
    const region = result['button-outline light']
    assert.equal(
      region.status,
      'pass',
      region.error ?? 'what lies outside the region is not compared',
    )
    assert.equal(region.ratio, 0)
    assert.equal(region.region, '.button')
    assert.deepEqual(
      region.box,
      { x: 0, y: 0, width: 122, height: 36 },
      'the first button, no more',
    )
    assert.equal(result['button-ghost light'].status, 'fail', 'the whole page has the second one')
    const missing = result['button-secondary light']
    assert.equal(missing.status, 'error')
    assert.match(missing.error, /nothing on the page matches the region "\.no-such-thing"/)
  },
)
