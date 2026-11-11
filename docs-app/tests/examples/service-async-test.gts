import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { Harness } from '@ember-joinery/test-support'
import ServiceAsync from 'docs-app/examples/service-async'

class PriceHarness extends Harness {
  static component = 'price'

  get text() {
    return this.element.textContent!.replace(/\s+/g, ' ').trim()
  }
}

module('Example | service-async', function (hooks) {
  setupRenderingTest(hooks)

  test('the rates load once, then every price converts with them', async function (assert) {
    await render(<template><ServiceAsync /></template>)
    // render() waits for the import, as it waits for any pending promise.
    assert.strictEqual(new PriceHarness('USD').text, '€20 is 21.60 USD')
    assert.strictEqual(new PriceHarness('GBP').text, '€20 is 17.00 GBP')
    assert.strictEqual(new PriceHarness('JPY').text, '€20 is 3248.00 JPY')
    await a11yAudit()
  })
})
