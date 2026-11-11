import { Plus } from 'lucide'
import { Avatar, Button, Icon, Item, ItemGroup } from '@ember-joinery/ember'

const people = [
  {
    username: 'shadcn',
    avatar: 'https://github.com/shadcn.png',
    email: 'shadcn@vercel.com',
  },
  {
    username: 'maxleiter',
    avatar: 'https://github.com/maxleiter.png',
    email: 'maxleiter@vercel.com',
  },
  {
    username: 'evilrabbit',
    avatar: 'https://github.com/evilrabbit.png',
    email: 'evilrabbit@vercel.com',
  },
]

const initial = (name: string) => name.charAt(0)

<template>
  {{!
    Three differences from upstream's, so the accessibility audit passes: each item is a
    listitem (the group is a list), each image has alt, and each icon button a name.
  }}
  <ItemGroup class="max-w-sm">
    {{#each people as |person|}}
      <Item @variant="outline" role="listitem" as |i|>
        <i.Media>
          <Avatar as |a|>
            <a.Image @src={{person.avatar}} alt={{person.username}} class="grayscale" />
            <a.Fallback>{{initial person.username}}</a.Fallback>
          </Avatar>
        </i.Media>
        <i.Content class="gap-1">
          <i.Title>{{person.username}}</i.Title>
          <i.Description>{{person.email}}</i.Description>
        </i.Content>
        <i.Actions>
          <Button
            @variant="ghost"
            @size="icon"
            class="rounded-full"
            aria-label="Add {{person.username}}"
          >
            <Icon @icon={{Plus}} />
          </Button>
        </i.Actions>
      </Item>
    {{/each}}
  </ItemGroup>
</template>
