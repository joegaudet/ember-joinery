import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { SliderHarness } from '@ember-joinery/test-support'
import SliderVertical from 'docs-app/examples/slider-vertical'

module('Example | slider-vertical', function (hooks) {
  setupRenderingTest(hooks)

  test('two vertical sliders, which up and down move', async function (assert) {
    await render(<template><SliderVertical /></template>)
    const [first, second] = SliderHarness.findAll()
    assert.strictEqual(first!.orientation, 'vertical')
    assert.strictEqual(second!.orientation, 'vertical')
    assert.deepEqual(first!.value, [50])
    assert.deepEqual(second!.value, [25])
    assert.dom(first!.thumb()).hasAttribute('aria-orientation', 'vertical')
    await first!.press('ArrowUp')
    assert.deepEqual(first!.value, [51])
    await second!.press('ArrowDown')
    assert.deepEqual(second!.value, [24])
    await a11yAudit()
  })
})
