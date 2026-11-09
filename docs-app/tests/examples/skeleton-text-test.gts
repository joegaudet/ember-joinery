import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { SkeletonHarness } from '@ember-joinery/test-support'
import SkeletonText from 'docs-app/examples/skeleton-text'

module('Example | skeleton-text', function (hooks) {
  setupRenderingTest(hooks)

  test('a paragraph loading: two full lines and a shorter last one', async function (assert) {
    await render(<template><SkeletonText /></template>)
    const [first, second, last] = SkeletonHarness.findAll()
    assert.strictEqual(first!.width, second!.width)
    assert.strictEqual(last!.width, first!.width * 0.75, 'w-3/4')
    for (const line of [first!, second!, last!]) assert.strictEqual(line.height, 16)
    await a11yAudit()
  })
})
