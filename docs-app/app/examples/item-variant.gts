import { Inbox } from 'lucide'
import { Icon, Item } from '@ember-joinery/ember'

<template>
  <div class="flex w-full max-w-md flex-col gap-6">
    <Item as |i|>
      <i.Media @variant="icon">
        <Icon @icon={{Inbox}} />
      </i.Media>
      <i.Content>
        <i.Title>Default Variant</i.Title>
        <i.Description>
          Transparent background with no border.
        </i.Description>
      </i.Content>
    </Item>
    <Item @variant="outline" as |i|>
      <i.Media @variant="icon">
        <Icon @icon={{Inbox}} />
      </i.Media>
      <i.Content>
        <i.Title>Outline Variant</i.Title>
        <i.Description>
          Outlined style with a visible border.
        </i.Description>
      </i.Content>
    </Item>
    <Item @variant="muted" as |i|>
      <i.Media @variant="icon">
        <Icon @icon={{Inbox}} />
      </i.Media>
      <i.Content>
        <i.Title>Muted Variant</i.Title>
        <i.Description>
          Muted background for secondary content.
        </i.Description>
      </i.Content>
    </Item>
  </div>
</template>
