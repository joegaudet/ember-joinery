import Component from '@glimmer/component'
import { As } from '@ember-joinery/primitives/as'
import { controllable } from '@ember-joinery/primitives/controllable-state'
import { idFor } from '@ember-joinery/primitives/id'
import { KeyCombo } from '@ember-joinery/primitives/keys'
import { part } from '@ember-joinery/primitives/part'
import { Presence } from '@ember-joinery/primitives/presence'

/**
 * A disclosure on the primitives, so this build covers what they depend on: `As` (an
 * @embroider/macros branch), `part` (ember-modifier) and `Presence` (@ember/test-waiters).
 */
class Disclosure extends Component {
  open = controllable(this, 'open', false)

  trigger = part(() => ({
    attributes: {
      'aria-expanded': String(this.open.value),
      'aria-controls': idFor(this, 'content'),
      'data-test-jn-part': 'trigger',
    },
    on: { click: () => this.open.set(open => !open) },
  }))

  <template>
    <div data-test-jn="disclosure">
      <As @tag="button" type="button" {{this.trigger}}>{{@label}}</As>
      <Presence @present={{this.open.value}} as |presence|>
        <div id={{idFor this "content"}} data-test-jn-part="content" {{presence.ref}}>
          {{yield}}
        </div>
      </Presence>
    </div>
  </template>
}

<template>
  <main>
    <h1>Joinery in a classic app</h1>
    <p>
      This app consumes Joinery's v2 addons through ember-auto-import, with no Vite. CI builds it
      and runs its smoke test.
    </p>
    <p>Search with <KeyCombo @name="search" @keys="Ctrl+K" />.</p>
    <Disclosure @label="Details">The primitives work here too.</Disclosure>
  </main>
</template>
