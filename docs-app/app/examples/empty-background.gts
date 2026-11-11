import { Bell, RefreshCcw } from 'lucide'
import { Button, Empty, Icon } from '@ember-joinery/ember'

<template>
  {{! Upstream's draws Tabler's bell; Joinery's icons are lucide's. }}
  <Empty class="h-full bg-muted/30" as |e|>
    <e.Header>
      <e.Media @variant="icon">
        <Icon @icon={{Bell}} />
      </e.Media>
      <e.Title>No Notifications</e.Title>
      <e.Description class="max-w-xs text-pretty">
        You're all caught up. New notifications will appear here.
      </e.Description>
    </e.Header>
    <e.Content>
      <Button @variant="outline">
        <Icon @icon={{RefreshCcw}} />
        Refresh
      </Button>
    </e.Content>
  </Empty>
</template>
