import { ArrowUp } from 'lucide'
import { Button, Icon } from '@ember-joinery/ember'
import { Carousel } from '@ember-joinery/carousel'
import { CodeBlock, highlightedCode } from '@ember-joinery/code-block'

const install = 'pnpm add @ember-joinery/code-block'
const slides = ['One', 'Two', 'Three']

<template>
  <main>
    <h1>Joinery in a Vite app</h1>
    <p>
      This app imports Joinery's packages and CSS the way a Vite (Embroider) app does. CI builds it
      and runs its smoke test.
    </p>
    <p>
      <Button @name="save" @variant="outline">Save</Button>
      <Button @name="up" @size="icon" aria-label="Back to top"><Icon @icon={{ArrowUp}} /></Button>
    </p>
    <CodeBlock @name="install" as |b|>
      <b.Header>
        <b.Title>Terminal</b.Title>
        <b.Actions><b.CopyButton @value={{install}} /></b.Actions>
      </b.Header>
      <b.Content>
        {{#each (highlightedCode install "bash") as |line|}}<b.Line @code={{line}} />{{/each}}
      </b.Content>
    </CodeBlock>
    <Carousel @name="slides" aria-label="Slides" style="width: 240px; margin: 0 48px" as |c|>
      <c.Content>
        {{#each slides as |slide|}}
          <c.Item>{{slide}}</c.Item>
        {{/each}}
      </c.Content>
      <c.Previous />
      <c.Next />
    </Carousel>
  </main>
</template>
