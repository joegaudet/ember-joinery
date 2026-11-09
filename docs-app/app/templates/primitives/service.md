# Service

State a whole app shares, such as the toaster's queue or the color scheme, without registering
an Ember service: `service` makes one instance of a class per owner, the first time it is asked
for, and destroys it with the owner. Each test has its own owner, so each test starts fresh.

<Example @name="service-counter" @title="One cart for the whole app" />

## Usage

```gts
import { tracked } from '@glimmer/tracking'
import { service } from '@ember-joinery/primitives/service'

class Cart {
  @tracked count = 0
  add = () => (this.count += 1)
}

// In JavaScript: anything with an owner (a component, route or controller), and the class
class AddToCart extends Component {
  get cart() {
    return service(this, Cart)
  }
}

// In a template: the class alone
<template>{{#let (service Cart) as |cart|}}{{cart.count}}{{/let}}</template>
```

The class is constructed with the owner and gets that owner, so `@service` injections work in
it after its constructor. For cleanup, call `registerDestructor(this, …)` in the constructor.
A function in place of the class is called once per owner to make the instance:
`service(this, () => new Cart(42))`.

Unlike `@service`, nothing is registered by name, so a module that never asks for the class
never loads it. It is ember-primitives' `createService`, and covers its `service` helper's use.

## Testing

Tests can reach the same instance through the test's owner, `service(this.owner, Cart)`, but
prefer driving the components that use it, as a user would.
