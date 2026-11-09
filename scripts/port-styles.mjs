#!/usr/bin/env node
// Ports shadcn's eight style sheets (apps/v4/registry/styles/style-*.css, at the commit pinned in
// upstream.json) into packages/ember/src/styles/<style>.css. See "Styling pipeline" in
// JOINERY_PLAN.md.
//
//   node scripts/port-styles.mjs           writes the ported sheets (run `upstream.mjs fetch` first),
//                                          and removes any it ported from a sheet upstream has dropped
//   node scripts/port-styles.mjs --check   fails if a ported sheet differs from what it would write,
//                                          or is left from a sheet upstream has dropped
//
// The port is mechanical, so an upstream change diffs cleanly into Joinery's copy:
//
// - every `cn-` class becomes `jn-` (in selectors and inside `@apply` arguments alike);
// - upstream scopes each sheet to an ancestor (`.style-nova { … }`), which Joinery doesn't need,
//   since an app loads one style: the wrapper goes and its rules move out one level;
// - each rule's selector goes inside `:where()`, so the rules add no specificity and app CSS can
//   override any part;
// - the `@apply` lists and comments are kept verbatim.
//
// It relies on upstream's sheets being flat rules inside the wrapper. Anything else (no wrapper,
// a rule outside it, a nested rule or an at-rule) fails the port instead of slipping through.

import { existsSync, mkdirSync, readFileSync, readdirSync, rmSync, writeFileSync } from 'node:fs'
import { basename, dirname, join, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'
import { PATHS, checkoutDir, readPins, repoRoot } from './upstream.mjs'

export const OUTPUT_DIR = 'packages/ember/src/styles'

/** `cn-button` → `jn-button`, anywhere a class name can appear. */
export function renameClasses(css) {
  return css.replace(/(?<![\w-])cn-(?=[a-z0-9])/g, 'jn-')
}

/**
 * Removes the sheet's `.style-<name> { … }` wrapper and dedents what was inside it. Blank lines
 * and comments before the wrapper are allowed (and dropped). Anything else fails: the port
 * relies on upstream's shape, so a sheet without the wrapper, or with rules outside it, is an
 * error rather than a silent half-port.
 */
export function unwrapStyleScope(css, style) {
  const lines = css.replace(/\r\n/g, '\n').split('\n')
  let open = 0
  for (let inComment = false; open < lines.length; open++) {
    const line = lines[open].trim()
    if (inComment || line.startsWith('/*')) {
      inComment = !line.includes('*/')
      continue
    }
    if (line !== '') break
  }
  if (lines[open]?.trim() !== `.style-${style} {`) {
    throw new Error(
      `style-${style}.css: expected its rules inside one .style-${style} { … } block, found: ${lines[open]?.trim() ?? 'nothing'}`,
    )
  }
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

/**
 * A selector list split at its top-level commas, leaving those inside `()`, `[]` and quotes
 * (`.a:is(.b, .c), .d` is two selectors).
 */
export function splitSelectorList(selector) {
  const parts = []
  let depth = 0
  let quote
  let start = 0
  for (let index = 0; index < selector.length; index++) {
    const char = selector[index]
    if (quote) {
      if (char === '\\') index++
      else if (char === quote) quote = undefined
    } else if (char === '"' || char === "'") quote = char
    else if (char === '(' || char === '[') depth++
    else if (char === ')' || char === ']') depth--
    else if (char === ',' && depth === 0) {
      parts.push(selector.slice(start, index))
      start = index + 1
    }
  }
  parts.push(selector.slice(start))
  return parts.map(part => part.trim())
}

/** Puts every top-level rule's selector inside `:where()`, each selector of a list on its own. */
export function whereSelectors(css) {
  return css.replace(
    /^(\.[^\s{][^{\n]*?)\s*\{$/gm,
    (_match, selector) =>
      `${splitSelectorList(selector)
        .map(part => `:where(${part})`)
        .join(', ')} {`,
  )
}

/**
 * Fails unless a ported sheet is what the port promises: no `cn-` class or `.style-` scope left,
 * every rule at the top level with its selector in `:where()`, and no nested rules or at-rules
 * (which would keep their specificity, or need a decision the port can't make).
 */
export function checkPorted(css, style) {
  const problems = []
  const text = css.replace(/\/\*[\s\S]*?\*\//g, comment => comment.replace(/[^\n]/g, ' '))
  text.split('\n').forEach((line, index) => {
    const where = `line ${index + 1}`
    if (/(?<![\w-])cn-[a-z0-9]/.test(line)) problems.push(`${where}: a cn- class is left`)
    if (/\.style-[a-z]/.test(line)) problems.push(`${where}: the .style-${style} scope is left`)
    if (!line.trimEnd().endsWith('{')) return
    if (/^\s/.test(line)) problems.push(`${where}: a nested rule or block: ${line.trim()}`)
    else if (!/^:where\(/.test(line)) problems.push(`${where}: not in :where(): ${line.trim()}`)
  })
  if (problems.length) {
    throw new Error(`style-${style}.css didn't port cleanly:\n  ${problems.join('\n  ')}`)
  }
  return css
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

/** Whether a file is a sheet this script ported: it starts with `header()`'s first lines. */
export function isPorted(css) {
  return /^\/\*\n \* The [A-Z][a-z]+ style, ported from shadcn-ui\/ui@[0-9a-f]+\n/.test(css)
}

/** One upstream sheet, ported. */
export function portStyle(css, { style, commit }) {
  const ported = whereSelectors(renameClasses(unwrapStyleScope(css, style)))
  return header(style, commit) + checkPorted(ported, style)
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

/**
 * Writes (or, with `check`, compares) every ported sheet, and removes (or, with `check`, reports)
 * the ones left from a sheet upstream no longer has. Other files in the folder are left alone.
 * Returns the styles it covered.
 */
export function portStyles({ root = repoRoot, check = false, log = console.log } = {}) {
  const pins = readPins(root)
  const commit = pins['shadcn-ui'].commit
  const checkout = checkoutDir('shadcn-ui', root)
  const outDir = join(root, OUTPUT_DIR)
  const stale = []
  const styles = []
  const sheets = upstreamSheets(checkout)
  const current = new Set(sheets.map(({ style }) => `${style}.css`))
  const dropped = existsSync(outDir)
    ? readdirSync(outDir)
        .filter(name => name.endsWith('.css') && !current.has(name))
        .filter(name => isPorted(readFileSync(join(outDir, name), 'utf8')))
        .sort()
    : []
  for (const name of dropped) {
    if (check) stale.push(`${OUTPUT_DIR}/${name} (upstream has no style-${name} any more)`)
    else {
      rmSync(join(outDir, name))
      log(`removed ${OUTPUT_DIR}/${name}: upstream has no style-${name} any more`)
    }
  }
  for (const { style, path } of sheets) {
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
