import { Button, DropdownMenu } from '@ember-joinery/ember'

<template>
  <DropdownMenu as |m|>
    <Button @variant="outline" {{m.trigger}}>Open</Button>
    <m.Content>
      <m.Group>
        <m.Label>My Account</m.Label>
        <m.Item>Profile</m.Item>
        <m.Item>Billing</m.Item>
        <m.Item>Settings</m.Item>
      </m.Group>
      <m.Separator />
      <m.Item>GitHub</m.Item>
      <m.Item>Support</m.Item>
      <m.Item @disabled={{true}}>API</m.Item>
    </m.Content>
  </DropdownMenu>
</template>
