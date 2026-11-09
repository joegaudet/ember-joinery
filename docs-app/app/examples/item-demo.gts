import { BadgeCheck, ChevronRight } from 'lucide'
import { Button, Icon, Item } from '@ember-joinery/ember'

<template>
  <div class="flex w-full max-w-md flex-col gap-6">
    <Item @variant="outline" as |i|>
      <i.Content>
        <i.Title>Basic Item</i.Title>
        <i.Description>
          A simple item with title and description.
        </i.Description>
      </i.Content>
      <i.Actions>
        <Button @variant="outline" @size="sm">
          Action
        </Button>
      </i.Actions>
    </Item>
    <Item @variant="outline" @size="sm" @as="a" href="#" as |i|>
      <i.Media>
        <Icon @icon={{BadgeCheck}} class="size-5" />
      </i.Media>
      <i.Content>
        <i.Title>Your profile has been verified.</i.Title>
      </i.Content>
      <i.Actions>
        <Icon @icon={{ChevronRight}} class="size-4" />
      </i.Actions>
    </Item>
  </div>
</template>
