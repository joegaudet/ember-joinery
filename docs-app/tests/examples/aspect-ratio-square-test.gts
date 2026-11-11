import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { AspectRatioHarness } from '@ember-joinery/test-support'
import AspectRatioSquare from 'docs-app/examples/aspect-ratio-square'

module('Example | aspect-ratio-square', function (hooks) {
  setupRenderingTest(hooks)

  test('a square photo, 12rem across', async function (assert) {
    await render(<template><AspectRatioSquare /></template>)
    const photo = new AspectRatioHarness()
    assert.deepEqual([photo.width, photo.height], [192, 192])
    assert.strictEqual(photo.ratio, 1)
    assert.dom(photo.element.querySelector('img')).hasAttribute('alt', 'Photo')
    await a11yAudit()
  })
})
