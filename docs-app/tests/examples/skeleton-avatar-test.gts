import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { SkeletonHarness } from '@ember-joinery/test-support'
import SkeletonAvatar from 'docs-app/examples/skeleton-avatar'

module('Example | skeleton-avatar', function (hooks) {
  setupRenderingTest(hooks)

  test('an avatar and a name and handle, loading', async function (assert) {
    await render(<template><SkeletonAvatar /></template>)
    const sizes = SkeletonHarness.findAll().map(skeleton => [skeleton.width, skeleton.height])
    assert.deepEqual(sizes, [
      [40, 40],
      [150, 16],
      [100, 16],
    ])
    await a11yAudit()
  })
})
