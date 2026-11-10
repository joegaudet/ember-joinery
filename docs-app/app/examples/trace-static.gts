import { GitBranch } from 'lucide'
import { Icon, Trace, TraceLine } from '@ember-joinery/ember'

<template>
  <Trace class="max-w-sm">
    <TraceLine as |l|>
      <l.Icon>
        <Icon @icon={{GitBranch}} />
      </l.Icon>
      <l.Title>Created branch fix/frozen-lockfile</l.Title>
    </TraceLine>
  </Trace>
</template>
