import { Button, DropdownMenu } from '@ember-joinery/ember'

<template>
  <DropdownMenu as |m|>
    <Button @variant="outline" {{m.trigger}}>Open</Button>
    <m.Content>
      <m.Group>
        <m.Item>Team</m.Item>
        <m.Sub as |s|>
          <s.Trigger>Invite users</s.Trigger>
          <m.Portal>
            <s.Content>
              <m.Item>Email</m.Item>
              <m.Item>Message</m.Item>
              <m.Sub as |more|>
                <more.Trigger>More options</more.Trigger>
                <m.Portal>
                  <more.Content>
                    <m.Item>Calendly</m.Item>
                    <m.Item>Slack</m.Item>
                    <m.Separator />
                    <m.Item>Webhook</m.Item>
                  </more.Content>
                </m.Portal>
              </m.Sub>
              <m.Separator />
              <m.Item>Advanced...</m.Item>
            </s.Content>
          </m.Portal>
        </m.Sub>
        <m.Item>
          New Team
          <m.Shortcut>⌘+T</m.Shortcut>
        </m.Item>
      </m.Group>
    </m.Content>
  </DropdownMenu>
</template>
