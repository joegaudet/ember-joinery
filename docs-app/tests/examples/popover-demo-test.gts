import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ButtonHarness, InputHarness, PopoverHarness, child } from '@ember-joinery/test-support'
import PopoverDemo from 'docs-app/examples/popover-demo'

/** The dimensions popover: a page object, with its four fields declared. */
class DimensionsPopover extends PopoverHarness {
  @child(InputHarness, { index: 0 }) declare width: InputHarness
  @child(InputHarness, { index: 1 }) declare maxWidth: InputHarness
  @child(InputHarness, { index: 2 }) declare height: InputHarness
  @child(InputHarness, { index: 3 }) declare maxHeight: InputHarness
}

module('Example | popover-demo', function (hooks) {
  setupRenderingTest(hooks)

  test('the button opens a wider popover of labelled fields for the dimensions', async function (assert) {
    await render(<template><PopoverDemo /></template>)
    const popover = new DimensionsPopover()
    const button = new ButtonHarness()
    assert.strictEqual(button.label, 'Open popover')
    assert.strictEqual(button.variant, 'outline')
    assert.false(popover.isOpen)

    await button.click()
    assert.true(popover.isOpen)
    assert.true(popover.isShown, 'in the top layer')
    assert.strictEqual(popover.label, 'Open popover', 'with no Title, its trigger names it')
    assert.strictEqual(getComputedStyle(popover.content!).width, '320px', 'w-80')
    assert.true(popover.width.isFocused, 'focus goes to the first field')

    assert.strictEqual(popover.width.label, 'Width', 'each label names its field')
    assert.strictEqual(popover.width.value, '100%')
    assert.strictEqual(popover.maxWidth.label, 'Max. width')
    assert.strictEqual(popover.maxWidth.value, '300px')
    assert.strictEqual(popover.height.label, 'Height')
    assert.strictEqual(popover.height.value, '25px')
    assert.strictEqual(popover.maxHeight.label, 'Max. height')
    assert.strictEqual(popover.maxHeight.value, 'none')
    await a11yAudit()

    await popover.height.fillIn('40px')
    assert.strictEqual(popover.height.value, '40px')
    assert.true(popover.isOpen, 'typing keeps it open')

    await popover.pressEscape()
    assert.false(popover.isOpen)
    assert.true(button.isFocused, 'focus is back on the button')
    await a11yAudit()
  })
})
