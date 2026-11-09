import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { FieldHarness, InputHarness } from '@ember-joinery/test-support'
import InputDemo from 'docs-app/examples/input-demo'

module('Example | input-demo', function (hooks) {
  setupRenderingTest(hooks)

  test('a password input for an API key, with its label and description', async function (assert) {
    await render(<template><InputDemo /></template>)
    const field = new FieldHarness()
    const key = field.find(InputHarness)

    assert.strictEqual(key.label, 'API Key')
    assert.strictEqual(key.type, 'password')
    assert.strictEqual(key.placeholder, 'sk-...')
    assert.strictEqual(field.description, 'Your API key is encrypted and stored securely.')
    await key.fillIn('sk-123')
    assert.strictEqual(key.value, 'sk-123')
    await a11yAudit()
  })
})
