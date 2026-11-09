import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import { TooltipHarness } from '@ember-joinery/test-support'
import TooltipRtl from 'docs-app/examples/tooltip-rtl'

module('Example | tooltip-rtl', function (hooks) {
  setupRenderingTest(hooks)

  test('right to left, each tooltip opens on its own physical side', async function (assert) {
    // The guide shows it with dir="rtl" on the preview; a provider does the same here.
    await render(
      <template>
        <DirectionProvider @dir="rtl"><TooltipRtl /></DirectionProvider>
      </template>,
    )
    const tooltips = TooltipHarness.findAll()
    assert.deepEqual(
      tooltips.map(tooltip => tooltip.trigger.textContent?.trim()),
      ['يسار', 'أعلى', 'أسفل', 'يمين'],
    )
    const sides = ['left', 'top', 'bottom', 'right']
    for (const [index, tooltip] of tooltips.entries()) {
      await tooltip.focus()
      assert.strictEqual(tooltip.description, 'إضافة إلى المكتبة')
      const side = sides[index]!
      const opposite = { left: 'right', right: 'left', top: 'bottom', bottom: 'top' }[side]
      assert.true([side, opposite].includes(tooltip.side!), `${side}: placed on ${tooltip.side}`)
      await a11yAudit()
      await tooltip.blur()
    }
  })
})
