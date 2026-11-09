import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { find, render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import { AspectRatioHarness } from '@ember-joinery/test-support'
import AspectRatioRtl from 'docs-app/examples/aspect-ratio-rtl'

module('Example | aspect-ratio-rtl', function (hooks) {
  setupRenderingTest(hooks)

  test('right to left, a 16:9 figure with its caption', async function (assert) {
    // The guide shows it with dir="rtl" on the preview; a provider does the same here.
    await render(
      <template>
        <DirectionProvider @dir="rtl"><AspectRatioRtl /></DirectionProvider>
      </template>,
    )
    const photo = new AspectRatioHarness()
    assert.deepEqual([photo.width, photo.height], [384, 216], 'max-w-sm at 16:9')
    assert.dom('figcaption').hasText('منظر طبيعي جميل')
    assert.strictEqual(getComputedStyle(find('figure')!).marginLeft, '0px', "m-0, as preflight's")
    assert.strictEqual(getComputedStyle(find('figcaption')!).direction, 'rtl')
    await a11yAudit()
  })
})
