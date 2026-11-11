import { Consume, Provide } from '@ember-joinery/primitives/dom-context'

/** The provider makes one State from the class, and the consumer inside it reads that one. */
class State {
  greeting = 'hello'
  name = 'world'
}

<template>
  <Provide @data={{State}}>
    <Consume @key={{State}} as |context|>
      <p data-test-jn="greeting">{{context.data.greeting}},
        {{context.data.name}}!</p>
    </Consume>
  </Provide>
</template>
