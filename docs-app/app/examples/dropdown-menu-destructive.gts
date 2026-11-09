import { Pencil, Share, Trash } from 'lucide'
import { Button, DropdownMenu, Icon } from '@ember-joinery/ember'

<template>
  <DropdownMenu as |m|>
    <Button @variant="outline" {{m.trigger}}>Actions</Button>
    <m.Content>
      <m.Group>
        <m.Item>
          <Icon @icon={{Pencil}} />
          Edit
        </m.Item>
        <m.Item>
          <Icon @icon={{Share}} />
          Share
        </m.Item>
      </m.Group>
      <m.Separator />
      <m.Group>
        <m.Item @variant="destructive">
          <Icon @icon={{Trash}} />
          Delete
        </m.Item>
      </m.Group>
    </m.Content>
  </DropdownMenu>
</template>
