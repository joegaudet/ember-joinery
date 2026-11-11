import { Button, DropdownMenu } from '@ember-joinery/ember'

<template>
  <DropdownMenu as |m|>
    <Button @variant="outline" {{m.trigger}}>Open</Button>
    <m.Content class="w-40" @align="start">
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
      <m.Group>
        <m.Item>Team</m.Item>
        <m.Sub as |s|>
          <s.Trigger>Invite users</s.Trigger>
          <m.Portal>
            <s.Content>
              <m.Item>Email</m.Item>
              <m.Item>Message</m.Item>
              <m.Separator />
              <m.Item>More...</m.Item>
            </s.Content>
          </m.Portal>
        </m.Sub>
        <m.Item>
          New Team
          <m.Shortcut>⌘+T</m.Shortcut>
        </m.Item>
      </m.Group>
      <m.Separator />
      <m.Group>
        <m.Item>GitHub</m.Item>
        <m.Item>Support</m.Item>
        <m.Item @disabled={{true}}>API</m.Item>
      </m.Group>
      <m.Separator />
      <m.Group>
        <m.Item>
          Log out
          <m.Shortcut>⇧⌘Q</m.Shortcut>
        </m.Item>
      </m.Group>
    </m.Content>
  </DropdownMenu>
</template>
