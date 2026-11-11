import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import { SkeletonHarness } from '@ember-joinery/test-support'
import SkeletonRtl from 'docs-app/examples/skeleton-rtl'

module('Example | skeleton-rtl', function (hooks) {
  setupRenderingTest(hooks)

  test('right to left, the avatar is on the right and the lines start there', async function (assert) {
    // The guide shows it with dir="rtl" on the preview; a provider does the same here.
    await render(
      <template>
        <DirectionProvider @dir="rtl"><SkeletonRtl /></DirectionProvider>
      </template>,
    )
    const [avatar, first, second] = SkeletonHarness.findAll()
    const avatarBox = avatar!.element.getBoundingClientRect()
    const firstBox = first!.element.getBoundingClientRect()
    const secondBox = second!.element.getBoundingClientRect()
    assert.ok(avatarBox.left > firstBox.right, 'the avatar is on the right')
    assert.strictEqual(secondBox.right, firstBox.right, 'both lines start at the right')
    assert.ok(secondBox.left > firstBox.left, 'the shorter one ends sooner')
    await a11yAudit()
  })
})
