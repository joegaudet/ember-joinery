import { test } from 'node:test'
import assert from 'node:assert/strict'
import { existsSync, readFileSync, readdirSync } from 'node:fs'
import { join } from 'node:path'
import { layered, topLevel } from '../packages/ember/build-css.mjs'
import { repoRoot } from './upstream.mjs'

const dist = join(repoRoot, 'packages/ember/dist')

test('topLevel splits CSS into its statements and blocks, past comments and strings', () => {
  const css = `/*! a banner { } */
@layer properties;
@property --x { syntax: "*"; inherits: false; }
a { content: "}"; }
@layer joinery { :where(.b) { color: red; } }`
  assert.deepEqual(
    topLevel(css).map(block => block.text),
    [
      '@layer properties;',
      '@property --x { syntax: "*"; inherits: false; }',
      'a { content: "}"; }',
      '@layer joinery { :where(.b) { color: red; } }',
    ],
  )
})

test("layered keeps what Tailwind emits for the rules, and drops shadcn's unlayered .shimmer rule", () => {
  const css = `/*! tailwindcss */
@layer properties;
@property --shimmer-angle {
  syntax: "<angle>";
  inherits: true;
  initial-value: 20deg;
}
@media (prefers-reduced-motion: reduce) {
  .shimmer {
    animation: none;
    background-image: none;
    -webkit-text-fill-color: currentColor;
  }
}
@layer joinery {
  :where(.jn-x) { color: red; }
}
@keyframes spin { to { transform: rotate(360deg); } }
@layer properties { @supports (x: y) { :root, :host { --shimmer-angle: 20deg; } } }
`
  const out = layered(css, 'nova')
  assert.doesNotMatch(out, /\.shimmer/)
  assert.match(out, /@property --shimmer-angle/)
  assert.match(out, /@layer joinery \{\n {2}:where\(\.jn-x\)/)
  assert.match(out, /@keyframes spin/)
  assert.match(out, /@layer properties \{ @supports/)
})

test('layered fails on any other CSS outside a layer', () => {
  assert.throws(
    () => layered('@layer joinery { :where(.a) { color: red; } }\n.b { color: blue; }\n', 'lyra'),
    /the lyra style has CSS outside @layer joinery[^]*\.b \{ color: blue; \}/,
  )
  assert.throws(
    () => layered('@media (hover: hover) { .c { color: red; } }'),
    /outside @layer joinery/,
  )
})

test(
  'every compiled style is layered',
  { skip: !existsSync(join(dist, 'joinery.css')) && 'build the packages first' },
  () => {
    const files = [
      join(dist, 'joinery.css'),
      ...readdirSync(join(dist, 'styles')).map(name => join(dist, 'styles', name)),
    ]
    assert.strictEqual(files.length, 8)
    for (const file of files) {
      const css = readFileSync(file, 'utf8')
      assert.strictEqual(layered(css, file), css, `${file} has nothing unlayered`)
      assert.doesNotMatch(css, /^\s*\.shimmer\b/m, file)
    }
  },
)
