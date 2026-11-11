import { ArrowUpRight, Globe } from 'lucide'
import { Icon, Trace, TraceCollapsible, TraceLine } from '@ember-joinery/ember'

const sources = [
  {
    title: 'Install Astro | docs.astro.build',
    href: 'https://docs.astro.build/en/install-and-setup/',
  },
  {
    title: 'create-astro | npmjs.com',
    href: 'https://www.npmjs.com/package/create-astro',
  },
  {
    title: 'Settings: minimumReleaseAge | pnpm.io',
    href: 'https://pnpm.io/settings#minimumreleaseage',
  },
]

<template>
  <div class="w-full max-w-sm">
    <TraceCollapsible @defaultOpen={{true}} as |c|>
      <c.Trigger>
        <TraceLine as |l|>
          <l.Icon>
            <Icon @icon={{Globe}} />
          </l.Icon>
          <l.Title>Used {{sources.length}} sources</l.Title>
        </TraceLine>
      </c.Trigger>
      <c.Content>
        <Trace>
          {{#each sources as |source|}}
            <a href={{source.href}} target="_blank" rel="noreferrer">
              <TraceLine as |l|>
                <l.Icon>
                  <Icon @icon={{Globe}} />
                </l.Icon>
                <l.Title>
                  {{source.title}}
                  <span class="sr-only"> (opens in a new tab)</span>
                </l.Title>
                <l.Icon>
                  <Icon @icon={{ArrowUpRight}} />
                </l.Icon>
              </TraceLine>
            </a>
          {{/each}}
        </Trace>
      </c.Content>
    </TraceCollapsible>
  </div>
</template>
