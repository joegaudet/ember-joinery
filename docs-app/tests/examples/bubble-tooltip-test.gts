import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { BubbleHarness, ButtonHarness, TooltipHarness } from '@ember-joinery/test-support'
import BubbleTooltip from 'docs-app/examples/bubble-tooltip'

module('Example | bubble-tooltip', function (hooks) {
  setupRenderingTest(hooks)

  test("a check in the bubble's reactions shows when the message was read", async function (assert) {
    await render(<template><BubbleTooltip /></template>)
    const [question, answer] = BubbleHarness.findAll()
    assert.strictEqual(question!.variant, 'secondary')
    assert.strictEqual(answer!.text, 'Yes, removed it from the registry.')
    assert.strictEqual(getComputedStyle(answer!.reactions).paddingTop, '0px', 'p-0')

    const read = answer!.find(ButtonHarness)
    assert.strictEqual(read.label, 'Read')
    assert.strictEqual(read.size, 'icon-xs')
    const tooltip = new TooltipHarness()
    assert.strictEqual(tooltip.trigger, read.element)

    await tooltip.hover()
    assert.true(tooltip.isOpen)
    assert.strictEqual(tooltip.text, 'Read on Jan 5, 2026 at 4:32 PM')
    assert.strictEqual(tooltip.description, 'Read on Jan 5, 2026 at 4:32 PM')
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
