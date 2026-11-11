import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ButtonHarness, CardHarness, InputHarness, child } from '@ember-joinery/test-support'
import CardDemo from 'docs-app/examples/card-demo'

/** The login card: a page object, with its fields and buttons declared. */
class LoginCard extends CardHarness {
  @child(ButtonHarness, { index: 0 }) declare signUp: ButtonHarness
  @child(InputHarness, { index: 0 }) declare email: InputHarness
  @child(InputHarness, { index: 1 }) declare password: InputHarness
  @child(ButtonHarness, { index: 1 }) declare login: ButtonHarness
  @child(ButtonHarness, { index: 2 }) declare google: ButtonHarness

  /** The "Forgot your password?" link. */
  get forgot(): HTMLAnchorElement {
    return this.content.querySelector('a')!
  }
}

module('Example | card-demo', function (hooks) {
  setupRenderingTest(hooks)

  test('a login form in a card, with sign up in the header and two buttons in the footer', async function (assert) {
    await render(<template><CardDemo /></template>)
    const card = new LoginCard()
    assert.strictEqual(card.title, 'Login to your account')
    assert.strictEqual(card.description, 'Enter your email below to login to your account')
    assert.true(card.action.contains(card.signUp.element), "sign up is the header's action")
    assert.strictEqual(card.signUp.label, 'Sign Up')
    assert.strictEqual(card.signUp.variant, 'link')

    assert.strictEqual(card.email.label, 'Email', 'its label names it')
    assert.strictEqual(card.email.type, 'email')
    assert.strictEqual(card.email.placeholder, 'm@example.com')
    assert.true(card.email.isRequired)
    assert.strictEqual(card.password.label, 'Password')
    assert.strictEqual(card.password.type, 'password')
    assert.true(card.password.isRequired)

    await card.email.fillIn('ada@example.com')
    await card.password.fillIn('secret')
    assert.strictEqual(card.email.value, 'ada@example.com')
    assert.strictEqual(card.password.value, 'secret')

    const field = card.password.element.getBoundingClientRect()
    const forgot = card.forgot.getBoundingClientRect()
    assert.strictEqual(card.forgot.textContent?.trim(), 'Forgot your password?')
    assert.ok(Math.abs(forgot.right - field.right) < 1, 'ml-auto: the link sits at the end')

    assert.strictEqual(card.login.label, 'Login')
    assert.strictEqual(card.google.label, 'Login with Google')
    assert.strictEqual(card.google.variant, 'outline')
    const login = card.login.element
    const google = card.google.element
    assert.ok(
      google.getBoundingClientRect().top >= login.getBoundingClientRect().bottom,
      'flex-col: one under the other',
    )
    assert.strictEqual(login.offsetWidth, card.footer.clientWidth - 32, 'w-full')
    assert.strictEqual(google.offsetWidth, login.offsetWidth)
    await a11yAudit()
  })
})
