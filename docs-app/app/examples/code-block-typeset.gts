import { FileCode } from 'lucide'
import { Icon } from '@ember-joinery/ember'
import { CodeBlock, highlightedCode } from '@ember-joinery/code-block'

// Upstream's route names a real model in `model:`; Joinery's examples use a
// placeholder of the same length, so the code lays out the same. Upstream
// calls it `code`, a name that would turn the template's <code> elements into calls to it.
const source = `import { streamText } from "ai"

export async function POST(request: Request) {
  const { messages } = await request.json()
  const result = streamText({ model: "your-provider/your-model-id", messages })

  return result.toUIMessageStreamResponse()
}`

<template>
  {{! ui.shadcn.com styles "typeset" prose with its own typeset.css, which Joinery doesn't ship. }}
  <div class="typeset w-full max-w-md">
    <h3>Stream a response</h3>
    <p>
      Create a route handler that calls
      <code>streamText</code>
      and returns the stream to the client.
    </p>
    <CodeBlock as |b|>
      <b.Header>
        <b.Title><Icon @icon={{FileCode}} />app/api/chat/route.ts</b.Title>
        <b.Actions>
          <b.CopyButton @value={{source}} />
        </b.Actions>
      </b.Header>
      <b.Content @lineNumbers={{true}}>
        {{#each (highlightedCode source "ts") as |line|}}
          <b.Line @code={{line}} />
        {{/each}}
      </b.Content>
    </CodeBlock>
    <p>
      The
      <code>useChat</code>
      hook reads the stream on the client and renders the answer while it is written.
    </p>
  </div>
</template>
