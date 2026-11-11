import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ButtonHarness, KbdHarness, TooltipHarness, child } from '@ember-joinery/test-support'
import TooltipKeyboard from 'docs-app/examples/tooltip-keyboard'

/** The save button's tooltip: a page object, with the key it shows declared. */
class SaveTooltip extends TooltipHarness {
  @child(KbdHarness) declare shortcut: KbdHarness
}

module('Example | tooltip-keyboard', function (hooks) {
  setupRenderingTest(hooks)

  test('an icon button’s tooltip shows its keyboard shortcut', async function (assert) {
    await render(<template><TooltipKeyboard /></template>)
    const tooltip = new SaveTooltip()
    const button = new ButtonHarness()
    assert.strictEqual(tooltip.trigger, button.element)
    assert.strictEqual(button.variant, 'outline')
    assert.strictEqual(button.size, 'icon-sm')
    assert.strictEqual(button.label, 'Save Changes')
    assert.false(tooltip.isOpen)

    await tooltip.hover()
    assert.true(tooltip.isOpen)
    assert.strictEqual(tooltip.text, 'Save Changes S')
    assert.strictEqual(tooltip.shortcut.label, 'S', 'the shortcut is a Kbd')
    assert.strictEqual(
      tooltip.description,
      'Save Changes S',
      'a screen reader hears it, shortcut and all, with the button',
    )
    const key = getComputedStyle(tooltip.shortcut.element)
    const content = getComputedStyle(tooltip.content!)
    assert.strictEqual(key.color, content.color, 'the key takes the tooltip’s text colour')
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
