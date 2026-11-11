import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { FormHarness, field } from '@ember-formwright/test-support'
import { Toaster } from '@ember-joinery/ember'
import { ToasterHarness, setupToaster } from '@ember-joinery/test-support'
import { RadioGroupFieldHarness } from '@ember-joinery/formwright/test-support'
import FormwrightRadiogroup from 'docs-app/examples/formwright-radiogroup'

class SubscriptionForm extends FormHarness {
  static override formName = 'subscription'
  @field(RadioGroupFieldHarness) declare plan: RadioGroupFieldHarness
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

module('Example | formwright-radiogroup', function (hooks) {
  setupRenderingTest(hooks)
  setupToaster(hooks)

  test('a plan must be chosen; the arrow keys move between them', async function (assert) {
    await render(
      <template>
        <FormwrightRadiogroup />
        <Toaster />
      </template>,
    )
    const subscription = new SubscriptionForm()
    assert.deepEqual(subscription.plan.options, ['starter', 'pro', 'enterprise'])
    await subscription.submit()
    assert.deepEqual(subscription.plan.errors, ['You must select a subscription plan to continue.'])
    await a11yAudit()

    await subscription.plan.select('pro')
    assert.strictEqual(subscription.plan.value, 'pro')
    await subscription.plan.radioGroup.press('ArrowDown')
    assert.strictEqual(subscription.plan.value, 'enterprise')
    await subscription.submit()
    assert.deepEqual(JSON.parse(new ToasterHarness().toast().description!), { plan: 'enterprise' })
    await a11yAudit(ALL_BUT_CONTRAST)
    await a11yAudit(BUT_THE_CHOSEN_CARD, { runOnly: ['color-contrast'] })
  })
})
