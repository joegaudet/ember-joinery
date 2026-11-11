import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { SliderHarness } from '@ember-joinery/test-support'
import SliderHeadless from 'docs-app/examples/slider-headless'

module('Example | slider-headless', function (hooks) {
  setupRenderingTest(hooks)

  test('a price range that snaps to the prices', async function (assert) {
    await render(<template><SliderHeadless /></template>)
    const slider = new SliderHarness()
    assert.deepEqual(slider.value, [20, 100])
    assert.deepEqual(slider.labels, ['Lowest price', 'Highest price'])
    assert.strictEqual(slider.max, 200)
    await slider.press('ArrowRight', { thumb: 0 })
    assert.deepEqual(slider.value, [50, 100], 'the next price')
    assert.dom('p').hasText('50 to 100 dollars')
    await a11yAudit()
  })
})
