import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { AccordionHarness, CardHarness } from '@ember-joinery/test-support'
import AccordionCard from 'docs-app/examples/accordion-card'

module('Example | accordion-card', function (hooks) {
  setupRenderingTest(hooks)

  test('billing questions in a card, the first open, and every one can close', async function (assert) {
    await render(<template><AccordionCard /></template>)
    const card = new CardHarness()
    assert.strictEqual(card.title, 'Subscription & Billing')
    assert.strictEqual(
      card.description,
      'Common questions about your account, plans, payments and cancellations.',
    )

    const faq = card.find(AccordionHarness)
    assert.true(card.content.contains(faq.element), 'the accordion is the card’s content')
    assert.deepEqual(faq.titles, [
      'What subscription plans do you offer?',
      'How does billing work?',
      'How do I cancel my subscription?',
    ])
    assert.deepEqual(faq.openValues, ['plans'])
    assert.strictEqual(
      faq.text('plans'),
      'We offer three subscription tiers: Starter ($9/month), Professional ($29/month), and Enterprise ($99/month). Each plan includes increasing storage limits, API access, priority support, and team collaboration features.',
    )

    await faq.toggle('billing')
    assert.deepEqual(faq.openValues, ['billing'], 'one at a time')
    assert.strictEqual(
      faq.text('billing'),
      "Billing occurs automatically at the start of each billing cycle. We accept all major credit cards, PayPal, and ACH transfers for enterprise customers. You'll receive an invoice via email after each payment.",
    )
    await faq.toggle('billing')
    assert.deepEqual(faq.openValues, [], 'collapsible: none open')

    await faq.focus('cancel')
    await faq.press('Home')
    assert.strictEqual(faq.focused, 'plans', 'Home moves to the first question')
    await a11yAudit()
  })
})
