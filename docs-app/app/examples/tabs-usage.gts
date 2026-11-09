import { Tabs } from '@ember-joinery/ember'

<template>
  {{!
    Joinery's own: upstream's Usage snippet, live, so the page shows panels until Card lands
    for tabs-demo. It has no upstream example, so the parity map leaves it out.
  }}
  <Tabs @defaultValue="account" class="w-[400px]" as |t|>
    <t.List>
      <t.Trigger @value="account">Account</t.Trigger>
      <t.Trigger @value="password">Password</t.Trigger>
    </t.List>
    <t.Content @value="account">Make changes to your account here.</t.Content>
    <t.Content @value="password">Change your password here.</t.Content>
  </Tabs>
</template>
