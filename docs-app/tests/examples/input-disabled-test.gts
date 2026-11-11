import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { FieldHarness, InputHarness } from '@ember-joinery/test-support'
import InputDisabled from 'docs-app/examples/input-disabled'

module('Example | input-disabled', function (hooks) {
  setupRenderingTest(hooks)

  test('a disabled email input, its field dimmed', async function (assert) {
    await render(<template><InputDisabled /></template>)
    const field = new FieldHarness()
    const email = field.find(InputHarness)

    assert.true(email.isDisabled)
    assert.true(field.isDisabled)
    assert.strictEqual(getComputedStyle(field.labelElement!).opacity, '0.5')
    assert.strictEqual(field.description, 'This field is currently disabled.')
    await a11yAudit()
  })
})
