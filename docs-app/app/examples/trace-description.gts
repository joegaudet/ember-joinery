import { FilePen, Search, Terminal } from 'lucide'
import { Icon, Trace, TraceLine } from '@ember-joinery/ember'

<template>
  <Trace class="max-w-sm">
    <TraceLine as |l|>
      <l.Icon>
        <Icon @icon={{FilePen}} />
      </l.Icon>
      <l.Title>
        Edited components/settings/notification-preferences-form.tsx
      </l.Title>
      <l.Description class="font-mono">+48 −12</l.Description>
    </TraceLine>
    <TraceLine as |l|>
      <l.Icon>
        <Icon @icon={{Terminal}} />
      </l.Icon>
      <l.Title>Ran pnpm test</l.Title>
      <l.Description>14s</l.Description>
    </TraceLine>
    <TraceLine as |l|>
      <l.Icon>
        <Icon @icon={{Search}} />
      </l.Icon>
      <l.Title>Searched for useChat</l.Title>
      <l.Description>8 results</l.Description>
    </TraceLine>
  </Trace>
</template>
