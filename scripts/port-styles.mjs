#!/usr/bin/env node
// Ports shadcn's eight style sheets (apps/v4/registry/styles/style-*.css, at the commit pinned in
// upstream.json) into packages/ember/src/styles/<style>.css. See "Styling pipeline" in
// JOINERY_PLAN.md.
//
//   node scripts/port-styles.mjs           writes the ported sheets (run `upstream.mjs fetch` first)
//   node scripts/port-styles.mjs --check   fails if a ported sheet differs from what it would write
//
// The port is mechanical, so an upstream change diffs cleanly into Joinery's copy:
//
// - every `cn-` class becomes `jn-` (in selectors and inside `@apply` arguments alike);
// - upstream scopes each sheet to an ancestor (`.style-nova { … }`), which Joinery doesn't need,
//   since an app loads one style: the wrapper goes and its rules move out one level;
// - each rule's selector goes inside `:where()`, so the rules add no specificity and app CSS can
//   override any part;
// - the `@apply` lists and comments are kept verbatim.

import { existsSync, mkdirSync, readFileSync, readdirSync, writeFileSync } from 'node:fs'
import { basename, dirname, join, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'
import { PATHS, checkoutDir, readPins, repoRoot } from './upstream.mjs'

export const OUTPUT_DIR = 'packages/ember/src/styles'

/** `cn-button` → `jn-button`, anywhere a class name can appear. */
export function renameClasses(css) {
  return css.replace(/(?<![\w-])cn-(?=[a-z0-9])/g, 'jn-')
}

/**
 * Removes the sheet's `.style-<name> { … }` wrapper and dedents what was inside it. A sheet
 * without one is returned as it is.
 */
export function unwrapStyleScope(css, style) {
  const lines = css.replace(/\r\n/g, '\n').split('\n')
  const open = lines.findIndex(line => line.trim() !== '')
  if (lines[open]?.trim() !== `.style-${style} {`) return css
  let close = lines.length - 1
  while (close > open && lines[close].trim() === '') close--
  if (lines[close] !== '}')
    throw new Error(`style-${style}.css: the .style-${style} block isn't closed`)
  const body = lines.slice(open + 1, close).map(line => {
    if (line.trim() === '') return ''
    if (!line.startsWith('  '))
      throw new Error(`style-${style}.css: unexpected indentation: ${line}`)
    return line.slice(2)
  })
  return `${body.join('\n').replace(/^\n+/, '')}\n`
}

/** Puts every top-level rule's selector inside `:where()`. */
export function whereSelectors(css) {
  return css.replace(/^(\.[^\s{][^{\n]*?)\s*\{$/gm, (_match, selector) => {
    if (selector.includes(',')) {
      return `${selector
        .split(',')
        .map(part => `:where(${part.trim()})`)
        .join(', ')} {`
    }
    return `:where(${selector}) {`
  })
}

/** The header every ported sheet starts with. */
export function header(style, commit) {
  return [
    '/*',
    ` * The ${style[0].toUpperCase()}${style.slice(1)} style, ported from shadcn-ui/ui@${commit.slice(0, 7)}`,
    ` * ${PATHS.styles}/style-${style}.css by scripts/port-styles.mjs. Do not edit it: change the`,
    ' * script, or move upstream.json forward and run it again.',
    ' */',
    '',
    '',
  ].join('\n')
}

/** One upstream sheet, ported. */
export function portStyle(css, { style, commit }) {
  return header(style, commit) + whereSelectors(renameClasses(unwrapStyleScope(css, style)))
}

/** The upstream sheets, as `{ style, path }`, in name order. */
export function upstreamSheets(checkout) {
  const dir = join(checkout, PATHS.styles)
  if (!existsSync(dir)) {
    throw new Error(`${dir} is missing; run \`node scripts/upstream.mjs fetch\``)
  }
  return readdirSync(dir)
    .filter(name => /^style-[a-z]+\.css$/.test(name))
    .sort()
    .map(name => ({ style: basename(name, '.css').slice('style-'.length), path: join(dir, name) }))
}

/** Writes (or, with `check`, compares) every ported sheet. Returns the styles it covered. */
export function portStyles({ root = repoRoot, check = false, log = console.log } = {}) {
  const pins = readPins(root)
  const commit = pins['shadcn-ui'].commit
  const checkout = checkoutDir('shadcn-ui', root)
  const outDir = join(root, OUTPUT_DIR)
  const stale = []
  const styles = []
  for (const { style, path } of upstreamSheets(checkout)) {
    const ported = portStyle(readFileSync(path, 'utf8'), { style, commit })
    const target = join(outDir, `${style}.css`)
    styles.push(style)
    if (check) {
      if (!existsSync(target) || readFileSync(target, 'utf8') !== ported)
        stale.push(`${OUTPUT_DIR}/${style}.css`)
      continue
    }
    mkdirSync(dirname(target), { recursive: true })
    writeFileSync(target, ported)
  }
  if (stale.length) {
    throw new Error(
      `stale ported styles (run \`node scripts/port-styles.mjs\`):\n  ${stale.join('\n  ')}`,
    )
  }
  log(
    `${check ? 'checked' : 'wrote'} ${styles.length} styles in ${OUTPUT_DIR}: ${styles.join(', ')}`,
  )
  return styles
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  try {
    portStyles({ check: process.argv.includes('--check') })
  } catch (error) {
    console.error(error.message)
    process.exitCode = 1
  }
}
