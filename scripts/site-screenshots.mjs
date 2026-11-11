#!/usr/bin/env node
/* global document -- the page functions run in the browser */
// `pnpm site:screenshots`: makes the site's images from the real thing.
//
// - The component grid (docs/site/img/components/<name>-light.png and -dark.png): each
//   component's example, rendered by the built guide's `/parity/<example>` route (one example,
//   no frame, centred on the theme's background) in a window of the shot's size, light and dark.
//   A shot with `open` clicks that first, for a component whose look is its open overlay.
// - The guide's example frame (docs/site/img/guide-example-light.png and -dark.png), as a page
//   of the guide shows it.
// - The social card (docs/site/social-card.png), rendered from docs/social-card.html at
//   1200×630. It is styled with Joinery's own CSS, copied in by `pnpm site:css`.
//
//   pnpm build && pnpm guide:build && pnpm site:css
//   pnpm site:screenshots                     every image
//   pnpm site:screenshots --only card,social  just these (a shot's name, `guide` or `social`)
//
// It serves docs/ as GitHub Pages does (the guide at /ember-joinery/guide/) and drives
// playwright-core's Chromium, as `pnpm parity` does. The guide and the card load their fonts
// (Geist, Inter) from Google Fonts, so it needs the network.

import { mkdirSync } from 'node:fs'
import { join } from 'node:path'
import { fileURLToPath } from 'node:url'
import { GUIDE_BASE, repoRoot, staticServer } from './parity.mjs'

/**
 * The component grid on the site, in the order it shows them: `name` names the images, `page`
 * is the guide page the tile links to (`guide/<page>.md`), `example` the guide example the shot
 * renders, and `width` the window's width (640 by default). Every window is 4:3, so the tiles
 * line up; a smaller window shows a small example larger. `open` is a selector to click first,
 * and `align` and `fullWidth` place the example as the parity route's parameters do.
 */
export const SHOTS = [
  { name: 'card', example: 'card-demo', page: 'components/card' },
  { name: 'calendar', example: 'calendar-demo', page: 'components/calendar', width: 480 },
  {
    name: 'chart',
    example: 'chart-bar-interactive',
    page: 'charts/bar',
    width: 800,
    fullWidth: true,
  },
  { name: 'dialog', example: 'dialog-demo', page: 'components/dialog', open: 'button' },
  { name: 'command', example: 'command-demo', page: 'components/command', width: 480 },
  {
    name: 'dropdown-menu',
    example: 'dropdown-menu-demo',
    page: 'components/dropdown-menu',
    open: 'button',
    align: 'start',
  },
  { name: 'field', example: 'field-choice-card', page: 'components/field' },
  { name: 'data-table', example: 'data-table-demo', page: 'components/data-table', width: 800 },
  { name: 'input-otp', example: 'input-otp-demo', page: 'components/input-otp', width: 320 },
  { name: 'tabs', example: 'tabs-demo', page: 'components/tabs', width: 480 },
  { name: 'message', example: 'message-demo', page: 'components/message' },
  {
    name: 'rich-text-editor',
    example: 'rich-text-editor-demo',
    page: 'components/rich-text-editor',
  },
]

/** A shot's window: its width (640 unless it says) and three quarters of that tall. */
export const shotViewport = shot => {
  const width = shot.width ?? 640
  return { width, height: Math.round((width * 3) / 4) }
}

export const THEMES = ['light', 'dark']

/** The image paths a shot writes, relative to docs/site/. */
export const shotFiles = shot => THEMES.map(theme => `img/components/${shot.name}-${theme}.png`)

/** The guide's example frame, on the page it is shown from. */
export const GUIDE_SHOT = { page: 'components/card.md', example: 'card-demo' }
export const guideFiles = () => THEMES.map(theme => `img/guide-example-${theme}.png`)

const site = join(repoRoot, 'docs', 'site')

async function shootComponents(browser, base, shots, log) {
  mkdirSync(join(site, 'img', 'components'), { recursive: true })
  for (const theme of THEMES) {
    for (const shot of shots) {
      const viewport = shotViewport(shot)
      const context = await browser.newContext({
        viewport,
        deviceScaleFactor: 1,
        colorScheme: theme,
        reducedMotion: 'reduce',
        locale: 'en-US',
        timezoneId: 'UTC',
      })
      const page = await context.newPage()
      const params = new URLSearchParams({ theme, align: shot.align ?? 'center' })
      if (shot.fullWidth) params.set('fullWidth', 'true')
      await page.goto(`${base}${GUIDE_BASE}parity/${shot.example}?${params}`)
      const stage = page.locator(`[data-parity="${shot.example}"]`)
      await stage.waitFor()
      await page.evaluate(() => document.fonts.ready)
      if (shot.open) {
        await stage.locator(shot.open).first().click()
        await page.waitForTimeout(400)
        // What opened takes focus (a dialog selects its first input): show it at rest.
        await page.evaluate(() => document.activeElement?.blur())
      }
      await page.waitForTimeout(200)
      const file = `img/components/${shot.name}-${theme}.png`
      await page.screenshot({ path: join(site, file) })
      log(`docs/site/${file}`)
      await context.close()
    }
  }
}

async function shootGuide(browser, base, log) {
  for (const theme of THEMES) {
    const context = await browser.newContext({
      viewport: { width: 1100, height: 900 },
      deviceScaleFactor: 1,
      colorScheme: theme,
      reducedMotion: 'reduce',
    })
    const page = await context.newPage()
    await page.goto(`${base}${GUIDE_BASE}${GUIDE_SHOT.page}`)
    const frame = page.locator(`[data-test-example="${GUIDE_SHOT.example}"]`)
    await frame.waitFor()
    await page.evaluate(() => document.fonts.ready)
    await page.waitForTimeout(300)
    const [file] = guideFiles().filter(path => path.includes(`-${theme}.`))
    await frame.screenshot({ path: join(site, file) })
    log(`docs/site/${file}`)
    await context.close()
  }
}

async function shootSocialCard(browser, base, log) {
  const context = await browser.newContext({
    viewport: { width: 1200, height: 630 },
    deviceScaleFactor: 1,
  })
  const page = await context.newPage()
  await page.goto(`${base}/docs/social-card.html`)
  await page.evaluate(() => document.fonts.ready)
  await page.waitForTimeout(200)
  await page.screenshot({ path: join(site, 'social-card.png') })
  log('docs/site/social-card.png')
  await context.close()
}

export async function siteScreenshots({ only, log = console.log } = {}) {
  const wanted = name => !only || only.includes(name)
  const unknown = (only ?? []).filter(
    name => name !== 'guide' && name !== 'social' && !SHOTS.some(shot => shot.name === name),
  )
  if (unknown.length) throw new Error(`no shot named ${unknown.join(', ')}`)

  const guide = join(site, 'guide')
  const server = await staticServer([
    { prefix: GUIDE_BASE, dir: guide, fallback: join(guide, 'index.html') },
    { prefix: '/ember-joinery/', dir: site },
    // The social card's source sits beside docs/site, and loads the site's files from it.
    { prefix: '/docs/', dir: join(repoRoot, 'docs') },
  ])
  const base = `http://127.0.0.1:${server.address().port}`
  const { chromium } = await import('playwright-core')
  const browser = await chromium.launch({
    executablePath: process.env.PARITY_CHROMIUM || undefined,
    args: ['--font-render-hinting=none', '--force-color-profile=srgb'],
  })
  try {
    const shots = SHOTS.filter(shot => wanted(shot.name))
    if (shots.length) await shootComponents(browser, base, shots, log)
    if (wanted('guide')) await shootGuide(browser, base, log)
    if (wanted('social')) await shootSocialCard(browser, base, log)
  } finally {
    await browser.close()
    server.close()
  }
}

if (process.argv[1] && fileURLToPath(import.meta.url) === process.argv[1]) {
  const index = process.argv.indexOf('--only')
  const only = index === -1 ? undefined : process.argv[index + 1].split(',')
  siteScreenshots({ only }).catch(error => {
    console.error(`site-screenshots: ${error.message}`)
    process.exitCode = 1
  })
}
