import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { SliderHarness } from '@ember-joinery/test-support'
import SliderMultiple from 'docs-app/examples/slider-multiple'

module('Example | slider-multiple', function (hooks) {
  setupRenderingTest(hooks)

  test('three thumbs, stepping by ten', async function (assert) {
    await render(<template><SliderMultiple /></template>)
    const slider = new SliderHarness()
    assert.deepEqual(slider.value, [10, 20, 70])
    assert.deepEqual(slider.labels, ['Value 1 of 3', 'Value 2 of 3', 'Value 3 of 3'])
    await slider.press('ArrowUp', { thumb: 1 })
    assert.deepEqual(slider.value, [10, 30, 70])
    await slider.press('End', { thumb: 2 })
    assert.deepEqual(slider.value, [10, 30, 100])
    await a11yAudit()
  })
})
