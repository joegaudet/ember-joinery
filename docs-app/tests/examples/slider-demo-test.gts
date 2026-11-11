import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { SliderHarness } from '@ember-joinery/test-support'
import SliderDemo from 'docs-app/examples/slider-demo'

module('Example | slider-demo', function (hooks) {
  setupRenderingTest(hooks)

  test('one thumb at 75, which the arrow keys step by one', async function (assert) {
    await render(<template><SliderDemo /></template>)
    const slider = new SliderHarness()
    assert.deepEqual(slider.value, [75])
    assert.strictEqual(slider.max, 100)
    assert.deepEqual(slider.labels, ['Value'], 'named, though upstream names it nothing')
    await slider.press('ArrowRight')
    assert.deepEqual(slider.value, [76])
    await slider.press('Home')
    assert.deepEqual(slider.value, [0])
    await a11yAudit()
  })
})
