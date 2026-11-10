import { ArrowUpRight, ChevronRight, Globe } from 'lucide'
import { Dialog, Icon, Trace, TraceLine } from '@ember-joinery/ember'

const results = [
  {
    title: 'Caching build outputs',
    url: 'https://nextjs.org/docs/app/guides/caching',
  },
  {
    title: 'Image optimization reference',
    url: 'https://nextjs.org/docs/app/api-reference/components/image',
  },
  {
    title: 'Deploy hooks and cache keys',
    url: 'https://vercel.com/docs/deploy-hooks',
  },
]

<template>
  <Trace class="max-w-sm">
    <Dialog as |d|>
      <d.Trigger>
        <TraceLine as |l|>
          <l.Icon>
            <Icon @icon={{Globe}} />
          </l.Icon>
          <l.Title>Searched the web for cache keys</l.Title>
          <l.Icon>
            <Icon @icon={{ChevronRight}} />
          </l.Icon>
        </TraceLine>
      </d.Trigger>
      <d.Content>
        <d.Header>
          <d.Title>Searched the web for cache keys</d.Title>
          <d.Description>
            Three results were used in the response.
          </d.Description>
        </d.Header>
        <Trace>
          {{#each results as |result|}}
            <a href={{result.url}} target="_blank" rel="noreferrer">
              <TraceLine as |l|>
                <l.Icon>
                  <Icon @icon={{Globe}} />
                </l.Icon>
                <l.Title>
                  {{result.title}}
                  <span class="sr-only"> (opens in a new tab)</span>
                </l.Title>
                <l.Icon>
                  <Icon @icon={{ArrowUpRight}} />
                </l.Icon>
              </TraceLine>
            </a>
          {{/each}}
        </Trace>
      </d.Content>
    </Dialog>
  </Trace>
</template>
