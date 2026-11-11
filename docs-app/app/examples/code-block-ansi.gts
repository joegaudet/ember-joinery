import { Terminal } from 'lucide'
import { Icon } from '@ember-joinery/ember'
import { CodeBlock, highlightedCode } from '@ember-joinery/code-block'

const output = `$ pnpm test
\x1b[32m✓\x1b[39m src/format.test.ts \x1b[2m(4 tests)\x1b[22m
\x1b[32m✓\x1b[39m src/parse.test.ts \x1b[2m(7 tests)\x1b[22m
\x1b[31m✗\x1b[39m src/stream.test.ts \x1b[2m(3 tests | 1 failed)\x1b[22m

\x1b[31mAssertionError: expected 'hello' to be 'hello world'\x1b[39m

Tests  \x1b[31m1 failed\x1b[39m | \x1b[32m13 passed\x1b[39m (14)`

// eslint-disable-next-line no-control-regex
const plain = output.replace(/\x1b\[[\d;]*m/g, '')

<template>
  <div class="w-full max-w-md">
    <CodeBlock as |b|>
      <b.Header>
        <b.Title><Icon @icon={{Terminal}} />Terminal</b.Title>
        <b.Actions>
          <b.CopyButton @value={{plain}} />
        </b.Actions>
      </b.Header>
      <b.Content @wrap={{true}}>
        {{#each (highlightedCode output "ansi") as |line|}}
          <b.Line @code={{line}} />
        {{/each}}
      </b.Content>
    </CodeBlock>
  </div>
</template>
