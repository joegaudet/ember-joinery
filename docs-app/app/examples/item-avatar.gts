import { Plus } from 'lucide'
import { Avatar, Button, Icon, Item } from '@ember-joinery/ember'

<template>
  <div class="flex w-full max-w-lg flex-col gap-6">
    <Item @variant="outline" as |i|>
      <i.Media>
        <Avatar class="size-10" as |a|>
          {{! Upstream's image has no alt; an image needs one, so this one is named. }}
          <a.Image @src="https://github.com/evilrabbit.png" alt="@evilrabbit" />
          <a.Fallback>ER</a.Fallback>
        </Avatar>
      </i.Media>
      <i.Content>
        <i.Title>Evil Rabbit</i.Title>
        <i.Description>Last seen 5 months ago</i.Description>
      </i.Content>
      <i.Actions>
        <Button @size="icon-sm" @variant="outline" class="rounded-full" aria-label="Invite">
          <Icon @icon={{Plus}} />
        </Button>
      </i.Actions>
    </Item>
    <Item @variant="outline" as |i|>
      <i.Media>
        <div
          class="flex -space-x-2 *:data-[slot=avatar]:ring-2 *:data-[slot=avatar]:ring-background *:data-[slot=avatar]:grayscale"
        >
          <Avatar class="hidden sm:flex" as |a|>
            <a.Image @src="https://github.com/shadcn.png" alt="@shadcn" />
            <a.Fallback>CN</a.Fallback>
          </Avatar>
          <Avatar class="hidden sm:flex" as |a|>
            <a.Image @src="https://github.com/maxleiter.png" alt="@maxleiter" />
            <a.Fallback>LR</a.Fallback>
          </Avatar>
          <Avatar as |a|>
            <a.Image @src="https://github.com/evilrabbit.png" alt="@evilrabbit" />
            <a.Fallback>ER</a.Fallback>
          </Avatar>
        </div>
      </i.Media>
      <i.Content>
        <i.Title>No Team Members</i.Title>
        <i.Description>
          Invite your team to collaborate on this project.
        </i.Description>
      </i.Content>
      <i.Actions>
        <Button @size="sm" @variant="outline">
          Invite
        </Button>
      </i.Actions>
    </Item>
  </div>
</template>
