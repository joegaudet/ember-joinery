import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { SkeletonHarness } from '@ember-joinery/test-support'
import SkeletonDemo from 'docs-app/examples/skeleton-demo'

module('Example | skeleton-demo', function (hooks) {
  setupRenderingTest(hooks)

  test('a round avatar and two lines of text, pulsing', async function (assert) {
    await render(<template><SkeletonDemo /></template>)
    const [avatar, first, second] = SkeletonHarness.findAll()
    assert.deepEqual([avatar!.width, avatar!.height], [48, 48], 'h-12 w-12')
    assert.ok(
      Number.parseFloat(getComputedStyle(avatar!.element).borderTopLeftRadius) >= 24,
      'rounded-full',
    )
    assert.deepEqual([first!.width, first!.height], [250, 16])
    assert.deepEqual([second!.width, second!.height], [200, 16])
    assert.strictEqual(getComputedStyle(first!.element).marginBottom, '8px', 'space-y-2')
    for (const skeleton of [avatar!, first!, second!]) assert.true(skeleton.isPulsing)
    await a11yAudit()
  })
})
