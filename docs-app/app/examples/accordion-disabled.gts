import { Accordion } from '@ember-joinery/ember'

<template>
  <Accordion @type="single" @collapsible={{true}} class="w-full" as |accordion|>
    <accordion.Item @value="item-1" as |item|>
      <item.Trigger>Can I access my account history?</item.Trigger>
      <item.Content>
        Yes, you can view your complete account history including all transactions, plan changes,
        and support tickets in the Account History section of your dashboard.
      </item.Content>
    </accordion.Item>
    <accordion.Item @value="item-2" @disabled={{true}} as |item|>
      <item.Trigger>Premium feature information</item.Trigger>
      <item.Content>
        This section contains information about premium features. Upgrade your plan to access this
        content.
      </item.Content>
    </accordion.Item>
    <accordion.Item @value="item-3" as |item|>
      <item.Trigger>How do I update my email address?</item.Trigger>
      <item.Content>
        You can update your email address in your account settings. You'll receive a verification
        email at your new address to confirm the change.
      </item.Content>
    </accordion.Item>
  </Accordion>
</template>
