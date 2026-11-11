import { Terminal } from 'lucide'
import { Icon } from '@ember-joinery/ember'
import { CodeBlock } from '@ember-joinery/code-block'

const output = `$ pnpm add ai @ai-sdk/react zod
Progress: resolved 412, reused 398, downloaded 14, added 14, done
Done in 2.8s using pnpm v10.18.0`

<template>
  <div class="flex w-full max-w-md flex-col gap-4">
    <CodeBlock as |b|>
      <b.Header>
        <b.Title><Icon @icon={{Terminal}} />Terminal</b.Title>
        <b.Actions>
          <b.CopyButton @value={{output}} />
        </b.Actions>
      </b.Header>
      <b.Content @code={{output}} @wrap={{true}} />
    </CodeBlock>
    <CodeBlock @size="sm" as |b|>
      <b.Header>
        <b.Title><Icon @icon={{Terminal}} />Terminal</b.Title>
        <b.Actions>
          <b.CopyButton @value={{output}} />
        </b.Actions>
      </b.Header>
      <b.Content @code={{output}} @wrap={{true}} />
    </CodeBlock>
  </div>
</template>
