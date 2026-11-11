import { Tabs } from '@ember-joinery/ember'

<template>
  <Tabs @defaultValue="account" @orientation="vertical" as |t|>
    <t.List>
      <t.Trigger @value="account">Account</t.Trigger>
      <t.Trigger @value="password">Password</t.Trigger>
      <t.Trigger @value="notifications">Notifications</t.Trigger>
    </t.List>
  </Tabs>
</template>
