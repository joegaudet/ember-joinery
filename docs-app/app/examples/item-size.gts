import { Inbox } from 'lucide'
import { Icon, Item } from '@ember-joinery/ember'

<template>
  <div class="flex w-full max-w-md flex-col gap-6">
    <Item @variant="outline" as |i|>
      <i.Media @variant="icon">
        <Icon @icon={{Inbox}} />
      </i.Media>
      <i.Content>
        <i.Title>Default Size</i.Title>
        <i.Description>
          The standard size for most use cases.
        </i.Description>
      </i.Content>
    </Item>
    <Item @variant="outline" @size="sm" as |i|>
      <i.Media @variant="icon">
        <Icon @icon={{Inbox}} />
      </i.Media>
      <i.Content>
        <i.Title>Small Size</i.Title>
        <i.Description>A compact size for dense layouts.</i.Description>
      </i.Content>
    </Item>
    <Item @variant="outline" @size="xs" as |i|>
      <i.Media @variant="icon">
        <Icon @icon={{Inbox}} />
      </i.Media>
      <i.Content>
        <i.Title>Extra Small Size</i.Title>
        <i.Description>The most compact size available.</i.Description>
      </i.Content>
    </Item>
  </div>
</template>
