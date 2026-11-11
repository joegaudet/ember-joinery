import { module, test } from 'qunit'
import { exampleNames, exampleTestNames, hasExample, loadExample } from 'docs-app/examples/index'

/** Every file in the examples' folders: `dashboard-01/nav-main.gts`, `lazy/exchange-rates.ts`. */
const folderFiles = Object.keys(
  import.meta.glob(['../../app/examples/*/*.gts', '../../app/examples/*/*.ts']),
)
  .map(path => path.slice('../../app/examples/'.length))
  .sort()

/**
 * Every example in docs-app/app/examples has its test in docs-app/tests/examples, and every
 * test there has its example. Without this, an example with no test would only lose its Test
 * tab, and nothing would fail.
 */
module('Unit | examples', function () {
  test('every example has a test', function (assert) {
    const tested = new Set(exampleTestNames())
    const untested = exampleNames().filter(name => !tested.has(name))
    assert.deepEqual(untested, [], 'add docs-app/tests/examples/<name>-test.gts for each of these')
  })

  test('every example test has its example', function (assert) {
    const examples = new Set(exampleNames())
    const orphans = exampleTestNames().filter(name => !examples.has(name))
    assert.deepEqual(orphans, [], 'these tests have no docs-app/app/examples/<name>.gts')
  })

  test('every example test ends in an axe audit', async function (assert) {
    const unaudited: string[] = []
    for (const name of exampleTestNames()) {
      const example = await loadExample(name)
      if (!example?.test) continue
      // Each test( … ) in the file, up to the next one, calls a11yAudit().
      const tests = example.test.split(/^\s*test\(/m).slice(1)
      tests.forEach((body, index) => {
        if (!body.includes('a11yAudit(')) unaudited.push(`${name}, test ${index + 1}`)
      })
    }
    assert.deepEqual(unaudited, [], 'call a11yAudit() at the end of these tests')
  })

  test("a block's Template tab shows every file in its folder", async function (assert) {
    // A block (dashboard-01.gts) keeps its components in a folder of its name, which readers
    // copy into their app whole, so the Template tab must show all of it: the files its
    // components import (app-sidebar.gts's nav-main.gts) as well as its own imports.
    const folders = [...new Set(folderFiles.map(path => path.split('/')[0]!))].filter(hasExample)
    assert.true(folders.includes('dashboard-01'), 'the blocks are found')
    for (const folder of folders) {
      const example = await loadExample(folder)
      const shown = example!.files.map(file => file.path).sort()
      const inFolder = folderFiles.filter(path => path.startsWith(`${folder}/`))
      assert.deepEqual(shown, inFolder, `${folder}.gts shows all of ${folder}/`)
    }
  })

  test('every file in a folder here shows with an example that imports it', async function (assert) {
    const shown = new Set<string>()
    for (const name of exampleNames()) {
      for (const file of (await loadExample(name))!.files) shown.add(file.path)
    }
    const unshown = folderFiles.filter(path => !shown.has(path))
    assert.deepEqual(unshown, [], 'no example imports these, so no Template tab shows them')
  })
})
