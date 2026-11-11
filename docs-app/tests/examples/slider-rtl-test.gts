import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { SliderHarness } from '@ember-joinery/test-support'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import SliderRtl from 'docs-app/examples/slider-rtl'

module('Example | slider-rtl', function (hooks) {
  setupRenderingTest(hooks)

  test('right to left, the range fills from the right and the left arrow steps up', async function (assert) {
    // The guide shows it with dir="rtl" on the preview; a provider does the same here.
    await render(
      <template>
        <DirectionProvider @dir="rtl"><SliderRtl /></DirectionProvider>
      </template>,
    )
    const slider = new SliderHarness()
    const root = slider.element.getBoundingClientRect()
    const range = slider.part('range').getBoundingClientRect()
    assert.true(Math.abs(root.right - range.right) < 1, 'the range starts on the right')
    assert.true(range.left > root.left, 'and stops short of the left')
    await slider.press('ArrowLeft')
    assert.deepEqual(slider.value, [76])
    await a11yAudit()
  })
})
