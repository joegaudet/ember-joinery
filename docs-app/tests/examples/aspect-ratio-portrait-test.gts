import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { AspectRatioHarness } from '@ember-joinery/test-support'
import AspectRatioPortrait from 'docs-app/examples/aspect-ratio-portrait'

module('Example | aspect-ratio-portrait', function (hooks) {
  setupRenderingTest(hooks)

  test('a portrait photo at 9:16, 10rem across', async function (assert) {
    await render(<template><AspectRatioPortrait /></template>)
    const photo = new AspectRatioHarness()
    assert.strictEqual(photo.width, 160)
    assert.strictEqual(Math.round(photo.height * 100) / 100, 284.44, '160 × 16 / 9')
    assert.ok(photo.ratio < 1, 'taller than it is wide')
    await a11yAudit()
  })
})
