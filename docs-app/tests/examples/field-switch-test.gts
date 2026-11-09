import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { FieldHarness, LabelHarness, SwitchHarness } from '@ember-joinery/test-support'
import FieldSwitch from 'docs-app/examples/field-switch'

module('Example | field-switch', function (hooks) {
  setupRenderingTest(hooks)

  test('a label, then its switch, side by side', async function (assert) {
    await render(<template><FieldSwitch /></template>)
    const field = new FieldHarness()
    const mfa = field.find(SwitchHarness)

    assert.strictEqual(field.orientation, 'horizontal')
    assert.strictEqual(mfa.label, 'Multi-factor authentication')
    assert.true(
      mfa.element.getBoundingClientRect().left > field.labelElement!.getBoundingClientRect().right,
      'the switch after its label',
    )
    assert.false(mfa.isChecked)
    await field.find(LabelHarness).click()
    assert.true(mfa.isChecked, 'a press on the label turns it on')
    await mfa.toggle()
    assert.false(mfa.isChecked)
    await a11yAudit()
  })
})
