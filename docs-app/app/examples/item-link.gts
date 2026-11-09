import { ChevronRight, ExternalLink } from 'lucide'
import { Icon, Item } from '@ember-joinery/ember'

<template>
  <div class="flex w-full max-w-md flex-col gap-4">
    <Item @as="a" href="#" as |i|>
      <i.Content>
        <i.Title>Visit our documentation</i.Title>
        <i.Description>
          Learn how to get started with our components.
        </i.Description>
      </i.Content>
      <i.Actions>
        <Icon @icon={{ChevronRight}} class="size-4" />
      </i.Actions>
    </Item>
    <Item @variant="outline" @as="a" href="#" target="_blank" rel="noopener noreferrer" as |i|>
      <i.Content>
        <i.Title>External resource</i.Title>
        <i.Description>
          Opens in a new tab with security attributes.
        </i.Description>
      </i.Content>
      <i.Actions>
        <Icon @icon={{ExternalLink}} class="size-4" />
      </i.Actions>
    </Item>
  </div>
</template>
