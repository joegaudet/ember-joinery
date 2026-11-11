import { Check } from 'lucide'
import { Bubble, Button, Icon, Tooltip } from '@ember-joinery/ember'

<template>
  <div class="flex w-full max-w-sm flex-col gap-4 py-12">
    <Bubble @variant="secondary" as |b|>
      <b.Content>Did you remove the stale route?</b.Content>
    </Bubble>
    <Bubble @align="end" as |b|>
      <b.Content>Yes, removed it from the registry.</b.Content>
      <b.Reactions class="p-0">
        <Tooltip as |t|>
          {{! Upstream leaves this icon-only button unnamed; it is named, so the audit passes. }}
          <Button @variant="ghost" @size="icon-xs" aria-label="Read" {{t.trigger}}>
            <Icon @icon={{Check}} />
          </Button>
          <t.Content>Read on Jan 5, 2026 at 4:32 PM</t.Content>
        </Tooltip>
      </b.Reactions>
    </Bubble>
  </div>
</template>
