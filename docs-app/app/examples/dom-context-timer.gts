import { registerDestructor } from '@ember/destroyable'
import { tracked } from '@glimmer/tracking'
import { Consume, Provide } from '@ember-joinery/primitives/dom-context'

class Timer {
  @tracked seconds = 0

  constructor() {
    const interval = setInterval(() => this.seconds++, 1000)
    // Runs when the provider goes: what a function returns shares the provider's lifetime.
    registerDestructor(this, () => clearInterval(interval))
  }
}

/** A function as @data is called once per provider, and its result is what consumers read. */
function createTimer() {
  return new Timer()
}

<template>
  <Provide @data={{createTimer}}>
    <div
      data-test-jn="timer"
      style="padding: 1rem 1.5rem; border: 1px solid; border-radius: 0.5rem;"
    >
      <p><strong>Timer example</strong></p>

      <Consume @key={{createTimer}} as |context|>
        <p data-test-jn-part="elapsed">Seconds elapsed: {{context.data.seconds}}</p>
      </Consume>

      <Consume @key={{createTimer}} as |context|>
        <p data-test-jn-part="also">Also showing: {{context.data.seconds}}s</p>
      </Consume>
    </div>
  </Provide>
</template>
