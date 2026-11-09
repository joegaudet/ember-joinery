// Builds @ember-joinery/ember's CSS into dist/ (see "Styling pipeline" in JOINERY_PLAN.md).
// The rollup build runs it after writing the JavaScript; `node build-css.mjs` runs it alone.
//
// Each entry is one shipped file. By default the Tailwind v4 CLI compiles it, which resolves
// the `@apply` rules in the ported style sheets. An entry with `compile: false` ships as
// written: tailwind.css is one, since apps feed its `@theme inline` to their own Tailwind.

import { spawnSync } from 'node:child_process'
import { copyFileSync, existsSync, mkdirSync, readdirSync } from 'node:fs'
import { dirname, join, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'

const packageDir = dirname(fileURLToPath(import.meta.url))

/** @type {{ input: string, output: string, compile?: boolean }[]} input from the package, output from dist/ */
export const entries = [
  // The components' CSS in the default (Nova) style, in `@layer joinery`.
  { input: 'src/joinery.css', output: 'joinery.css' },
]

const tailwind = join(packageDir, 'node_modules', '.bin', 'tailwindcss')

/** Builds every entry into `outDir`, or throws with the Tailwind CLI's output. */
export function buildCss({ outDir = join(packageDir, 'dist') } = {}) {
  for (const entry of entries) {
    const input = resolve(packageDir, entry.input)
    const output = resolve(outDir, entry.output)
    mkdirSync(dirname(output), { recursive: true })

    if (entry.compile === false) {
      copyFileSync(input, output)
      continue
    }

    if (!existsSync(tailwind)) {
      throw new Error(`build-css: ${tailwind} is missing; run pnpm install`)
    }
    const result = spawnSync(tailwind, ['--input', input, '--output', output], {
      cwd: packageDir,
      encoding: 'utf8',
    })
    if (result.status !== 0) {
      throw new Error(`build-css: tailwindcss failed on ${entry.input}\n${result.stderr}`)
    }
  }
}

/**
 * What a CSS rebuild depends on: the entries, and every style sheet under src/ that they
 * `@import` (the ported styles in src/styles/ and the rest).
 */
export function watchedFiles() {
  const files = new Set(entries.map(entry => resolve(packageDir, entry.input)))
  const src = join(packageDir, 'src')
  if (existsSync(src)) {
    for (const name of readdirSync(src, { recursive: true })) {
      if (name.endsWith('.css')) files.add(join(src, name))
    }
  }
  return [...files].sort()
}

/** The rollup plugin: rebuilds the CSS after every (re)build, and watches its sources. */
export function joineryCss() {
  return {
    name: 'joinery-css',
    buildStart() {
      for (const file of watchedFiles()) this.addWatchFile(file)
    },
    writeBundle(options) {
      buildCss({ outDir: options.dir ? resolve(options.dir) : undefined })
    },
  }
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  try {
    buildCss()
  } catch (error) {
    console.error(error.message)
    process.exitCode = 1
  }
}
