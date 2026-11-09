import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ButtonHarness, TooltipHarness } from '@ember-joinery/test-support'
import TooltipDisabled from 'docs-app/examples/tooltip-disabled'

module('Example | tooltip-disabled', function (hooks) {
  setupRenderingTest(hooks)

  test('a disabled button shows a tooltip through the span around it', async function (assert) {
    await render(<template><TooltipDisabled /></template>)
    const tooltip = new TooltipHarness()
    const button = new ButtonHarness()
    assert.true(button.isDisabled)
    assert.dom(tooltip.trigger).hasTagName('span', 'the span is the trigger')
    assert.strictEqual(
      getComputedStyle(button.element).pointerEvents,
      'none',
      'the disabled button lets the pointer through to it',
    )

    await tooltip.hover()
    assert.true(tooltip.isOpen)
    assert.strictEqual(tooltip.text, 'This feature is currently unavailable')
    await a11yAudit()
  })
})
