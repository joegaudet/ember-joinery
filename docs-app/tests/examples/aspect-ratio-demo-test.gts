import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { AspectRatioHarness } from '@ember-joinery/test-support'
import AspectRatioDemo from 'docs-app/examples/aspect-ratio-demo'

module('Example | aspect-ratio-demo', function (hooks) {
  setupRenderingTest(hooks)

  test('a photo at 16:9, as wide as its max-w-sm column', async function (assert) {
    await render(<template><AspectRatioDemo /></template>)
    const photo = new AspectRatioHarness()
    assert.strictEqual(photo.width, 384, 'max-w-sm')
    assert.strictEqual(photo.height, 216, '384 × 9 / 16')
    const image = photo.element.querySelector('img')!
    assert.dom(image).hasAttribute('alt', 'Photo')
    assert.deepEqual(
      [getComputedStyle(image).width, getComputedStyle(image).height],
      ['384px', '216px'],
      'the image fills it',
    )
    assert.strictEqual(getComputedStyle(photo.element).borderTopLeftRadius, '10px', 'rounded-lg')
    await a11yAudit()
  })
})
