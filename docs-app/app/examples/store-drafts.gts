import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { on } from '@ember/modifier'
import { createStore } from '@ember-joinery/primitives/store'

/** A reply's draft: each Reply component gets its own, kept for as long as it renders. */
class Draft {
  @tracked text = ''
  update = (event: Event) => (this.text = (event.target as HTMLTextAreaElement).value)
}

class Reply extends Component<{ Args: { to: string } }> {
  get draft() {
    return createStore(this, Draft)
  }

  <template>
    <div data-test-jn="reply" data-test-jn-name={{@to}}>
      <label>
        Reply to
        {{@to}}
        <textarea data-test-jn-part="text" {{on "input" this.draft.update}}></textarea>
      </label>
      <p data-test-jn-part="count">{{this.draft.text.length}} characters</p>
    </div>
  </template>
}

<template>
  <div
    style="display: grid; gap: 1rem; grid-template-columns: repeat(auto-fit, minmax(12rem, 1fr));"
  >
    <Reply @to="Ada" />
    <Reply @to="Grace" />
  </div>
</template>
