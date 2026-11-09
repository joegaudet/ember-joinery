import { test } from 'node:test'
import assert from 'node:assert/strict'
import { mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from 'node:fs'
import { tmpdir } from 'node:os'
import { dirname, join } from 'node:path'
import {
  BASE_COLORS_FILE,
  THEMES_DIR,
  THEMES_FILE,
  isPortedTheme,
  parseBaseColorNames,
  parseThemes,
  portThemes,
  themeCss,
} from './themes.mjs'

const THEMES = `import { type RegistryItem } from "shadcn/schema"

export const THEMES: RegistryItem[] = [
  {
    name: "neutral",
    title: "Neutral",
    type: "registry:theme",
    cssVars: {
      light: { background: "oklch(1 0 0)", "chart-1": "oklch(0.87 0 0)", radius: "0.625rem" },
      dark: { background: "oklch(0.145 0 0)", border: "oklch(1 0 0 / 10%)" },
    },
  },
  {
    name: "amber",
    title: "Amber",
    type: "registry:theme",
    cssVars: { light: { primary: "oklch(0.5 0.1 70)" }, dark: { primary: "oklch(0.6 0.1 70)" } },
  },
]
`

const BASE_COLORS = `import { THEMES } from "@/registry/themes"

export const BASE_COLORS = THEMES.filter((theme) =>
  ["neutral"].includes(theme.name)
)
`

const COMMIT = '8ab27715521cbd4f87ae6886cd989cbb678f6de7'

test('parseThemes and parseBaseColorNames read the files as data', () => {
  const themes = parseThemes(THEMES)
  assert.deepEqual(
    themes.map(theme => theme.name),
    ['neutral', 'amber'],
  )
  assert.equal(themes[0].cssVars.light['chart-1'], 'oklch(0.87 0 0)')
  assert.deepEqual(parseBaseColorNames(BASE_COLORS), ['neutral'])
  assert.throws(() => parseThemes('export const THEMES = [compute()]'), /expected a literal/)
})

test('themeCss puts the light tokens on :root and the dark ones on .dark', () => {
  const css = themeCss(parseThemes(THEMES)[0], COMMIT)
  assert.ok(isPortedTheme(css))
  assert.match(css, /The Neutral base colour, ported from shadcn-ui\/ui@8ab2771/)
  assert.match(
    css,
    /:root \{\n {2}--background: oklch\(1 0 0\);\n {2}--chart-1: oklch\(0\.87 0 0\);\n {2}--radius: 0\.625rem;\n\}/,
  )
  assert.match(
    css,
    /\.dark \{\n {2}--background: oklch\(0\.145 0 0\);\n {2}--border: oklch\(1 0 0 \/ 10%\);\n\}/,
  )
})

test('portThemes writes the base colours only, and --check finds stale ones', () => {
  const root = mkdtempSync(join(tmpdir(), 'port-themes-'))
  const write = (path, content) => {
    mkdirSync(dirname(join(root, path)), { recursive: true })
    writeFileSync(join(root, path), content)
  }
  try {
    write(
      'upstream.json',
      JSON.stringify({
        'shadcn-ui': { repo: 'shadcn-ui/ui', commit: COMMIT },
        'ember-primitives': { repo: 'universal-ember/ember-primitives', commit: COMMIT },
      }),
    )
    write(`.upstream/shadcn-ui/${THEMES_FILE}`, THEMES)
    write(`.upstream/shadcn-ui/${BASE_COLORS_FILE}`, BASE_COLORS)
    write(
      `${THEMES_DIR}/slate.css`,
      themeCss({ name: 'slate', title: 'Slate', cssVars: { light: {}, dark: {} } }, COMMIT),
    )
    write(`${THEMES_DIR}/mine.css`, ':root { --mine: 1; }\n')

    assert.throws(
      () => portThemes({ root, check: true, log: () => {} }),
      /slate\.css[\s\S]*neutral\.css/,
    )
    assert.deepEqual(portThemes({ root, log: () => {} }), ['neutral'])
    assert.match(readFileSync(join(root, THEMES_DIR, 'neutral.css'), 'utf8'), /--radius: 0\.625rem/)
    assert.throws(() => readFileSync(join(root, THEMES_DIR, 'slate.css')), /ENOENT/)
    assert.equal(readFileSync(join(root, THEMES_DIR, 'mine.css'), 'utf8'), ':root { --mine: 1; }\n')
    assert.deepEqual(portThemes({ root, check: true, log: () => {} }), ['neutral'])
  } finally {
    rmSync(root, { recursive: true, force: true })
  }
})
