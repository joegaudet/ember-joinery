import { module, test } from 'qunit'
import { exampleNames, exampleTestNames, loadExample } from 'docs-app/examples/index'

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
      if (example?.test && !example.test.includes('a11yAudit(')) unaudited.push(name)
    }
    assert.deepEqual(unaudited, [], 'call a11yAudit() at the end of these tests')
  })
})
