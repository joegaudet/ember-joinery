import { ArrowUpRight, ChevronRight, FileText, Globe } from 'lucide'
import { Icon, Trace, TraceLine } from '@ember-joinery/ember'

<template>
  <Trace class="max-w-sm">
    <a href="#link">
      <TraceLine as |l|>
        <l.Icon>
          <Icon @icon={{FileText}} />
        </l.Icon>
        <l.Title>Read apps/v4/lib/docs.ts</l.Title>
        <l.Icon>
          <Icon @icon={{ChevronRight}} />
        </l.Icon>
      </TraceLine>
    </a>
    <a href="https://docs.astro.build/en/install-and-setup/" target="_blank" rel="noreferrer">
      <TraceLine as |l|>
        <l.Icon>
          <Icon @icon={{Globe}} />
        </l.Icon>
        <l.Title>
          Install Astro | docs.astro.build
          <span class="sr-only"> (opens in a new tab)</span>
        </l.Title>
        <l.Icon>
          <Icon @icon={{ArrowUpRight}} />
        </l.Icon>
      </TraceLine>
    </a>
  </Trace>
</template>
