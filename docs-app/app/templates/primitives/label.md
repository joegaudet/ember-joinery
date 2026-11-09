# Label

A label for a control, as Radix's `Label`: a native `<label>`, which names its control and
passes it a click, and whose text a double click doesn't select. It has no styles; the styled
[Label](/components/label.md) is built on it.

<Example @name="label-headless" @title="A label for an input" />

## Usage

```gts
import { on } from '@ember/modifier'
import { Label, preventLabelSelection } from '@ember-joinery/primitives/label'

<template>
  <Label for="email">Your email address</Label>
  <input id="email" type="email" />

  {{! the behaviour on an element of your own }}
  <span id="volume-label" {{on "mousedown" preventLabelSelection}}>Volume</span>
</template>
```

`preventLabelSelection` is Radix Label's one behaviour, as a `mousedown` listener: the second
press of a double click on the label's text is prevented, so the text isn't selected, while a
press on a control inside the label (`button`, `input`, `select`, `textarea`) is left alone.
Your own `mousedown` listeners on a `Label` run first, and one that calls `preventDefault()`
has already done its work.

## API

| Argument | Type     | Default | What it does                                       |
| -------- | -------- | ------- | -------------------------------------------------- |
| `@as`    | tag name | `label` | The tag to render                                  |
| `@name`  | `string` |         | Its name, for `LabelHarness` (`data-test-jn-name`) |

It yields its block and takes attributes, `for` among them.

## Accessibility

Tie the label to its control with `for`, or put the control inside it, and the control is named
by the label's text. With `@as` (anything but a `<label>`), name the control with
`aria-labelledby` instead.

## Testing

```ts
import { LabelHarness } from '@ember-joinery/test-support'

const email = new LabelHarness()
email.text // 'Your email address'
email.control // the <input> it names
await email.click() // focuses it
```
