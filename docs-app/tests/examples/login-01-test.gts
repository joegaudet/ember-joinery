import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import {
  ButtonHarness,
  CardHarness,
  FieldHarness,
  InputHarness,
  child,
} from '@ember-joinery/test-support'
import Login01 from 'docs-app/examples/login-01'

/** The login card, as a page object: its fields, its buttons and its links. */
class LoginCard extends CardHarness {
  @child(FieldHarness, { index: 0 }) declare emailField: FieldHarness
  @child(FieldHarness, { index: 1 }) declare passwordField: FieldHarness
  @child(FieldHarness, { index: 2 }) declare actions: FieldHarness
  @child(InputHarness, { index: 0 }) declare email: InputHarness
  @child(InputHarness, { index: 1 }) declare password: InputHarness
  @child(ButtonHarness, { index: 0 }) declare login: ButtonHarness
  @child(ButtonHarness, { index: 1 }) declare google: ButtonHarness

  get form(): HTMLFormElement {
    return this.element.querySelector('form')!
  }

  /** A link in the card, by its text. */
  link(text: string): HTMLAnchorElement {
    const found = [...this.element.querySelectorAll('a')].find(a => a.textContent?.trim() === text)
    if (!found) throw new Error(`No link "${text}" in the login card`)
    return found
  }
}

module('Example | login-01', function (hooks) {
  setupRenderingTest(hooks)

  test('a simple login form: email, password, and two ways in', async function (assert) {
    await render(<template><Login01 /></template>)
    const card = new LoginCard()
    assert.strictEqual(card.title, 'Login to your account')
    assert.strictEqual(card.description, 'Enter your email below to login to your account')

    assert.strictEqual(card.emailField.label, 'Email')
    assert.strictEqual(card.email.label, 'Email', 'the label names the input')
    assert.strictEqual(card.email.type, 'email')
    assert.strictEqual(card.email.placeholder, 'm@example.com')
    assert.true(card.email.isRequired)
    assert.strictEqual(card.passwordField.label, 'Password')
    assert.strictEqual(card.password.label, 'Password')
    assert.strictEqual(card.password.type, 'password')
    assert.true(card.password.isRequired)

    const forgot = card.link('Forgot your password?')
    const row = forgot.parentElement!.getBoundingClientRect()
    assert.ok(
      Math.abs(forgot.getBoundingClientRect().right - row.right) < 1,
      'ml-auto: the link sits at the end of the label row',
    )

    assert.strictEqual(card.login.label, 'Login')
    assert.strictEqual(card.login.element.getAttribute('type'), 'submit')
    assert.strictEqual(card.google.label, 'Login with Google')
    assert.strictEqual(card.google.variant, 'outline')
    assert.strictEqual(card.google.element.getAttribute('type'), 'button')
    assert.ok(
      card.google.element.getBoundingClientRect().top >=
        card.login.element.getBoundingClientRect().bottom,
      'the field stacks its buttons',
    )
    assert.strictEqual(card.actions.description, "Don't have an account? Sign up")
    assert.strictEqual(card.link('Sign up').getAttribute('href'), '#')
    await a11yAudit()
  })

  test('the form asks for both fields before it submits', async function (assert) {
    await render(<template><Login01 /></template>)
    const card = new LoginCard()
    assert.false(card.form.checkValidity(), 'empty, it is invalid')

    await card.email.fillIn('not an email')
    await card.password.fillIn('secret')
    assert.false(card.form.checkValidity(), 'the email has to be one')

    await card.email.fillIn('m@example.com')
    assert.true(card.form.checkValidity())
    assert.strictEqual(card.email.value, 'm@example.com')
    await a11yAudit()
  })

  test('the card is centred on the page, no wider than max-w-sm', async function (assert) {
    await render(<template><Login01 /></template>)
    const card = new LoginCard()
    const page = card.element.closest('.min-h-svh')!.getBoundingClientRect()
    const box = card.element.getBoundingClientRect()
    assert.ok(card.element.offsetWidth <= 384, 'max-w-sm')
    assert.ok(
      Math.abs(box.left - page.left - (page.right - box.right)) < 1,
      'centred across the page',
    )
    assert.ok(
      Math.abs(box.top - page.top - (page.bottom - box.bottom)) < 1,
      'and down it, which is at least the viewport tall (min-h-svh)',
    )
    await a11yAudit()
  })
})
