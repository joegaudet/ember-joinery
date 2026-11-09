# Native Value

A native control's value, controlled or uncontrolled, as Radix's controls have it. Joinery's
[Input](/components/input.md), [Textarea](/components/textarea.md) and
[Native Select](/components/native-select.md) are built on it, and `{{nativeValue}}` gives any
`<input>`, `<textarea>` or `<select>` of your own the same behaviour.

<Example @name="native-value-form" @title="An input of your own" />

## Usage

```gts
import { nativeValue } from '@ember-joinery/primitives/native-value'

<template>
  <input
    aria-label="Name"
    {{nativeValue value=@value defaultValue=@defaultValue onValueChange=@onValueChange}}
  />
</template>
```

It takes the three arguments of the [controllable state](/primitives/controllable-state.md)
pattern:

| Argument        | What it does                                                                      |
| --------------- | --------------------------------------------------------------------------------- |
| `value`         | Controls the value. While you pass anything but `undefined`, the control shows it |
| `defaultValue`  | The value it starts with when you don't control it                                |
| `onValueChange` | Called with each new value (on `input`), controlled or not                        |

## Controlled

With `value`, the control shows it from the start and whenever it changes. Someone typing or
choosing calls `onValueChange`, and then the control shows `value` again: pass the new value
back to take the change, change it (a username in lower case), or leave it to refuse the
change, which is undone, as in React. While an input method is composing (Japanese, Chinese,
Korean…), that waits until it is done, so composition isn't broken.

## Uncontrolled

Without `value`, the control keeps its own value, starting from `defaultValue`, or with none,
from what it shows when it is inserted: its `value` attribute, or a select's first or
`selected` option. `onValueChange` still hears every change.

## Forms

A form reset puts the control back to the value it started with, after the browser's own
reset, and calls `onValueChange` with it, as Radix's controls do. A reset that a listener
cancels (`event.preventDefault()`) changes nothing.

## Selects and file inputs

- A `<select>` shows its value again whenever its options change, so a value whose option
  renders later (an `{{#each}}`, data that loads) is chosen once it's there. A select with no
  option for the value keeps the option it shows rather than showing none, as React's does.
- A file input's value can only be cleared (browsers throw on anything else), so it is given
  only an empty `value`. Read its files from a `change` listener.

## Testing

The harness of the component that uses it reads the element's own value, so it works the same
controlled or not: `InputHarness`, `TextareaHarness` and `NativeSelectHarness` from
`@ember-joinery/test-support`. Test both ways: leave the value to the control and check it
changes; control it, check the callback, and check that a refused change is undone.
