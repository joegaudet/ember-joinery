import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ProgressHarness, SliderHarness } from '@ember-joinery/test-support'
import ProgressControlled from 'docs-app/examples/progress-controlled'

module('Example | progress-controlled', function (hooks) {
  setupRenderingTest(hooks)

  test('the slider sets the bar', async function (assert) {
    await render(<template><ProgressControlled /></template>)
    const progress = new ProgressHarness()
    const slider = new SliderHarness()

    assert.strictEqual(progress.value, 50)
    assert.strictEqual(progress.label, 'Progress')
    assert.deepEqual(slider.value, [50])
    assert.deepEqual(slider.labels, ['Value'])

    await slider.press('ArrowRight')
    assert.deepEqual(slider.value, [51])
    assert.strictEqual(progress.value, 51, 'the bar follows the slider')

    await slider.press('PageUp')
    assert.strictEqual(progress.value, 61)
    assert.strictEqual(progress.valueText, '61%')

    await slider.slideTo(25)
    assert.strictEqual(progress.value, 25, 'a press a quarter of the way along')
    assert.dom(progress.indicator).hasAttribute('style', 'transform: translateX(-75%)')
    await a11yAudit()
  })
})
