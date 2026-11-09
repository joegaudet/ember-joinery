import { Terminal } from 'lucide'
import { Icon } from '@ember-joinery/ember'
import { CodeBlock } from '@ember-joinery/code-block'

const command = 'pnpm add ai @ai-sdk/react zod'

const output = `$ ${command}
Packages: +14
Progress: resolved 412, reused 398, downloaded 14, added 14, done
Done in 2.8s using pnpm v10.18.0`

<template>
  <div class="w-full max-w-md">
    <CodeBlock as |b|>
      <b.Header>
        <b.Title><Icon @icon={{Terminal}} />Terminal</b.Title>
        <b.Actions>
          <b.CopyButton @value={{command}} />
        </b.Actions>
      </b.Header>
      <b.Content @code={{output}} />
    </CodeBlock>
  </div>
</template>
