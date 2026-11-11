import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { AspectRatioHarness } from '@ember-joinery/test-support'
import AspectRatioHeadless from 'docs-app/examples/aspect-ratio-headless'

module('Example | aspect-ratio-headless', function (hooks) {
  setupRenderingTest(hooks)

  test('a box held to 16:9 at the width of its container', async function (assert) {
    await render(<template><AspectRatioHeadless /></template>)
    const box = new AspectRatioHarness()
    assert.strictEqual(box.width, 256, 'w-64')
    assert.strictEqual(box.height, 144, '256 × 9 / 16')
    assert.dom(box.element).hasText('16 : 9')
    await a11yAudit()
  })
})
