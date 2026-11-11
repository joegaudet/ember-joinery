import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { on } from '@ember/modifier'
import { service } from '@ember-joinery/primitives/service'

/** State the whole app shares: one instance per app, and a fresh one in every test. */
class Cart {
  @tracked count = 0
  add = () => (this.count += 1)
}

class AddToCart extends Component<{ Args: { item: string } }> {
  get cart() {
    return service(this, Cart)
  }

  <template>
    <button
      type="button"
      data-test-jn-part="add"
      data-test-jn-value={{@item}}
      {{on "click" this.cart.add}}
    >Add {{@item}}</button>
  </template>
}

<template>
  <div data-test-jn="shop">
    <AddToCart @item="a lamp" />
    <AddToCart @item="a chair" />
    {{#let (service Cart) as |cart|}}
      <p>Items in the cart: <output data-test-jn-part="count">{{cart.count}}</output></p>
    {{/let}}
  </div>
</template>
