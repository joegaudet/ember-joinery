import { CodeBlock } from '@ember-joinery/code-block'

const code = `export default {
  experimental: {
    reactCompiler: true,
    viewTransition: true,
  },
  images: {
    remotePatterns: [{ hostname: "avatars.githubusercontent.com" }],
  },
}`

const highlighted = [2, 3]

const lines = code.split('\n')
const variantFor = (index: number) => (highlighted.includes(index) ? 'highlighted' : 'default')

<template>
  <div class="w-full max-w-md">
    <CodeBlock as |b|>
      <b.Content @lineNumbers={{true}}>
        {{#each lines as |line index|}}
          <b.Line @code={{line}} @variant={{variantFor index}} />
        {{/each}}
      </b.Content>
    </CodeBlock>
  </div>
</template>
