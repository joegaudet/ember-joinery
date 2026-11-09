import { Terminal } from 'lucide'
import { Icon } from '@ember-joinery/ember'
import { CodeBlock, highlightedCode } from '@ember-joinery/code-block'

const code = `pnpm add ai @ai-sdk/react zod
pnpm dev`

<template>
  {{!
    Upstream's Arabic, which its preview opens in. The code reads left to right whatever the
    page's direction, and the header follows the page.
  }}
  <div class="flex w-full max-w-md flex-col gap-3 text-sm" dir="rtl">
    <p>ثبّت الحزم، ثم شغّل خادم التطوير.</p>
    <CodeBlock as |b|>
      <b.Header>
        <b.Title><Icon @icon={{Terminal}} />الطرفية</b.Title>
        <b.Actions>
          <b.CopyButton @value={{code}} />
        </b.Actions>
      </b.Header>
      <b.Content @lineNumbers={{true}}>
        {{#each (highlightedCode code "bash") as |line|}}
          <b.Line @code={{line}} />
        {{/each}}
      </b.Content>
    </CodeBlock>
  </div>
</template>
