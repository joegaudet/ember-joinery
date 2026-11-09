import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { findAll, render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { SeparatorHarness } from '@ember-joinery/test-support'
import SeparatorList from 'docs-app/examples/separator-list'

module('Example | separator-list', function (hooks) {
  setupRenderingTest(hooks)

  test('horizontal lines between the items of a list', async function (assert) {
    await render(<template><SeparatorList /></template>)
    const separators = SeparatorHarness.findAll()
    assert.strictEqual(separators.length, 2)
    const lists = findAll('dl')
    assert.deepEqual(
      lists.map(list => list.textContent!.replace(/\s+/g, ' ').trim()),
      ['Item 1 Value 1', 'Item 2 Value 2', 'Item 3 Value 3'],
    )
    for (const [index, separator] of separators.entries()) {
      assert.strictEqual(separator.orientation, 'horizontal')
      assert.strictEqual(getComputedStyle(separator.element).height, '1px')
      // Each line sits between two items, with the column's gap-2 on either side.
      const above = lists[index]!.getBoundingClientRect()
      const below = lists[index + 1]!.getBoundingClientRect()
      const line = separator.element.getBoundingClientRect()
      assert.ok(
        above.bottom <= line.top && line.bottom <= below.top,
        `line ${index + 1} is between`,
      )
    }
    assert.strictEqual(getComputedStyle(lists[0]!).marginTop, '0px', "m-0, as preflight's")
    await a11yAudit()
  })
})
