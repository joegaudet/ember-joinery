# Service

State a whole app shares, such as the toaster's queue or the color scheme, without registering
an Ember service: `service` makes one instance of a class per owner, the first time it is asked
for, and destroys it with the owner. Each test has its own owner, so each test starts fresh.

<Example @name="service-counter" @title="One cart for the whole app" />

A name in place of the class reads a service registered with the app, as `@service` does, so a
template needs no backing class to use one:

<Example @name="service-router" @title="A registered service, by name" />

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
never loads it. It is ember-primitives' `createService`, with a template form.

## A registered service

`(service "router")` in a template, and `service(this, 'router')` in JavaScript, return the
service registered under that name, typed through `@ember/service`'s `Registry`. It throws if
there is none.

## Loading a service on demand

`asyncService` is for a service whose class pulls in something large: the loader runs the first
time any part of the app asks, and everything that asks with the same loader then shares one
instance per owner.

<Example @name="service-async" @title="A service loaded when first asked for" />

```ts
import { asyncService } from '@ember-joinery/primitives/service'

const loadRates = () => import('./exchange-rates.ts') // default export: the class

class Price extends Component {
  get rates() {
    return asyncService(this, loadRates)
  }
}
```

It returns a reactive state rather than the instance: `isLoading` while the class loads, then
`resolved` (the instance) or `error` (`{ reason, original }`). The loader resolves with the
class, a function returning the instance, or a module whose default export is either; the
loader itself is the key, so share one function.

### From ember-primitives

| ember-primitives                         | Joinery                                                              |
| ---------------------------------------- | -------------------------------------------------------------------- |
| `createService(this, Class)`             | `service(this, Class)`, also `(service Class)` in a template         |
| `(service "router")` (`helpers/service`) | `(service "router")`, also `service(this, 'router')`                 |
| `createAsyncService(this, loader)`       | `asyncService(this, loader)`, with one instance per owner (per test) |

## Testing

Tests can reach the same instance through the test's owner, `service(this.owner, Cart)`, but
prefer driving the components that use it, as a user would.
