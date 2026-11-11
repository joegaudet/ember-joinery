import { ArrowUpRight, FolderCode } from 'lucide'
import { Button, Empty, Icon } from '@ember-joinery/ember'

<template>
  {{! Upstream's draws Tabler's folder-code; Joinery's icons are lucide's. }}
  <Empty as |e|>
    <e.Header>
      <e.Media @variant="icon">
        <Icon @icon={{FolderCode}} />
      </e.Media>
      <e.Title>No Projects Yet</e.Title>
      <e.Description>
        You haven't created any projects yet. Get started by creating your first project.
      </e.Description>
    </e.Header>
    <e.Content class="flex-row justify-center gap-2">
      <Button>Create Project</Button>
      <Button @variant="outline">Import Project</Button>
    </e.Content>
    {{! Upstream's <Button asChild><a href="#">: @as renders the link itself. }}
    <Button @as="a" href="#" @variant="link" @size="sm" class="text-muted-foreground">
      Learn More
      <Icon @icon={{ArrowUpRight}} />
    </Button>
  </Empty>
</template>
