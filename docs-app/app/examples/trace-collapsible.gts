import { Terminal } from 'lucide'
import { Icon, TraceCollapsible, TraceLine } from '@ember-joinery/ember'
import { CodeBlock } from '@ember-joinery/code-block'

const output = `$ node --version
v24.18.0`

<template>
  <div class="w-full max-w-sm">
    <TraceCollapsible as |c|>
      <c.Trigger>
        <TraceLine as |l|>
          <l.Icon>
            <Icon @icon={{Terminal}} />
          </l.Icon>
          <l.Title>Ran node --version</l.Title>
        </TraceLine>
      </c.Trigger>
      <c.Content>
        <CodeBlock @size="sm" as |b|>
          <b.Content @code={{output}} @wrap={{true}} class="max-h-64" />
        </CodeBlock>
      </c.Content>
    </TraceCollapsible>
  </div>
</template>
