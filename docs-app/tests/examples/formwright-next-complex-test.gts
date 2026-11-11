import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render, waitUntil } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { FormHarness, field } from '@ember-formwright/test-support'
import { Toaster } from '@ember-joinery/ember'
import {
  ButtonHarness,
  CardHarness,
  SpinnerHarness,
  ToasterHarness,
  setupToaster,
} from '@ember-joinery/test-support'
import {
  CheckboxGroupFieldHarness,
  RadioGroupFieldHarness,
  SelectFieldHarness,
  SwitchFieldHarness,
  form,
} from '@ember-joinery/formwright/test-support'
import FormwrightNextComplex from 'docs-app/examples/formwright-next-complex'

class SubscriptionForm extends FormHarness {
  @field(RadioGroupFieldHarness) declare plan: RadioGroupFieldHarness
  @field(SelectFieldHarness) declare billingPeriod: SelectFieldHarness
  @field(CheckboxGroupFieldHarness) declare addons: CheckboxGroupFieldHarness
  @field(SwitchFieldHarness) declare emailNotifications: SwitchFieldHarness
}

/** The card, with its form and its one button, Save Preferences. */
class SubscriptionCard extends CardHarness {
  @form(SubscriptionForm, 'subscription-form') declare subscription: SubscriptionForm

  get saveButton(): ButtonHarness {
    return this.find(ButtonHarness)
  }
}

/**
 * A chosen card's description is upstream's `--muted-foreground` on the card's `--primary` 5%
 * tint, about 4.3:1, under the 4.5:1 WCAG AA asks of its text (the Forms page's Accessibility
 * notes say how an app can darken it). While it saves, every field is disabled and fades
 * (upstream's `opacity-50`): text in inactive controls, which WCAG's contrast minimum exempts.
 * So the audit runs every rule but colour contrast, then colour contrast over all of it but
 * those.
 */
const ALL_BUT_CONTRAST = { rules: { 'color-contrast': { enabled: false } } }
const BUT_THE_CHOSEN_CARD = {
  include: [['#ember-testing-container']],
  exclude: [
    [
      '[data-slot="field-label"]:has([role="radio"][aria-checked="true"]) [data-slot="field-description"]',
    ],
  ],
}
const BUT_THE_DISABLED_FIELDS = {
  include: [['#ember-testing-container']],
  exclude: [['[data-test-fw-field]']],
}

module('Example | formwright-next-complex', function (hooks) {
  setupRenderingTest(hooks)
  setupToaster(hooks)

  test('it starts Basic and monthly, under a plain legend, with one button at the end', async function (assert) {
    await render(<template><FormwrightNextComplex /></template>)
    const card = new SubscriptionCard()
    const { subscription, saveButton } = card

    assert.dom('[data-slot="card-header"]', card.element).doesNotExist('no header, as upstream')
    assert.strictEqual(subscription.plan.value, 'basic')
    assert.strictEqual(subscription.billingPeriod.value, 'monthly', 'billed monthly to start')
    assert.strictEqual(subscription.billingPeriod.text, 'Monthly')
    assert.deepEqual(subscription.addons.value, [])
    assert.false(subscription.emailNotifications.value)
    assert
      .dom('[data-slot="field-legend"]', subscription.plan.element)
      .hasAttribute('data-variant', 'legend', "the plan's legend is a section's, not a label's")
    assert.strictEqual(saveButton.text, 'Save Preferences')
    assert.dom(saveButton.element.parentElement).hasClass('justify-end')
    assert.dom('[data-test-fw-reset]', card.element).doesNotExist('no Reset, as upstream has none')

    await a11yAudit(ALL_BUT_CONTRAST)
    await a11yAudit(BUT_THE_CHOSEN_CARD, { runOnly: ['color-contrast'] })
  })

  test('while it saves, every field waits and the button spins; then a toast says it is saved', async function (assert) {
    await render(
      <template>
        <FormwrightNextComplex />
        <Toaster />
      </template>,
    )
    const card = new SubscriptionCard()
    const { subscription, saveButton } = card

    await subscription.submit()
    assert.false(subscription.isSubmitting, 'an invalid form never starts saving')
    assert.deepEqual(subscription.addons.errors, ['Please select at least one add-on'])
    assert.deepEqual(subscription.billingPeriod.errors, [], 'the billing period is set')

    await subscription.plan.select('pro')
    await subscription.billingPeriod.select('yearly')
    await subscription.addons.select(['analytics', 'backup'])
    await subscription.emailNotifications.check()
    const submitted = subscription.submit()
    await waitUntil(() => subscription.isSubmitting)
    assert.true(saveButton.isDisabled, 'the button waits')
    assert.dom(saveButton.element).hasAttribute('aria-busy', 'true')
    assert.strictEqual(new SpinnerHarness({ within: saveButton }).label, 'Loading')
    assert.true(subscription.plan.radioGroup.isDisabled, 'and so does every field')
    assert.true(subscription.billingPeriod.selectHarness.isDisabled)
    assert.true(subscription.addons.isDisabled)
    assert.true(subscription.emailNotifications.switch.isDisabled)
    await a11yAudit(ALL_BUT_CONTRAST)
    await a11yAudit(BUT_THE_DISABLED_FIELDS, { runOnly: ['color-contrast'] })

    await submitted
    assert.false(subscription.isSubmitting)
    assert.false(saveButton.isDisabled)
    assert.dom(saveButton.element).doesNotHaveAttribute('aria-busy')
    assert.strictEqual(saveButton.text, 'Save Preferences', 'the Spinner goes')
    assert.false(subscription.plan.radioGroup.isDisabled)
    const toast = new ToasterHarness().toast()
    assert.strictEqual(toast.type, 'success')
    assert.strictEqual(toast.title, 'Preferences saved')
    assert.strictEqual(toast.description, 'Your subscription plan has been updated.')
    assert.strictEqual(subscription.plan.value, 'pro', 'the form keeps what was saved')
    assert.strictEqual(subscription.billingPeriod.value, 'yearly')
    assert.deepEqual(subscription.addons.value, ['analytics', 'backup'])
    assert.true(subscription.emailNotifications.value)

    await a11yAudit(ALL_BUT_CONTRAST)
    await a11yAudit(BUT_THE_CHOSEN_CARD, { runOnly: ['color-contrast'] })
  })
})
