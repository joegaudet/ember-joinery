import { Plus } from 'lucide'
import { Avatar, Button, Empty, Icon } from '@ember-joinery/ember'

<template>
  <Empty as |e|>
    <e.Header>
      <e.Media>
        <div
          class="flex -space-x-2 *:data-[slot=avatar]:size-12 *:data-[slot=avatar]:ring-2 *:data-[slot=avatar]:ring-background *:data-[slot=avatar]:grayscale"
        >
          <Avatar as |a|>
            <a.Image @src="https://github.com/shadcn.png" alt="@shadcn" />
            <a.Fallback>CN</a.Fallback>
          </Avatar>
          <Avatar as |a|>
            <a.Image @src="https://github.com/maxleiter.png" alt="@maxleiter" />
            <a.Fallback>LR</a.Fallback>
          </Avatar>
          <Avatar as |a|>
            <a.Image @src="https://github.com/evilrabbit.png" alt="@evilrabbit" />
            <a.Fallback>ER</a.Fallback>
          </Avatar>
        </div>
      </e.Media>
      <e.Title>No Team Members</e.Title>
      <e.Description>
        Invite your team to collaborate on this project.
      </e.Description>
    </e.Header>
    <e.Content>
      <Button @size="sm">
        <Icon @icon={{Plus}} />
        Invite Members
      </Button>
    </e.Content>
  </Empty>
</template>
