import { Bubble, Message } from '@ember-joinery/ember'
import { CodeBlock, highlightedCode } from '@ember-joinery/code-block'

// Upstream's route names a real model in `model:`; Joinery's examples use a
// placeholder of the same length, so the code lays out the same.
const code = `import { streamText } from "ai"

export async function POST(request: Request) {
  const { messages } = await request.json()

  const result = streamText({
    model: "your-provider/your-model-id",
    messages,
  })

  return result.toUIMessageStreamResponse()
}`

<template>
  <div class="flex w-full max-w-md flex-col gap-4 text-sm">
    <Message @align="end" as |m|>
      <m.Content>
        <Bubble @variant="muted" as |b|>
          <b.Content>How do I stream a response?</b.Content>
        </Bubble>
      </m.Content>
    </Message>
    <Message as |m|>
      <m.Content class="gap-3">
        <p>Create a route handler that returns the stream:</p>
        <CodeBlock as |b|>
          <b.Header>
            <b.Title>app/api/chat/route.ts</b.Title>
            <b.Actions>
              <b.CopyButton @value={{code}} />
            </b.Actions>
          </b.Header>
          <b.Content>
            {{#each (highlightedCode code "ts") as |line|}}
              <b.Line @code={{line}} />
            {{/each}}
          </b.Content>
        </CodeBlock>
        <p>The client reads it with useChat.</p>
      </m.Content>
    </Message>
  </div>
</template>
