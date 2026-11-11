import { Terminal } from 'lucide'
import { Icon, Trace, TraceCollapsible, TraceLine } from '@ember-joinery/ember'
import { CodeBlock } from '@ember-joinery/code-block'

const output = `$ node --version
v24.18.0`

const error = `$ pnpm dev
Error: listen EADDRINUSE: address already in use :::3000
    at Server.setupListenHandle [as _listen2] (node:net:1908:16)`

<template>
  <div class="w-full max-w-md">
    <Trace>
      <TraceCollapsible @defaultOpen={{true}} as |c|>
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
      <TraceCollapsible @defaultOpen={{true}} as |c|>
        <c.Trigger>
          <TraceLine @status="error" as |l|>
            <l.Icon>
              <Icon @icon={{Terminal}} />
            </l.Icon>
            <l.Title>Failed to run pnpm dev</l.Title>
          </TraceLine>
        </c.Trigger>
        <c.Content>
          <CodeBlock @size="sm" @variant="destructive" as |b|>
            <b.Content @code={{error}} @wrap={{true}} class="max-h-64" />
          </CodeBlock>
        </c.Content>
      </TraceCollapsible>
    </Trace>
  </div>
</template>
