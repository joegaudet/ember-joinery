# Query Params

Read and write the URL's query params from a template, with no controller or router injection:
`{{qp "view"}}` is the current value, `{{withQP "view" "grid"}}` an `href` that sets it, and
`castToBoolean` reads a flag. They are ember-primitives' `qp` utilities.

<Example @name="query-params-view" @title="A view kept in the URL" />

## Usage

```gts
import { castToBoolean, qp, withQP } from '@ember-joinery/primitives/qp'

<template>
  <a href={{withQP "view" "grid"}}>Grid</a>
  <a href={{withQP "view" null}}>Default</a>

  {{#if (castToBoolean (qp "compact"))}}…{{/if}}
</template>
```

`qp` reads the current route's query params from the router service, and updates when the URL
does. `withQP` returns the current URL (with the app's `rootURL`) with the param set, or
removed for `null`. For the link to be a transition rather than a page load, the app's router
needs [`properLinks`](/primitives/proper-links.md), or the link a click handler (see the
[link helper](/primitives/link-helper.md)).

A transition keeps a query param only where a controller declares it
(`queryParams = ['view']`), as with any Ember query param; `qp` reads one from a URL you visit
either way.

## API

| Export                 | What it returns                                                                                 |
| ---------------------- | ----------------------------------------------------------------------------------------------- |
| `(qp name)`            | The param as a string, or `undefined` when the URL doesn't have it                              |
| `(withQP name value)`  | An `href`: the current URL with `name` set to `value` (`null` removes)                          |
| `castToBoolean(value)` | `false` for no value and `''`, `0`, `false`, `f`, `off`, `no`, `null`, `undefined`; else `true` |

### From ember-primitives

The same names. `withQP` keeps the app's `rootURL` and can remove a param, and
`castToBoolean` matches its words in any case (`FALSE` too).

## Testing

In an application test, `visit('/products?view=grid')` and read the page. To give a test its
own routes, use `setupRouting` from `@ember-joinery/test-support` (see
[Proper Links](/primitives/proper-links.md#testing)).
