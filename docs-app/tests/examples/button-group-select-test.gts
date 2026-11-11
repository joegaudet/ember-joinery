import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ButtonGroupHarness, InputHarness, SelectHarness } from '@ember-joinery/test-support'
import ButtonGroupSelect from 'docs-app/examples/button-group-select'

const style = (element: Element) => getComputedStyle(element)

module('Example | button-group-select', function (hooks) {
  setupRenderingTest(hooks)

  test('a currency select joined to an amount, and a send button', async function (assert) {
    await render(<template><ButtonGroupSelect /></template>)
    const select = new SelectHarness()
    const amount = new InputHarness()
    assert.strictEqual(select.valueText, '$')
    assert.strictEqual(amount.placeholder, '10.00')

    // The select's trigger is inside its root, which the group's rules reach through.
    assert.strictEqual(style(select.trigger).borderTopRightRadius, '0px', 'joined to the input')
    assert.strictEqual(style(amount.element).borderTopLeftRadius, '0px')
    assert.strictEqual(style(amount.element).borderLeftWidth, '0px')
    assert.notStrictEqual(style(amount.element).borderTopRightRadius, '0px')

    const [, send] = new ButtonGroupHarness().groups
    assert.strictEqual(send!.buttons[0]!.label, 'Send')

    await select.open()
    assert.deepEqual(select.optionTexts, ['$ US Dollar', '€ Euro', '£ British Pound'])
    await a11yAudit()

    await select.select('€')
    assert.strictEqual(select.value, '€')
    assert.strictEqual(select.valueText, '€')
    await amount.fillIn('25.00')
    assert.strictEqual(amount.value, '25.00')
    await a11yAudit()
  })
})
