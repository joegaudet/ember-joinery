import { ShieldAlert } from 'lucide'
import { Button, Icon, Item } from '@ember-joinery/ember'

<template>
  <div class="flex w-full max-w-lg flex-col gap-6">
    <Item @variant="outline" as |i|>
      <i.Media @variant="icon">
        <Icon @icon={{ShieldAlert}} />
      </i.Media>
      <i.Content>
        <i.Title>Security Alert</i.Title>
        <i.Description>
          New login detected from unknown device.
        </i.Description>
      </i.Content>
      <i.Actions>
        <Button @size="sm" @variant="outline">
          Review
        </Button>
      </i.Actions>
    </Item>
  </div>
</template>
