import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import {
  ButtonHarness,
  CardHarness,
  InputHarness,
  ToggleGroupHarness,
  child,
} from '@ember-joinery/test-support'
import CardSpacing from 'docs-app/examples/card-spacing'

/** The login card: a page object, with its fields and buttons declared. */
class LoginCard extends CardHarness {
  @child(InputHarness, { index: 0 }) declare email: InputHarness
  @child(InputHarness, { index: 1 }) declare password: InputHarness
  @child(ButtonHarness, { index: 1 }) declare login: ButtonHarness

  /** The inset of the card's parts, and the gap between them: `--card-spacing`. */
  get spacing(): string {
    return getComputedStyle(this.header).paddingInlineStart
  }
}

module('Example | card-spacing', function (hooks) {
  setupRenderingTest(hooks)

  test('a toggle group sets the card spacing, and one option is always chosen', async function (assert) {
    await render(<template><CardSpacing /></template>)
    const spacing = new ToggleGroupHarness()
    const card = new LoginCard()

    assert.strictEqual(spacing.type, 'single')
    assert.strictEqual(spacing.variant, 'outline')
    assert.strictEqual(spacing.size, 'sm')
    assert.deepEqual(spacing.itemValues, ['4', '5', '6', '8'])
    assert.deepEqual(
      spacing.itemValues.map(value => spacing.label(value)),
      ['16px', '20px', '24px', '32px'],
      'each option is named by its text',
    )
    assert.deepEqual(spacing.value, ['4'])
    assert.strictEqual(card.spacing, '16px')
    assert.strictEqual(getComputedStyle(card.element).paddingTop, '16px')

    await spacing.toggle('8')
    assert.deepEqual(spacing.value, ['8'])
    assert.strictEqual(card.spacing, '32px', 'the class on the card sets --card-spacing')
    assert.strictEqual(getComputedStyle(card.element).rowGap, '32px')

    await spacing.toggle('5')
    assert.strictEqual(card.spacing, '20px')

    await spacing.toggle('5')
    assert.deepEqual(spacing.value, ['5'], 'pressing the chosen one again keeps it')
    assert.strictEqual(card.spacing, '20px')

    assert.strictEqual(card.title, 'Login to your account')
    assert.strictEqual(card.email.label, 'Email')
    assert.strictEqual(card.password.label, 'Password')
    assert.strictEqual(card.login.label, 'Login')
    await a11yAudit()
  })
})
