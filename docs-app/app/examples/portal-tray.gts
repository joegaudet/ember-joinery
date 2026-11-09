import { uniqueId } from '@ember/helper'
import { Portal, PortalTarget } from '@ember-joinery/primitives/portal'

<template>
  <div class="portal-demo">
    {{#let (uniqueId) as |id|}}
      <section id={{id}} class="portal-box" aria-label="Card" data-test-jn="card">
        <strong class="portal-title">Card</strong>
        <p>The note below is the card's own, rendered in the tray.</p>
        <Portal @to="tray">
          {{! Rendered outside the card, so it names the card as its owner for the harnesses. }}
          <p class="portal-note" data-test-jn-part="note" data-test-jn-owner={{id}}>
            A note from the card.
          </p>
        </Portal>
      </section>
    {{/let}}
    <PortalTarget @name="tray" class="portal-box" aria-label="Tray" role="region" />
  </div>
  <style>
    .portal-demo {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 1rem;
    }
    .portal-box {
      min-height: 6rem;
      padding: 1rem;
      border: 1px dashed;
      border-radius: 0.5rem;
    }
    .portal-title {
      display: block;
      margin-bottom: 0.5rem;
    }
    .portal-note {
      margin: 0;
    }
  </style>
</template>
