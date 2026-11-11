import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ButtonGroupHarness, InputGroupHarness, TooltipHarness } from '@ember-joinery/test-support'
import ButtonGroupNested from 'docs-app/examples/button-group-nested'

module('Example | button-group-nested', function (hooks) {
  setupRenderingTest(hooks)

  test('a button and an input group, spaced, the addon with a tooltip', async function (assert) {
    await render(<template><ButtonGroupNested /></template>)
    const outer = new ButtonGroupHarness()
    assert.strictEqual(outer.groups.length, 2)
    assert.strictEqual(getComputedStyle(outer.element).columnGap, '8px')
    const message = new InputGroupHarness()
    assert.strictEqual(message.placeholder, 'Send a message...')

    // The addon is the tooltip's trigger, inside the tooltip's root (so it is the tooltip's
    // part, not the input group's); the input still narrows its padding beside it, as beside
    // an addon of its own.
    const tooltip = new TooltipHarness()
    assert.strictEqual(tooltip.trigger.dataset['slot'], 'input-group-addon')
    assert.strictEqual(tooltip.trigger.dataset['align'], 'inline-end')
    assert.strictEqual(getComputedStyle(message.control).paddingRight, '6px', 'pe-1.5')
    await tooltip.hover()
    assert.strictEqual(tooltip.text, 'Voice Mode')
    await a11yAudit()
  })
})
