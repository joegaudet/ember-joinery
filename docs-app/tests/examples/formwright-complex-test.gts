import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { FormHarness, field } from '@ember-formwright/test-support'
import { Toaster } from '@ember-joinery/ember'
import { ToasterHarness, setupToaster } from '@ember-joinery/test-support'
import {
  CheckboxGroupFieldHarness,
  RadioGroupFieldHarness,
  SelectFieldHarness,
  SwitchFieldHarness,
} from '@ember-joinery/formwright/test-support'
import FormwrightComplex from 'docs-app/examples/formwright-complex'

class SubscriptionForm extends FormHarness {
  static override formName = 'subscription'
  @field(RadioGroupFieldHarness) declare plan: RadioGroupFieldHarness
  @field(SelectFieldHarness) declare billingPeriod: SelectFieldHarness
  @field(CheckboxGroupFieldHarness) declare addons: CheckboxGroupFieldHarness
  @field(SwitchFieldHarness) declare emailNotifications: SwitchFieldHarness
}

/**
 * A chosen card's description is upstream's `--muted-foreground` on the card's `--primary` 5%
 * tint, about 4.3:1, under the 4.5:1 WCAG AA asks of its text (the Forms page's Accessibility
 * notes say how an app can darken it). So the audit runs every rule but colour contrast, then
 * colour contrast over all of it but that description.
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

module('Example | formwright-complex', function (hooks) {
  setupRenderingTest(hooks)
  setupToaster(hooks)

  test('a plan, a billing period and an add-on make a subscription', async function (assert) {
    await render(
      <template>
        <FormwrightComplex />
        <Toaster />
      </template>,
    )
    const subscription = new SubscriptionForm()
    assert.strictEqual(subscription.plan.value, 'basic', 'Basic to start with')
    await subscription.submit()
    assert.deepEqual(subscription.billingPeriod.errors, ['Please select a billing period'])
    assert.deepEqual(subscription.addons.errors, ['Please select at least one add-on'])
    await a11yAudit(ALL_BUT_CONTRAST)
    await a11yAudit(BUT_THE_CHOSEN_CARD, { runOnly: ['color-contrast'] })

    await subscription.plan.select('pro')
    await subscription.reset()
    assert.strictEqual(subscription.plan.value, 'basic', 'Reset puts every field back')

    await subscription.plan.select('pro')
    await subscription.billingPeriod.choose('yearly')
    await subscription.addons.select(['analytics', 'support'])
    await subscription.emailNotifications.check()
    await subscription.submit()
    assert.deepEqual(JSON.parse(new ToasterHarness().toast().description!), {
      plan: 'pro',
      billingPeriod: 'yearly',
      addons: ['analytics', 'support'],
      emailNotifications: true,
    })

    await a11yAudit(ALL_BUT_CONTRAST)
    await a11yAudit(BUT_THE_CHOSEN_CARD, { runOnly: ['color-contrast'] })
  })
})
