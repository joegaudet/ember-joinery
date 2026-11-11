import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import {
  ButtonHarness,
  CardHarness,
  FieldGroupHarness,
  FieldHarness,
  InputHarness,
  child,
} from '@ember-joinery/test-support'
import Signup01 from 'docs-app/examples/signup-01'

/** The signup card, as a page object. */
class SignupCard extends CardHarness {
  @child(FieldGroupHarness) declare fields: FieldGroupHarness
  @child(InputHarness, { index: 0 }) declare name: InputHarness
  @child(InputHarness, { index: 1 }) declare email: InputHarness
  @child(InputHarness, { index: 2 }) declare password: InputHarness
  @child(InputHarness, { index: 3 }) declare confirm: InputHarness
  @child(ButtonHarness, { index: 0 }) declare create: ButtonHarness
  @child(ButtonHarness, { index: 1 }) declare google: ButtonHarness

  get form(): HTMLFormElement {
    return this.element.querySelector('form')!
  }

  field(index: number): FieldHarness {
    return new FieldHarness({ index, within: this })
  }
}

module('Example | signup-01', function (hooks) {
  setupRenderingTest(hooks)

  test('a simple signup form: four fields, each described, and two ways to sign up', async function (assert) {
    await render(<template><Signup01 /></template>)
    const card = new SignupCard()
    assert.strictEqual(card.title, 'Create an account')
    assert.strictEqual(card.description, 'Enter your information below to create your account')

    const fields = [0, 1, 2, 3].map(index => card.field(index))
    assert.deepEqual(
      fields.map(field => [field.label, field.description]),
      [
        ['Full Name', ''],
        ['Email', "We'll use this to contact you. We will not share your email with anyone else."],
        ['Password', 'Must be at least 8 characters long.'],
        ['Confirm Password', 'Please confirm your password.'],
      ],
    )
    assert.deepEqual(
      [card.name, card.email, card.password, card.confirm].map(input => [
        input.label,
        input.type,
        input.isRequired,
      ]),
      [
        ['Full Name', 'text', true],
        ['Email', 'email', true],
        ['Password', 'password', true],
        ['Confirm Password', 'password', true],
      ],
      'each label names its input, and each input is required',
    )
    assert.strictEqual(card.name.placeholder, 'John Doe')
    assert.strictEqual(card.email.placeholder, 'm@example.com')

    assert.strictEqual(card.fields.fields.length, 5, 'four fields and the actions')
    const actions = card.field(4)
    assert.strictEqual(card.create.label, 'Create Account')
    assert.strictEqual(card.create.element.getAttribute('type'), 'submit')
    assert.strictEqual(card.google.label, 'Sign up with Google')
    assert.strictEqual(card.google.variant, 'outline')
    assert.true(actions.element.contains(card.google.element), 'the buttons share the last field')
    assert.strictEqual(actions.description, 'Already have an account? Sign in')
    assert.notStrictEqual(
      actions.element.closest('[data-slot="field-group"]'),
      card.fields.element,
      "in a field group of their own, inside the form's",
    )
    await a11yAudit()
  })

  test('the form takes every field before it submits', async function (assert) {
    await render(<template><Signup01 /></template>)
    const card = new SignupCard()
    assert.false(card.form.checkValidity())
    await card.name.fillIn('Ada Lovelace')
    await card.email.fillIn('ada@example.com')
    await card.password.fillIn('analytical')
    assert.false(card.form.checkValidity(), 'the confirmation is still empty')
    await card.confirm.fillIn('analytical')
    assert.true(card.form.checkValidity())
    await a11yAudit()
  })
})
