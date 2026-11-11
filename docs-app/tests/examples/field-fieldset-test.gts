import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { FieldSetHarness, InputHarness } from '@ember-joinery/test-support'
import FieldFieldset from 'docs-app/examples/field-fieldset'

module('Example | field-fieldset', function (hooks) {
  setupRenderingTest(hooks)

  test('an address under a legend, the city and postal code side by side', async function (assert) {
    await render(<template><FieldFieldset /></template>)
    const address = new FieldSetHarness()

    assert.strictEqual(address.legend, 'Address Information')
    assert.strictEqual(address.legendVariant, 'legend')
    assert.strictEqual(address.description, 'We need your address to deliver your order.')
    assert.deepEqual(
      address.fields.map(field => field.label),
      ['Street Address', 'City', 'Postal Code'],
    )
    const [, city, zip] = address.fields
    const cityBox = city!.element.getBoundingClientRect()
    const zipBox = zip!.element.getBoundingClientRect()
    assert.strictEqual(Math.round(cityBox.top), Math.round(zipBox.top), 'on one row')
    assert.true(zipBox.left > cityBox.right, 'the postal code after the city')

    await city!.find(InputHarness).fillIn('New York')
    assert.strictEqual(city!.find(InputHarness).value, 'New York')
    await a11yAudit()
  })
})
