import { BadgeCheck, Bell, CreditCard, LogOut } from 'lucide'
import { Avatar, Button, DropdownMenu, Icon } from '@ember-joinery/ember'

<template>
  {{! Upstream's DropdownMenuTrigger asChild makes the Button the trigger, as m.trigger does. }}
  <DropdownMenu as |m|>
    <Button @variant="ghost" @size="icon" class="rounded-full" {{m.trigger}}>
      <Avatar as |a|>
        <a.Image @src="https://github.com/shadcn.png" alt="shadcn" />
        <a.Fallback>LR</a.Fallback>
      </Avatar>
    </Button>
    <m.Content @align="end">
      <m.Group>
        <m.Item>
          <Icon @icon={{BadgeCheck}} />
          Account
        </m.Item>
        <m.Item>
          <Icon @icon={{CreditCard}} />
          Billing
        </m.Item>
        <m.Item>
          <Icon @icon={{Bell}} />
          Notifications
        </m.Item>
      </m.Group>
      <m.Separator />
      <m.Item>
        <Icon @icon={{LogOut}} />
        Sign Out
      </m.Item>
    </m.Content>
  </DropdownMenu>
</template>
