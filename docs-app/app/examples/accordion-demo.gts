import { Accordion } from '@ember-joinery/ember'

<template>
  <Accordion
    @type="single"
    @collapsible={{true}}
    @defaultValue="shipping"
    class="max-w-lg"
    as |accordion|
  >
    <accordion.Item @value="shipping" as |item|>
      <item.Trigger>What are your shipping options?</item.Trigger>
      <item.Content>
        We offer standard (5-7 days), express (2-3 days), and overnight shipping. Free shipping on
        international orders.
      </item.Content>
    </accordion.Item>
    <accordion.Item @value="returns" as |item|>
      <item.Trigger>What is your return policy?</item.Trigger>
      <item.Content>
        Returns accepted within 30 days. Items must be unused and in original packaging. Refunds
        processed within 5-7 business days.
      </item.Content>
    </accordion.Item>
    <accordion.Item @value="support" as |item|>
      <item.Trigger>How can I contact customer support?</item.Trigger>
      <item.Content>
        Reach us via email, live chat, or phone. We respond within 24 hours during business days.
      </item.Content>
    </accordion.Item>
  </Accordion>
</template>
