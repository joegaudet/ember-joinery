import { ChevronDown } from 'lucide'
import { Avatar, Button, DropdownMenu, Icon, Item } from '@ember-joinery/ember'

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

const initial = (username: string) => username.charAt(0)

<template>
  {{!
    Upstream's DropdownMenuTrigger asChild makes the Button the trigger, as m.trigger does.
    Upstream's images have no alt; an image needs one, and the username beside each names the
    person, so these are decorative (alt="").
  }}
  <DropdownMenu as |m|>
    <Button @variant="outline" {{m.trigger}}>
      Select
      <Icon @icon={{ChevronDown}} />
    </Button>
    <m.Content class="w-48" @align="end">
      <m.Group>
        {{#each people as |person|}}
          <m.Item>
            <Item @size="xs" class="w-full p-2" as |i|>
              <i.Media>
                <Avatar class="size-[--spacing(6.5)]" as |a|>
                  <a.Image @src={{person.avatar}} alt="" class="grayscale" />
                  <a.Fallback>{{initial person.username}}</a.Fallback>
                </Avatar>
              </i.Media>
              <i.Content class="gap-0">
                <i.Title>{{person.username}}</i.Title>
                <i.Description class="leading-none">
                  {{person.email}}
                </i.Description>
              </i.Content>
            </Item>
          </m.Item>
        {{/each}}
      </m.Group>
    </m.Content>
  </DropdownMenu>
</template>
