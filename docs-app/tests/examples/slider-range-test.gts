import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { SliderHarness } from '@ember-joinery/test-support'
import SliderRange from 'docs-app/examples/slider-range'

module('Example | slider-range', function (hooks) {
  setupRenderingTest(hooks)

  test('two thumbs make a range, stepping by five', async function (assert) {
    await render(<template><SliderRange /></template>)
    const slider = new SliderHarness()
    assert.deepEqual(slider.value, [25, 50])
    assert.deepEqual(slider.labels, ['Minimum', 'Maximum'])
    await slider.press('ArrowRight', { thumb: 0 })
    assert.deepEqual(slider.value, [30, 50])
    await slider.press('ArrowLeft', { thumb: 1 })
    assert.deepEqual(slider.value, [30, 45])
    await a11yAudit()
  })
})
