import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { find, render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { LabelHarness, SliderHarness } from '@ember-joinery/test-support'
import SliderControlled from 'docs-app/examples/slider-controlled'

module('Example | slider-controlled', function (hooks) {
  setupRenderingTest(hooks)

  test('the parent owns the range, and shows it beside the label', async function (assert) {
    await render(<template><SliderControlled /></template>)
    const slider = new SliderHarness()
    const label = new LabelHarness()
    const shown = () => find('.text-muted-foreground')!.textContent!.trim()

    assert.strictEqual(label.text, 'Temperature')
    assert.deepEqual(slider.value, [0.3, 0.7], 'it shows @value')
    assert.strictEqual(slider.min, 0)
    assert.strictEqual(slider.max, 1)
    assert.deepEqual(slider.labels, ['Minimum', 'Maximum'])
    assert.strictEqual(shown(), '0.3, 0.7')

    await slider.press('ArrowRight', { thumb: 0 })
    assert.deepEqual(slider.value, [0.4, 0.7], 'a step of 0.1, rounded to it')
    assert.strictEqual(shown(), '0.4, 0.7', 'the parent hears it')

    await slider.press('End')
    assert.deepEqual(slider.value, [0.4, 1])
    assert.strictEqual(shown(), '0.4, 1')
    await a11yAudit()
  })
})
