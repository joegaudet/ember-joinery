import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { SkeletonHarness } from '@ember-joinery/test-support'
import SkeletonTable from 'docs-app/examples/skeleton-table'

module('Example | skeleton-table', function (hooks) {
  setupRenderingTest(hooks)

  test('five rows of three cells, loading', async function (assert) {
    await render(<template><SkeletonTable /></template>)
    const cells = SkeletonHarness.findAll()
    assert.strictEqual(cells.length, 15)
    const [first, second, third] = cells
    assert.strictEqual(second!.width, 96, 'w-24')
    assert.strictEqual(third!.width, 80, 'w-20')
    assert.ok(first!.width > second!.width, 'the first cell takes the rest of the row (flex-1)')
    await a11yAudit()
  })
})
