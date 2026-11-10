import { FileText, Search, Terminal } from 'lucide'
import { Icon, Trace, TraceLine } from '@ember-joinery/ember'

<template>
  <Trace class="max-w-sm">
    <TraceLine as |l|>
      <l.Icon>
        <Icon @icon={{Search}} />
      </l.Icon>
      <l.Title>Searched for minimumReleaseAge</l.Title>
    </TraceLine>
    <TraceLine as |l|>
      <l.Icon>
        <Icon @icon={{FileText}} />
      </l.Icon>
      <l.Title>Read pnpm-workspace.yaml</l.Title>
    </TraceLine>
    <TraceLine as |l|>
      <l.Icon>
        <Icon @icon={{Terminal}} />
      </l.Icon>
      <l.Title>Ran pnpm install</l.Title>
    </TraceLine>
  </Trace>
</template>
