import { tracked } from '@glimmer/tracking'
import { on } from '@ember/modifier'
import { Consume, Provide } from '@ember-joinery/primitives/dom-context'

/** The provider makes one Counter; every consumer inside it reads that one. */
class Counter {
  @tracked count = 0
  increment = () => this.count++
  decrement = () => this.count--
}

<template>
  <div data-test-jn="counter">
    <Provide @data={{Counter}}>
      <Consume @key={{Counter}} as |context|>
        <div role="group" aria-label="Count">
          <button
            type="button"
            aria-label="One less"
            data-test-jn-part="decrement"
            {{on "click" context.data.decrement}}
          >−</button>
          <output data-test-jn-part="count">{{context.data.count}}</output>
          <button
            type="button"
            aria-label="One more"
            data-test-jn-part="increment"
            {{on "click" context.data.increment}}
          >+</button>
        </div>
      </Consume>

      <section>
        <p>Further down, another consumer:</p>
        <Consume @key={{Counter}} as |context|>
          <p data-test-jn-part="echo">The count is {{context.data.count}}.</p>
        </Consume>
      </section>
    </Provide>
  </div>
</template>
