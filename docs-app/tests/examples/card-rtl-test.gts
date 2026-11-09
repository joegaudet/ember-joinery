import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import { ButtonHarness, CardHarness, InputHarness, child } from '@ember-joinery/test-support'
import CardRtl from 'docs-app/examples/card-rtl'

/** The login card, in Arabic: a page object, with its fields and buttons declared. */
class LoginCard extends CardHarness {
  @child(ButtonHarness, { index: 0 }) declare signUp: ButtonHarness
  @child(InputHarness, { index: 0 }) declare email: InputHarness
  @child(InputHarness, { index: 1 }) declare password: InputHarness
  @child(ButtonHarness, { index: 1 }) declare login: ButtonHarness

  /** The "Forgot your password?" link. */
  get forgot(): HTMLAnchorElement {
    return this.content.querySelector('a')!
  }
}

module('Example | card-rtl', function (hooks) {
  setupRenderingTest(hooks)

  test('in Arabic, the header action and the link on the left', async function (assert) {
    // The guide shows it with dir="rtl" on the preview; a provider does the same here.
    await render(
      <template>
        <DirectionProvider @dir="rtl"><CardRtl /></DirectionProvider>
      </template>,
    )
    const card = new LoginCard()
    assert.strictEqual(card.title, 'تسجيل الدخول إلى حسابك')
    assert.strictEqual(card.signUp.label, 'إنشاء حساب')
    assert.strictEqual(card.email.label, 'البريد الإلكتروني', 'its label names it')
    assert.strictEqual(card.email.placeholder, 'm@example.com')
    assert.strictEqual(card.password.label, 'كلمة المرور')
    assert.strictEqual(card.login.label, 'تسجيل الدخول')

    const title = card.part('title').getBoundingClientRect()
    const action = card.action.getBoundingClientRect()
    assert.ok(action.right <= title.left + 1, "the header's action is on the left of the title")

    const field = card.password.element.getBoundingClientRect()
    const forgot = card.forgot.getBoundingClientRect()
    assert.ok(
      Math.abs(forgot.left - field.left) < 1,
      'ms-auto: the link sits at the end, on the left',
    )
    assert.strictEqual(getComputedStyle(card.email.control).direction, 'rtl')

    await card.email.fillIn('ada@example.com')
    assert.strictEqual(card.email.value, 'ada@example.com')
    await a11yAudit()
  })
})
