import { CodeBlock } from '@ember-joinery/code-block'

const logs = Array.from(
  { length: 40 },
  (_, index) =>
    `[${String(index + 1).padStart(2, '0')}] GET /api/chat 200 in ${12 + ((index * 7) % 40)}ms`,
).join('\n')

<template>
  <div class="w-full max-w-md">
    <CodeBlock as |b|>
      <b.Header>
        <b.Title>Logs</b.Title>
        <b.Actions>
          <b.CopyButton @value={{logs}} />
        </b.Actions>
      </b.Header>
      <b.Content @code={{logs}} class="max-h-48 scroll-fade-y" />
    </CodeBlock>
  </div>
</template>
