import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ButtonHarness, TooltipHarness } from '@ember-joinery/test-support'
import TooltipDemo from 'docs-app/examples/tooltip-demo'

module('Example | tooltip-demo', function (hooks) {
  setupRenderingTest(hooks)

  test('resting the pointer on the button shows its tooltip, which describes it', async function (assert) {
    await render(<template><TooltipDemo /></template>)
    const tooltip = new TooltipHarness()
    const button = new ButtonHarness()
    assert.strictEqual(tooltip.trigger, button.element)
    assert.false(tooltip.isOpen)

    await tooltip.hover()
    assert.true(tooltip.isOpen)
    assert.strictEqual(tooltip.text, 'Add to library')
    assert.strictEqual(
      tooltip.description,
      'Add to library',
      'a screen reader hears it with the button',
    )
    assert.strictEqual(tooltip.side, 'top')
    await a11yAudit()

    await tooltip.unhover()
    assert.false(tooltip.isOpen)

    await tooltip.focus()
    assert.true(tooltip.isOpen, 'focus shows it too')
    await tooltip.pressEscape()
    assert.false(tooltip.isOpen)
    await a11yAudit()
  })
})
