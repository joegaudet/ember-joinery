import { CodeBlock, highlightedCode } from '@ember-joinery/code-block'

const code = `{
  "location": "San Francisco",
  "temperature": 18,
  "unit": "celsius",
  "conditions": ["fog", "wind"]
}`

<template>
  <div class="w-full max-w-md">
    <CodeBlock as |b|>
      <b.Header>
        <b.Title>getWeather output</b.Title>
      </b.Header>
      <b.Content>
        {{#each (highlightedCode code "json") as |line|}}
          <b.Line @code={{line}} />
        {{/each}}
      </b.Content>
    </CodeBlock>
  </div>
</template>
