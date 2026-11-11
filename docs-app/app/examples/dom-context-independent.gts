import { tracked } from '@glimmer/tracking'
import { on } from '@ember/modifier'
import type { TOC } from '@ember/component/template-only'
import { Consume, Provide } from '@ember-joinery/primitives/dom-context'

/** What both providers give under the key "store", though each makes its own class. */
interface Store {
  count: number
  doit: () => void
}

class Incrementer {
  @tracked count = 2
  doit = () => this.count++
}

class Doubler {
  @tracked count = 2
  doit = () => (this.count *= 2)
}

// A string key leaves the data untyped, so the consumer says what it expects.
const asStore = (data: unknown) => data as Store

/** Reads the nearest "store" above it, whichever class that provider made. */
const StoreConsumer: TOC<{ Blocks: { default: [store: Store] } }> = <template>
  <Consume @key="store" as |context|>
    {{yield (asStore context.data)}}
  </Consume>
</template>

<template>
  <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 1rem;">
    <section
      data-test-jn="store"
      data-test-jn-name="incrementer"
      aria-label="Incrementer store"
      style="padding: 1rem; border: 1px solid; border-radius: 0.5rem;"
    >
      <p><strong>Incrementer store</strong></p>
      <Provide @data={{Incrementer}} @key="store">
        <StoreConsumer as |store|>
          <p>Count: <output data-test-jn-part="count">{{store.count}}</output></p>
          <button type="button" data-test-jn-part="action" {{on "click" store.doit}}>
            Increment
          </button>
        </StoreConsumer>
      </Provide>
    </section>

    <section
      data-test-jn="store"
      data-test-jn-name="doubler"
      aria-label="Doubler store"
      style="padding: 1rem; border: 1px solid; border-radius: 0.5rem;"
    >
      <p><strong>Doubler store</strong></p>
      <Provide @data={{Doubler}} @key="store">
        <StoreConsumer as |store|>
          <p>Count: <output data-test-jn-part="count">{{store.count}}</output></p>
          <button type="button" data-test-jn-part="action" {{on "click" store.doit}}>
            Double
          </button>
        </StoreConsumer>
      </Provide>
    </section>
  </div>
</template>
