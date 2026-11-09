import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { FieldHarness, SwitchHarness } from '@ember-joinery/test-support'
import SwitchInvalid from 'docs-app/examples/switch-invalid'

module('Example | switch-invalid', function (hooks) {
  setupRenderingTest(hooks)

  test('an invalid switch, its field in the destructive colour', async function (assert) {
    await render(<template><SwitchInvalid /></template>)
    const field = new FieldHarness()
    const terms = field.find(SwitchHarness)

    assert.true(field.isInvalid)
    assert.true(terms.isInvalid)
    assert.strictEqual(terms.label, 'Accept terms and conditions')
    assert.strictEqual(field.description, 'You must accept the terms and conditions to continue.')
    assert.strictEqual(
      getComputedStyle(field.labelElement!).color,
      getComputedStyle(field.element).color,
    )
    await terms.check()
    assert.true(terms.isChecked)
    await a11yAudit()
  })
})
