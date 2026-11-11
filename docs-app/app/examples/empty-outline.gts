import { Cloud } from 'lucide'
import { Button, Empty, Icon } from '@ember-joinery/ember'

<template>
  {{! Upstream's draws Tabler's cloud; Joinery's icons are lucide's. }}
  <Empty class="border border-dashed" as |e|>
    <e.Header>
      <e.Media @variant="icon">
        <Icon @icon={{Cloud}} />
      </e.Media>
      <e.Title>Cloud Storage Empty</e.Title>
      <e.Description>
        Upload files to your cloud storage to access them anywhere.
      </e.Description>
    </e.Header>
    <e.Content>
      <Button @variant="outline" @size="sm">
        Upload Files
      </Button>
    </e.Content>
  </Empty>
</template>
