import { Avatar, Button, Empty } from '@ember-joinery/ember'

<template>
  <Empty as |e|>
    <e.Header>
      <e.Media @variant="default">
        <Avatar class="size-12" as |a|>
          {{! Upstream's image has no alt; an image needs one, so this one is named. }}
          <a.Image @src="https://github.com/shadcn.png" alt="@shadcn" class="grayscale" />
          <a.Fallback>LR</a.Fallback>
        </Avatar>
      </e.Media>
      <e.Title>User Offline</e.Title>
      <e.Description>
        This user is currently offline. You can leave a message to notify them or try again later.
      </e.Description>
    </e.Header>
    <e.Content>
      <Button @size="sm">Leave Message</Button>
    </e.Content>
  </Empty>
</template>
