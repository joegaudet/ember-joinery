import { Info } from 'lucide'
import { Bubble, Button, Icon, Popover } from '@ember-joinery/ember'

<template>
  <div class="flex w-full max-w-sm flex-col gap-4 py-12">
    <Bubble @align="end" as |b|>
      <b.Content>Run the build script.</b.Content>
    </Bubble>
    <Bubble @variant="destructive" as |b|>
      <b.Content>Failed to run the command.</b.Content>
      <b.Reactions>
        <Popover as |p|>
          <Button
            @variant="ghost"
            @size="icon-xs"
            aria-label="Show error details"
            class="aria-expanded:text-destructive"
            {{p.trigger}}
          >
            <Icon @icon={{Info}} />
          </Button>
          <p.Content>
            <p.Header>
              <p.Title class="text-sm">
                Command failed with exit code 1
              </p.Title>
              <p.Description class="text-sm">
                ENOENT: no such file or directory, open pnpm-lock.yaml
              </p.Description>
            </p.Header>
          </p.Content>
        </Popover>
      </b.Reactions>
    </Bubble>
  </div>
</template>
