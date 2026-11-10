import { Avatar, Button, DropdownMenu } from '@ember-joinery/ember'

<template>
  {{! Upstream's DropdownMenuTrigger asChild makes the Button the trigger, as m.trigger does. }}
  <DropdownMenu as |m|>
    <Button @variant="ghost" @size="icon" class="rounded-full" {{m.trigger}}>
      <Avatar as |a|>
        <a.Image @src="https://github.com/shadcn.png" alt="shadcn" />
        <a.Fallback>CN</a.Fallback>
      </Avatar>
    </Button>
    <m.Content class="w-32">
      <m.Group>
        <m.Item>Profile</m.Item>
        <m.Item>Billing</m.Item>
        <m.Item>Settings</m.Item>
      </m.Group>
      <m.Separator />
      <m.Group>
        <m.Item @variant="destructive">Log out</m.Item>
      </m.Group>
    </m.Content>
  </DropdownMenu>
</template>
