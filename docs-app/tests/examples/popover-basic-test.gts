import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ButtonHarness, PopoverHarness } from '@ember-joinery/test-support'
import PopoverBasic from 'docs-app/examples/popover-basic'

module('Example | popover-basic', function (hooks) {
  setupRenderingTest(hooks)

  test('the button opens a popover with a title and a description, at its start', async function (assert) {
    await render(<template><PopoverBasic /></template>)
    const popover = new PopoverHarness()
    const button = new ButtonHarness()
    assert.strictEqual(button.label, 'Open Popover')
    assert.strictEqual(button.variant, 'outline')
    assert.false(popover.isOpen)

    await button.click()
    assert.true(popover.isOpen)
    assert.strictEqual(popover.label, 'Dimensions', 'its title names it')
    assert.strictEqual(popover.description, 'Set the dimensions for the layer.')
    assert.strictEqual(popover.align, 'start')
    await a11yAudit()

    await popover.pressEscape()
    assert.false(popover.isOpen)
    assert.true(button.isFocused, 'focus is back on the button')
    await a11yAudit()
  })
})
