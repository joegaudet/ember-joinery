// The live demo (test-app/app/components/demo) is the guide's dashboard and settings blocks,
// copied in as an app copies them (blocks aren't exported from a package). This keeps the
// copies honest: each file is the guide's, byte for byte, but for the few the demo adapts to
// its routes, which are listed here.
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
