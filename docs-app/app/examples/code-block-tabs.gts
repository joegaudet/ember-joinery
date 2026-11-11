import { Tabs } from '@ember-joinery/ember'
import { CodeBlock, highlightedCode } from '@ember-joinery/code-block'

// Upstream's route names a real model in `model:`; Joinery's examples use a
// placeholder of the same length, so the code lays out the same.
const files = [
  {
    id: 'route',
    title: 'app/api/chat/route.ts',
    language: 'ts',
    code: `import { streamText } from "ai"

export async function POST(request: Request) {
  const { messages } = await request.json()
  const result = streamText({ model: "your-provider/your-model-id", messages })

  return result.toUIMessageStreamResponse()
}`,
  },
  {
    id: 'chat',
    title: 'components/chat.tsx',
    language: 'tsx',
    code: `"use client"

import { useChat } from "@ai-sdk/react"

export function Chat() {
  const { messages } = useChat()

  return <MessageList messages={messages} />
}`,
  },
  {
    id: 'env',
    title: '.env.local',
    language: 'bash',
    code: 'AI_GATEWAY_API_KEY=your-api-key',
  },
]

const fileName = (title: string) => title.split('/').at(-1)

<template>
  <Tabs @defaultValue="route" class="w-full max-w-md" as |t|>
    <t.List>
      {{#each files key="id" as |file|}}
        <t.Trigger @value={{file.id}}>{{fileName file.title}}</t.Trigger>
      {{/each}}
    </t.List>
    {{#each files key="id" as |file|}}
      <t.Content @value={{file.id}}>
        <CodeBlock as |b|>
          <b.Header>
            <b.Title>{{file.title}}</b.Title>
            <b.Actions>
              <b.CopyButton @value={{file.code}} />
            </b.Actions>
          </b.Header>
          <b.Content @lineNumbers={{true}}>
            {{#each (highlightedCode file.code file.language) as |line|}}
              <b.Line @code={{line}} />
            {{/each}}
          </b.Content>
        </CodeBlock>
      </t.Content>
    {{/each}}
  </Tabs>
</template>
