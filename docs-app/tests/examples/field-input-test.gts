import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { FieldHarness, FieldSetHarness, InputHarness } from '@ember-joinery/test-support'
import FieldInput from 'docs-app/examples/field-input'

module('Example | field-input', function (hooks) {
  setupRenderingTest(hooks)

  test('a username and a password, each with its help text', async function (assert) {
    await render(<template><FieldInput /></template>)
    const [username, password] = new FieldSetHarness().fields

    assert.strictEqual(username!.label, 'Username')
    assert.strictEqual(username!.description, 'Choose a unique username for your account.')
    assert.strictEqual(password!.label, 'Password')
    assert.strictEqual(password!.description, 'Must be at least 8 characters long.')

    const name = username!.find(InputHarness)
    assert.strictEqual(name.label, 'Username', 'the field label names its input')
    assert.strictEqual(name.placeholder, 'Max Leiter')
    await name.fillIn('maxleiter')
    assert.strictEqual(name.value, 'maxleiter')
    assert.strictEqual(password!.find(InputHarness).type, 'password')
    assert.strictEqual(password!.control, password!.find(InputHarness).element)
    await a11yAudit()
  })

  test('the description sits under its input in the first field, above it in the second', async function (assert) {
    await render(<template><FieldInput /></template>)
    const [username, password] = FieldHarness.findAll()
    const below = (field: FieldHarness) =>
      field.part('description').getBoundingClientRect().top >
      field.find(InputHarness).element.getBoundingClientRect().top
    assert.true(below(username!))
    assert.false(below(password!))
    await a11yAudit()
  })
})
