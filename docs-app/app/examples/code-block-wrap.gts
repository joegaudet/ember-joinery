import { CodeBlock } from '@ember-joinery/code-block'

// Upstream's error names a real model; Joinery's examples use a placeholder of the same
// length, so the error wraps the same.
const output = `Error: The model "your-provider/your-model-id" returned an error: Request too large. The prompt is 212,431 tokens and the context window is 200,000 tokens. Remove some messages or summarize the conversation and try again.`

<template>
  <div class="flex w-full max-w-md flex-col gap-4">
    <CodeBlock as |b|>
      <b.Content @code={{output}} />
    </CodeBlock>
    <CodeBlock as |b|>
      <b.Content @code={{output}} @wrap={{true}} />
    </CodeBlock>
  </div>
</template>
