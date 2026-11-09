// The guide's view of Joinery's CSS, as a Vite plugin with two virtual modules. Each example
// frame picks a style, a base colour, a radius and light or dark for its preview (see
// app/components/example.gts), so the guide can't load one style sheet for the whole page as an
// app does:
//
// - `virtual:joinery-styles.css` holds all eight styles, each scoped to the previews that pick
//   it: `@scope ([data-style="<style>"]) to ([data-style])`, inside `@layer joinery`. The `to`
//   limit stops a style at a nested preview that picks another, so no rule of one style leaks
//   into another's preview. It is built from the package's compiled dist/joinery.css and
//   dist/styles/<style>.css, so the guide shows exactly what apps get.
// - `virtual:joinery-themes` is the base colours' tokens, read from dist/themes/<colour>.css, for
//   the frame to set on its preview.

import { existsSync, readFileSync, readdirSync } from 'node:fs'
import { basename, dirname, join } from 'node:path'
import { fileURLToPath } from 'node:url'

const dist = join(dirname(fileURLToPath(import.meta.url)), 'node_modules/@ember-joinery/ember/dist')

const STYLES_ID = 'virtual:joinery-styles.css'
const THEMES_ID = 'virtual:joinery-themes'
const RESOLVED_THEMES_ID = `\0${THEMES_ID}`

/** The style sheets the package ships, as `{ name, path }`, Nova (dist/joinery.css) first. */
export function styleSheets(dir = dist) {
  if (!existsSync(join(dir, 'joinery.css'))) {
    throw new Error(`${dir}/joinery.css is missing; build the packages first (pnpm build)`)
  }
  const others = readdirSync(join(dir, 'styles'))
    .filter(name => name.endsWith('.css'))
    .sort()
    .map(name => ({ name: basename(name, '.css'), path: join(dir, 'styles', name) }))
  return [{ name: 'nova', path: join(dir, 'joinery.css') }, ...others]
}

/**
 * Splits CSS into its top-level statements and blocks (`@layer x;`, `a { … }`, `@layer x { … }`),
 * skipping comments and leaving braces inside strings alone.
 */
export function topLevel(css) {
  const blocks = []
  let depth = 0
  let start = 0
  let quote
  for (let index = 0; index < css.length; index++) {
    const char = css[index]
    if (quote) {
      if (char === '\\') index++
      else if (char === quote) quote = undefined
      continue
    }
    if (char === '/' && css[index + 1] === '*') {
      const end = css.indexOf('*/', index + 2)
      if (depth === 0) start = end + 2
      index = end + 1
      continue
    }
    if (char === '"' || char === "'") quote = char
    else if (char === '{') depth++
    else if (char === '}') {
      depth--
      if (depth === 0) {
        blocks.push(css.slice(start, index + 1).trim())
        start = index + 1
      }
    } else if (char === ';' && depth === 0) {
      blocks.push(css.slice(start, index + 1).trim())
      start = index + 1
    }
  }
  return blocks.filter(Boolean)
}

/** Every style, scoped to the previews that pick it, in one style sheet. */
export function scopedStyles(sheets = styleSheets()) {
  const scoped = []
  const shared = new Set()
  for (const { name, path } of sheets) {
    for (const block of topLevel(readFileSync(path, 'utf8'))) {
      const layer = /^@layer\s+joinery\s*\{/.exec(block)
      if (!layer) {
        // @property registrations, keyframes and the like: the same in every style.
        shared.add(block)
        continue
      }
      const body = block.slice(layer[0].length, -1)
      scoped.push(`@scope ([data-style="${name}"]) to ([data-style]) {${body}}`)
    }
  }
  return `@layer joinery {\n${scoped.join('\n')}\n}\n${[...shared].join('\n')}\n`
}

/** A theme file's custom properties: `{ light: {…}, dark: {…} }`, from `:root` and `.dark`. */
export function themeTokens(css) {
  const tokens = { light: {}, dark: {} }
  for (const block of topLevel(css)) {
    const selector = block.slice(0, block.indexOf('{')).trim()
    const mode = selector === ':root' ? 'light' : selector === '.dark' ? 'dark' : undefined
    if (!mode) continue
    for (const [, name, value] of block.matchAll(/(--[\w-]+)\s*:\s*([^;]+);/g)) {
      tokens[mode][name] = value.trim()
    }
  }
  return tokens
}

/** The base colours, in the order upstream lists them (Neutral, Joinery's default, first). */
export function baseColors(dir = dist) {
  const order = ['neutral', 'stone', 'zinc', 'mauve', 'olive', 'mist', 'taupe']
  const names = readdirSync(join(dir, 'themes'))
    .filter(name => name.endsWith('.css'))
    .map(name => basename(name, '.css'))
    .sort(
      (a, b) => (order.indexOf(a) + 1 || 99) - (order.indexOf(b) + 1 || 99) || a.localeCompare(b),
    )
  return Object.fromEntries(
    names.map(name => [
      name,
      themeTokens(readFileSync(join(dir, 'themes', `${name}.css`), 'utf8')),
    ]),
  )
}

export function joineryCss() {
  return {
    name: 'joinery-guide-css',
    resolveId(id) {
      if (id === STYLES_ID) return STYLES_ID
      if (id === THEMES_ID) return RESOLVED_THEMES_ID
    },
    load(id) {
      if (id === STYLES_ID) {
        const sheets = styleSheets()
        for (const { path } of sheets) this.addWatchFile(path)
        return scopedStyles(sheets)
      }
      if (id === RESOLVED_THEMES_ID) {
        const colors = baseColors()
        const styles = styleSheets().map(sheet => sheet.name)
        return `export const styles = ${JSON.stringify(styles)}\nexport const baseColors = ${JSON.stringify(colors)}\n`
      }
    },
  }
}
