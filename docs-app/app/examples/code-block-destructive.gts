import { CodeBlock } from '@ember-joinery/code-block'

const error = `TypeError: Cannot read properties of undefined (reading 'map')
    at MessageList (components/message-list.tsx:18:22)
    at renderWithHooks (react-dom.development.js:16305:18)`

<template>
  <div class="w-full max-w-md">
    <CodeBlock @variant="destructive" as |b|>
      <b.Header>
        <b.Title>Error</b.Title>
        <b.Actions>
          <b.CopyButton @value={{error}} />
        </b.Actions>
      </b.Header>
      <b.Content @code={{error}} @wrap={{true}} />
    </CodeBlock>
  </div>
</template>
