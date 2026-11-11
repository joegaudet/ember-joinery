// The live demo (test-app/app/components/demo) is the guide's dashboard and settings blocks,
// copied in as an app copies them (blocks aren't exported from a package). This keeps the
// copies honest: each file is the guide's, byte for byte, but for the few the demo adapts to
// its routes, which are listed here. The dashboard's page (dashboard-01.gts) is the demo's
// application template, which wraps it in the demo's root, its outlet and a Toaster: that it
// still renders the guide's page is checked too.
//
//   node --test scripts/demo-blocks.test.mjs

import { test } from 'node:test'
import assert from 'node:assert/strict'
import { existsSync, readdirSync, readFileSync } from 'node:fs'
import { dirname, join, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..')

const COPIES = [
  {
    guide: 'docs-app/app/examples/dashboard-01',
    demo: 'test-app/app/components/demo/dashboard',
    // Settings is a link to the demo's settings route.
    adapted: ['app-sidebar.gts', 'nav-secondary.gts'],
  },
  {
    guide: 'docs-app/app/examples/sidebar-13',
    demo: 'test-app/app/components/demo/settings',
    // The route opens it, each section is a link, and the page behind it is the main.
    adapted: ['settings-dialog.gts'],
  },
]

const files = dir => readdirSync(join(root, dir)).sort()
const read = path => readFileSync(join(root, path), 'utf8')

/**
 * The dashboard's page, which the demo's application template renders as its own. `folder` is
 * where each copies the block's files from, and `adapted` what the template adds to the page.
 */
const PAGE = {
  guide: 'docs-app/app/examples/dashboard-01.gts',
  demo: 'test-app/app/templates/application.gts',
  folder: ['./dashboard-01/', '../components/demo/dashboard/'],
  // The demo names its sidebar, for its tests' SidebarHarness.
  adapted: [' @name="demo"'],
}

/** What a module imports: each source, with the names it takes from it (`default as X`). */
export function imports(source) {
  const found = new Map()
  for (const [, clause, from] of source.matchAll(
    /^import\s+(?:type\s+)?([\s\S]+?)\s+from\s+'([^']+)'/gm,
  )) {
    const names = found.get(from) ?? new Set()
    const braces = clause.match(/\{([\s\S]*)\}/)
    for (const name of braces?.[1].split(',') ?? []) if (name.trim()) names.add(name.trim())
    const bare = clause
      .replace(/\{[\s\S]*\}/, '')
      .replace(/,\s*$/, '')
      .trim()
    if (bare) names.add(`default as ${bare}`)
    found.set(from, names)
  }
  return found
}

/** The lines from the first that starts with `start` to the next that starts with `end`, dedented. */
export function block(source, start, end) {
  const lines = source.split('\n')
  const from = lines.findIndex(line => line.trimStart().startsWith(start))
  const to = lines.findIndex((line, index) => index > from && line.trimStart().startsWith(end))
  assert.ok(from !== -1 && to !== -1, `no lines from ${start} to ${end}`)
  const indent = lines[from].length - lines[from].trimStart().length
  return lines
    .slice(from, to + 1)
    .map(line => line.slice(Math.min(indent, line.length - line.trimStart().length)))
    .join('\n')
}

for (const { guide, demo, adapted } of COPIES) {
  test(`the demo's ${demo} has every file of the guide's ${guide}`, () => {
    assert.deepEqual(files(demo), files(guide))
  })

  test(`the demo's copies of ${guide} are the guide's, but for the files it adapts`, () => {
    for (const file of files(guide)) {
      if (adapted.includes(file)) continue
      const copy = join(root, demo, file)
      assert.ok(existsSync(copy), `${demo}/${file} is missing`)
      assert.equal(
        readFileSync(copy, 'utf8'),
        readFileSync(join(root, guide, file), 'utf8'),
        `${demo}/${file} differs from ${guide}/${file}: copy it again, or list it as adapted`,
      )
    }
  })

  test(`each file ${demo} adapts is one of the guide's`, () => {
    for (const file of adapted) {
      assert.ok(existsSync(join(root, guide, file)), `${guide} has no ${file}`)
    }
  })
}

test(`the demo's ${PAGE.demo} renders the guide's ${PAGE.guide}`, () => {
  const page = read(PAGE.guide)
  const app = read(PAGE.demo)
  const [from, to] = PAGE.folder
  const taken = imports(app)
  for (const [source, names] of imports(page)) {
    const copy = source.startsWith(from) ? to + source.slice(from.length) : source
    for (const name of names) {
      assert.ok(taken.get(copy)?.has(name), `${PAGE.demo} doesn't import ${name} from '${copy}'`)
    }
  }
  assert.equal(block(app, 'const style', ')'), block(page, 'const style', ')'), 'the same style')
  let provider = block(app, '<SidebarProvider', '</SidebarProvider>')
  for (const change of PAGE.adapted) provider = provider.replace(change, '')
  assert.equal(
    provider,
    block(page, '<SidebarProvider', '</SidebarProvider>'),
    `${PAGE.demo}'s SidebarProvider differs from ${PAGE.guide}'s: copy it again, or list the change as adapted`,
  )
})

test('imports() and block() read a page as the copy check needs', () => {
  const source = [
    "import { htmlSafe } from '@ember/template'",
    "import { A, type B } from 'x'",
    "import C, { D } from 'y'",
    'import {',
    '  E,',
    '  F,',
    "} from 'z'",
    '',
    '<template>',
    '    <P as |p|>',
    '      <p.Q />',
    '    </P>',
    '</template>',
  ].join('\n')
  const found = imports(source)
  assert.deepEqual([...found.get('@ember/template')], ['htmlSafe'])
  assert.deepEqual([...found.get('x')], ['A', 'type B'])
  assert.deepEqual([...found.get('y')], ['D', 'default as C'])
  assert.deepEqual([...found.get('z')], ['E', 'F'])
  assert.equal(block(source, '<P', '</P>'), '<P as |p|>\n  <p.Q />\n</P>')
  assert.throws(() => block(source, '<R', '</R>'), /no lines from <R to <\/R>/)
})
