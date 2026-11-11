import { ChevronRight, FolderSearch } from 'lucide'
import { Icon, Sheet, Trace, TraceLine } from '@ember-joinery/ember'

<template>
  <Trace class="max-w-sm">
    <Sheet as |s|>
      <s.Trigger>
        <TraceLine as |l|>
          <l.Icon>
            <Icon @icon={{FolderSearch}} />
          </l.Icon>
          <l.Title>Explored 4 files</l.Title>
          <l.Icon>
            <Icon @icon={{ChevronRight}} />
          </l.Icon>
        </TraceLine>
      </s.Trigger>
      <s.Content>
        <s.Header>
          <s.Title>Explored 4 files</s.Title>
          <s.Description>
            Files read while preparing the response.
          </s.Description>
        </s.Header>
        <ul class="flex flex-col gap-2 px-6 font-mono text-xs">
          <li>apps/v4/lib/docs.ts</li>
          <li>apps/v4/lib/components.ts</li>
          <li>apps/v4/next.config.mjs</li>
          <li>apps/v4/package.json</li>
        </ul>
      </s.Content>
    </Sheet>
  </Trace>
</template>
