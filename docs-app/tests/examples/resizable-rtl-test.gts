import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import { ResizableHarness } from '@ember-joinery/test-support'
import ResizableRtl from 'docs-app/examples/resizable-rtl'

module('Example | resizable-rtl', function (hooks) {
  setupRenderingTest(hooks)

  test('right to left, the first panel is on the right, and Left grows it', async function (assert) {
    // The guide shows it with dir="rtl" on the preview; a provider does the same here.
    await render(
      <template>
        <DirectionProvider @dir="rtl"><ResizableRtl /></DirectionProvider>
      </template>,
    )
    const [outer, inner] = ResizableHarness.findAll()
    const [first, second] = outer!.panels
    assert.dom(first).containsText('واحد')
    assert.true(first!.offsetLeft > second!.offsetLeft, 'the first panel is on the right')
    assert.deepEqual(inner!.sizes, [25, 75])

    await outer!.press(0, 'ArrowLeft')
    assert.deepEqual(outer!.sizes, [55, 45], 'Left moves the handle left: the first panel grows')
    await outer!.drag(0, 38)
    assert.deepEqual(outer!.sizes.map(Math.round), [45, 55], 'a drag right shrinks it')
    await a11yAudit()
  })
})
