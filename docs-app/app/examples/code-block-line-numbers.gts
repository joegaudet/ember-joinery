import { CodeBlock } from '@ember-joinery/code-block'

const code = `{
  "name": "chat",
  "private": true,
  "scripts": {
    "dev": "next dev",
    "build": "next build"
  }
}`

<template>
  <div class="w-full max-w-md">
    <CodeBlock as |b|>
      <b.Content @code={{code}} @lineNumbers={{true}} />
    </CodeBlock>
  </div>
</template>
