import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { find, render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { InputHarness } from '@ember-joinery/test-support'
import InputControlled from 'docs-app/examples/input-controlled'

module('Example | input-controlled', function (hooks) {
  setupRenderingTest(hooks)

  test('the parent owns the username, and keeps it lower case without spaces', async function (assert) {
    await render(<template><InputControlled /></template>)
    const username = new InputHarness('username')
    const profile = () => find('[data-test-username]')!.textContent!.trim()

    assert.strictEqual(username.value, 'ada', 'it shows @value')
    assert.strictEqual(username.label, 'Username')

    await username.fillIn('Grace Hopper')
    assert.strictEqual(username.value, 'gracehopper', 'it shows what the parent made of it')
    assert.strictEqual(profile(), 'example.com/@gracehopper')
    await a11yAudit()
  })
})
