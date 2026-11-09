import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ButtonHarness, FieldGroupHarness, InputHarness } from '@ember-joinery/test-support'
import InputFieldgroup from 'docs-app/examples/input-fieldgroup'

module('Example | input-fieldgroup', function (hooks) {
  setupRenderingTest(hooks)

  test('a name and an email, then Reset and Submit side by side', async function (assert) {
    await render(<template><InputFieldgroup /></template>)
    const group = new FieldGroupHarness()
    const [name, email, actions] = group.fields

    assert.strictEqual(name!.label, 'Name')
    assert.strictEqual(email!.find(InputHarness).type, 'email')
    assert.strictEqual(email!.description, "We'll send updates to this address.")
    assert.strictEqual(actions!.orientation, 'horizontal')
    assert.deepEqual(
      actions!.findAll(ButtonHarness).map(button => [button.text, button.variant]),
      [
        ['Reset', 'outline'],
        ['Submit', 'default'],
      ],
    )
    await name!.find(InputHarness).fillIn('Ada')
    assert.strictEqual(name!.find(InputHarness).value, 'Ada')
    await a11yAudit()
  })
})
