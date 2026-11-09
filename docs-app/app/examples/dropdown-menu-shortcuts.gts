import { Button, DropdownMenu } from '@ember-joinery/ember'

<template>
  <DropdownMenu as |m|>
    <Button @variant="outline" {{m.trigger}}>Open</Button>
    <m.Content>
      <m.Group>
        <m.Label>My Account</m.Label>
        <m.Item>
          Profile
          <m.Shortcut>⇧⌘P</m.Shortcut>
        </m.Item>
        <m.Item>
          Billing
          <m.Shortcut>⌘B</m.Shortcut>
        </m.Item>
        <m.Item>
          Settings
          <m.Shortcut>⌘S</m.Shortcut>
        </m.Item>
      </m.Group>
      <m.Separator />
      <m.Item>
        Log out
        <m.Shortcut>⇧⌘Q</m.Shortcut>
      </m.Item>
    </m.Content>
  </DropdownMenu>
</template>
