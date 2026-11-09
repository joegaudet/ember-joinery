import { CodeBlock, highlightedCode } from '@ember-joinery/code-block'

const samples = [
  {
    language: 'css',
    title: 'app/globals.css',
    code: `@import "tailwindcss";

:root {
  --radius: 0.625rem;
}`,
  },
  {
    language: 'python',
    title: 'main.py',
    code: `def greet(name: str) -> str:
    return f"Hello, {name}!"`,
  },
  {
    language: 'text',
    title: 'notes.txt',
    code: 'A language that is not in the list renders as plain text.',
  },
]

<template>
  <div class="flex w-full max-w-md flex-col gap-4">
    {{#each samples key="language" as |sample|}}
      <CodeBlock as |b|>
        <b.Header>
          <b.Title>{{sample.title}}</b.Title>
        </b.Header>
        <b.Content>
          {{#each (highlightedCode sample.code sample.language) as |line|}}
            <b.Line @code={{line}} />
          {{/each}}
        </b.Content>
      </CodeBlock>
    {{/each}}
  </div>
</template>
