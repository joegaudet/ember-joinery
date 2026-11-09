import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { SliderHarness } from '@ember-joinery/test-support'
import SliderDisabled from 'docs-app/examples/slider-disabled'

module('Example | slider-disabled', function (hooks) {
  setupRenderingTest(hooks)

  test('a disabled slider, out of the tab order', async function (assert) {
    await render(<template><SliderDisabled /></template>)
    const slider = new SliderHarness()
    assert.true(slider.isDisabled)
    assert.deepEqual(slider.value, [50])
    assert.dom(slider.thumb()).doesNotHaveAttribute('tabindex')
    await slider.slideTo(90)
    assert.deepEqual(slider.value, [50], 'a press on it does nothing')
    await a11yAudit()
  })
})
