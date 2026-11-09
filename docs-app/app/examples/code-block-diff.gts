import { CodeBlock, type CodeBlockLineVariant } from '@ember-joinery/code-block'

const patch = ` export function Greeting({ name }: { name: string }) {
-  return <p>Hello, {name}</p>
+  return <p className="text-sm text-muted-foreground">
+    Hello, {name}!
+  </p>
 }`

function getVariant(line: string): CodeBlockLineVariant {
  if (line.startsWith('+')) {
    return 'added'
  }

  if (line.startsWith('-')) {
    return 'removed'
  }

  return 'default'
}

// A diff row starts with +, - or a space. The marker is not part of the code.
const rows = patch.split('\n').map(line => ({ code: line.slice(1), variant: getVariant(line) }))

<template>
  <div class="w-full max-w-md">
    <CodeBlock as |b|>
      <b.Header>
        <b.Title>components/greeting.tsx</b.Title>
        <b.Actions>
          <b.CopyButton @value={{patch}} />
        </b.Actions>
      </b.Header>
      <b.Content>
        {{#each rows as |row|}}
          <b.Line @code={{row.code}} @variant={{row.variant}} />
        {{/each}}
      </b.Content>
    </CodeBlock>
  </div>
</template>
