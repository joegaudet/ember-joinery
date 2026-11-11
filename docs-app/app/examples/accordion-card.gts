import { Accordion, Card } from '@ember-joinery/ember'

const items = [
  {
    value: 'plans',
    trigger: 'What subscription plans do you offer?',
    content:
      'We offer three subscription tiers: Starter ($9/month), Professional ($29/month), and Enterprise ($99/month). Each plan includes increasing storage limits, API access, priority support, and team collaboration features.',
  },
  {
    value: 'billing',
    trigger: 'How does billing work?',
    content:
      "Billing occurs automatically at the start of each billing cycle. We accept all major credit cards, PayPal, and ACH transfers for enterprise customers. You'll receive an invoice via email after each payment.",
  },
  {
    value: 'cancel',
    trigger: 'How do I cancel my subscription?',
    content:
      'You can cancel your subscription anytime from your account settings. There are no cancellation fees or penalties. Your access will continue until the end of your current billing period.',
  },
]

<template>
  <Card class="w-full max-w-sm" as |card|>
    <card.Header>
      <card.Title>Subscription & Billing</card.Title>
      <card.Description>
        Common questions about your account, plans, payments and cancellations.
      </card.Description>
    </card.Header>
    <card.Content>
      <Accordion @type="single" @collapsible={{true}} @defaultValue="plans" as |accordion|>
        {{#each items as |item|}}
          <accordion.Item @value={{item.value}} as |i|>
            <i.Trigger>{{item.trigger}}</i.Trigger>
            <i.Content>{{item.content}}</i.Content>
          </accordion.Item>
        {{/each}}
      </Accordion>
    </card.Content>
  </Card>
</template>
