#!/usr/bin/env node
// `pnpm site:css`: copies Joinery's own CSS, as `pnpm build` compiles it, into docs/site/joinery/,
// where the marketing page (docs/site/index.html) and the social card load it from. The site is
// styled with what an app imports: tokens.css (the Neutral base colour) and joinery.css (the Nova
// style), and its theme picker swaps in the other base colours (themes/) for tokens.css and the
// other styles (styles/) for joinery.css. The copies are gitignored; pages.yml and CI's site job
// run this after the build.
//
//   pnpm build && pnpm site:css

import { copyFileSync, existsSync, mkdirSync, readdirSync, rmSync } from 'node:fs'
import { dirname, join, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'

export const repoRoot = resolve(dirname(fileURLToPath(import.meta.url)), '..')

/** Where the copies go, relative to the repository. The page links them by these paths. */
export const SITE_CSS_DIR = 'docs/site/joinery'

/** The `.css` files in a folder of the package's dist/, A–Z, as paths relative to dist/. */
function cssIn(dist, folder) {
  return readdirSync(join(dist, folder))
    .filter(file => file.endsWith('.css'))
    .sort()
    .map(file => `${folder}/${file}`)
}

/**
 * The files the site loads, relative to `packages/ember/dist/`: the default theme and style,
 * every base colour (themes/) and every other style (styles/).
 */
export function siteCssFiles(dist) {
  return ['tokens.css', 'joinery.css', ...cssIn(dist, 'themes'), ...cssIn(dist, 'styles')]
}

/** Copies the files into `SITE_CSS_DIR`, replacing what was there. Returns their paths. */
export function copySiteCss(root = repoRoot) {
  const dist = join(root, 'packages', 'ember', 'dist')
  if (!existsSync(join(dist, 'joinery.css'))) {
    throw new Error('packages/ember/dist/joinery.css is missing; run `pnpm build` first')
  }
  const out = join(root, SITE_CSS_DIR)
  rmSync(out, { recursive: true, force: true })
  const files = siteCssFiles(dist)
  for (const file of files) {
    mkdirSync(dirname(join(out, file)), { recursive: true })
    copyFileSync(join(dist, file), join(out, file))
  }
  return files.map(file => `${SITE_CSS_DIR}/${file}`)
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  try {
    for (const file of copySiteCss()) console.log(file)
  } catch (error) {
    console.error(`site-css: ${error.message}`)
    process.exitCode = 1
  }
}
