import { CreditCard, LogOut, Settings, User } from 'lucide'
import { Button, DropdownMenu, Icon } from '@ember-joinery/ember'

<template>
  <DropdownMenu as |m|>
    <Button @variant="outline" {{m.trigger}}>Open</Button>
    <m.Content>
      <m.Item>
        <Icon @icon={{User}} />
        Profile
      </m.Item>
      <m.Item>
        <Icon @icon={{CreditCard}} />
        Billing
      </m.Item>
      <m.Item>
        <Icon @icon={{Settings}} />
        Settings
      </m.Item>
      <m.Separator />
      <m.Item @variant="destructive">
        <Icon @icon={{LogOut}} />
        Log out
      </m.Item>
    </m.Content>
  </DropdownMenu>
</template>
