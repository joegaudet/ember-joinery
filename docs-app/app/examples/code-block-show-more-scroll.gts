import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { on } from '@ember/modifier'
import { uniqueId } from '@ember/helper'
import { ChevronDown } from 'lucide'
import { Button, Icon } from '@ember-joinery/ember'
import { CodeBlock, highlightedCode } from '@ember-joinery/code-block'

const code = `"use client"

import * as React from "react"
import { useChat } from "@ai-sdk/react"

import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"

export function Chat() {
  const [input, setInput] = React.useState("")
  const { messages, sendMessage, status } = useChat()

  return (
    <div className="flex flex-col gap-4">
      {messages.map((message) => (
        <div key={message.id}>
          {message.parts.map((part, index) =>
            part.type === "text" ? <p key={index}>{part.text}</p> : null
          )}
        </div>
      ))}
      <form
        onSubmit={(event) => {
          event.preventDefault()
          sendMessage({ text: input })
          setInput("")
        }}
      >
        <Input value={input} onChange={(event) => setInput(event.target.value)} />
        <Button disabled={status !== "ready"}>Send</Button>
      </form>
    </div>
  )
}`

export default class CodeBlockShowMoreScroll extends Component {
  @tracked expanded = false

  id = uniqueId()
  toggle = () => (this.expanded = !this.expanded)

  <template>
    <div class="w-full max-w-md">
      <CodeBlock as |b|>
        <b.Header>
          <b.Title>components/chat.tsx</b.Title>
          <b.Actions>
            <b.CopyButton @value={{code}} />
          </b.Actions>
        </b.Header>
        <b.Content
          id={{this.id}}
          @lineNumbers={{true}}
          class={{if
            this.expanded
            "max-h-96 scroll-fade-y"
            "max-h-64 scroll-fade-y overflow-y-hidden"
          }}
        >
          {{#each (highlightedCode code "tsx") as |line|}}
            <b.Line @code={{line}} />
          {{/each}}
        </b.Content>
        <b.Footer class="justify-center">
          <Button
            @variant="ghost"
            @size="xs"
            aria-expanded={{if this.expanded "true" "false"}}
            aria-controls={{this.id}}
            {{on "click" this.toggle}}
          >
            <Icon @icon={{ChevronDown}} class="transition-transform in-aria-expanded:rotate-180" />
            {{if this.expanded "Show less" "Show more"}}
          </Button>
        </b.Footer>
      </CodeBlock>
    </div>
  </template>
}
