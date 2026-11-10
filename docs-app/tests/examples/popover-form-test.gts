import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import {
  ButtonHarness,
  FieldHarness,
  InputHarness,
  PopoverHarness,
  child,
} from '@ember-joinery/test-support'
import PopoverForm from 'docs-app/examples/popover-form'

/** The dimensions popover: a page object, with its two fields declared. */
class DimensionsPopover extends PopoverHarness {
  @child(FieldHarness, { index: 0 }) declare widthField: FieldHarness
  @child(FieldHarness, { index: 1 }) declare heightField: FieldHarness
  @child(InputHarness, { index: 0 }) declare width: InputHarness
  @child(InputHarness, { index: 1 }) declare height: InputHarness
}

module('Example | popover-form', function (hooks) {
  setupRenderingTest(hooks)

  test('the button opens a popover with a header and two horizontal fields', async function (assert) {
    await render(<template><PopoverForm /></template>)
    const popover = new DimensionsPopover()
    const button = new ButtonHarness()
    assert.strictEqual(button.label, 'Open Popover')
    assert.strictEqual(button.variant, 'outline')
    assert.false(popover.isOpen)

    await button.click()
    assert.true(popover.isOpen)
    assert.true(popover.isShown, 'in the top layer')
    assert.strictEqual(popover.title, 'Dimensions')
    assert.strictEqual(popover.label, 'Dimensions', 'its Title names it')
    assert.strictEqual(popover.description, 'Set the dimensions for the layer.')
    assert.strictEqual(popover.align, 'start')
    assert.strictEqual(getComputedStyle(popover.content!).width, '256px', 'w-64')

    assert.strictEqual(popover.widthField.orientation, 'horizontal')
    assert.strictEqual(popover.heightField.orientation, 'horizontal')
    assert.strictEqual(popover.width.label, 'Width', 'each label names its input')
    assert.strictEqual(popover.width.value, '100%')
    assert.strictEqual(popover.height.label, 'Height')
    assert.strictEqual(popover.height.value, '25px')
    const label = popover.widthField.labelElement!.getBoundingClientRect()
    const input = popover.width.element.getBoundingClientRect()
    assert.strictEqual(
      Math.round(label.top + label.height / 2),
      Math.round(input.top + input.height / 2),
      'side by side',
    )
    assert.ok(label.right <= input.left)
    await a11yAudit()

    await popover.height.fillIn('40px')
    assert.strictEqual(popover.height.value, '40px')
    await popover.pressEscape()
    assert.false(popover.isOpen)
    assert.true(button.isFocused, 'focus is back on the button')
    await a11yAudit()
  })
})
