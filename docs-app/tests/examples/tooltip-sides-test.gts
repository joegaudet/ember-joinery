import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { TooltipHarness } from '@ember-joinery/test-support'
import TooltipSides from 'docs-app/examples/tooltip-sides'

module('Example | tooltip-sides', function (hooks) {
  setupRenderingTest(hooks)

  test('each button’s tooltip opens on the side it names', async function (assert) {
    await render(<template><TooltipSides /></template>)
    const tooltips = TooltipHarness.findAll()
    assert.deepEqual(
      tooltips.map(tooltip => tooltip.trigger.textContent?.trim()),
      ['left', 'top', 'bottom', 'right'],
    )
    assert.strictEqual(getComputedStyle(tooltips[0]!.trigger).textTransform, 'capitalize')

    for (const tooltip of tooltips) {
      const side = tooltip.trigger.textContent!.trim()
      await tooltip.focus()
      assert.strictEqual(tooltip.text, 'Add to library')
      const opposite = { left: 'right', right: 'left', top: 'bottom', bottom: 'top' }[side]
      assert.true([side, opposite].includes(tooltip.side!), `${side}: placed on ${tooltip.side}`)
      await a11yAudit()
      await tooltip.blur()
    }
  })
})
