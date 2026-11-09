# Narrowing

Type guards that narrow a value in TypeScript and work in a template, where `typeof` and
`instanceof` can't be written: `{{#if (isElement @target)}}`. They are ember-primitives'
`narrowing` and `type-utils`.

<Example @name="narrowing-guards" @title="What each value is" />

## Usage

```ts
import { isElement, isNewable, isString, type Newable } from '@ember-joinery/primitives/narrowing'

function labelOf(target: unknown) {
  if (isString(target)) return target // a string from here on
  if (isElement(target)) return target.getAttribute('aria-label') // an Element
}

function make<T extends object>(definition: Newable<T> | (() => T)): T {
  return isNewable<T>(definition) ? new definition() : definition()
}
```

## API

| Export              | What it does                                                                   |
| ------------------- | ------------------------------------------------------------------------------ |
| `isString(value)`   | Whether `value` is a string (not a `String` object)                            |
| `isElement(value)`  | Whether `value` is a DOM element, from this window or another (an iframe's)    |
| `isNewable(value)`  | Whether `value` is a class, to call with `new`, rather than a function to call |
| `Newable<T>` (type) | Anything `new` makes a `T` with                                                |

`isNewable` is the check ember-primitives keeps private in its `utils`, and `isElement` also
accepts another window's elements, which `instanceof Element` doesn't.
