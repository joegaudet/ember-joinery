import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import {
  ButtonHarness,
  FieldHarness,
  InputHarness,
  SelectHarness,
} from '@ember-joinery/test-support'
import InputForm from 'docs-app/examples/input-form'

module('Example | input-form', function (hooks) {
  setupRenderingTest(hooks)

  test('name, email, phone, country and address, then Cancel and Submit', async function (assert) {
    await render(<template><InputForm /></template>)
    const fields = new FieldHarness().element.closest('form')!
    const labels = [...fields.querySelectorAll('[data-slot="field-label"]')].map(label =>
      label.textContent!.trim(),
    )
    assert.deepEqual(labels, ['Name', 'Email', 'Phone', 'Country', 'Address'])

    const inputs = new InputHarness().element.closest('form')!
    assert.dom('#form-name', inputs).hasAttribute('required')
    assert.dom('#form-email', inputs).hasAttribute('type', 'email')
    assert.dom('#form-phone', inputs).hasAttribute('type', 'tel')

    const country = new SelectHarness()
    assert.strictEqual(country.label, 'Country')
    assert.strictEqual(country.valueText, 'United States')
    const phone = inputs.querySelector<HTMLElement>('#form-phone')!
    assert.strictEqual(
      country.trigger.offsetWidth,
      phone.offsetWidth,
      'the select fills its column, as the phone input does',
    )
    await country.open()
    assert.deepEqual(country.optionTexts, ['United States', 'United Kingdom', 'Canada'])
    await a11yAudit()
    await country.pressOption('ca')
    assert.strictEqual(country.valueText, 'Canada')

    const cancel = new ButtonHarness({ index: 0 })
    assert.strictEqual(cancel.text, 'Cancel')
    assert.strictEqual(cancel.variant, 'outline')
    assert.strictEqual(new ButtonHarness({ index: 1 }).text, 'Submit')
    await a11yAudit()
  })
})
