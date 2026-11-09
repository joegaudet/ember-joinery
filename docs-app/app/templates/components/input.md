# Input

A text input component for forms and user data entry with built-in styling and accessibility
features.

Upstream's first example shows an input in a Field, with a label and a description; Field
hasn't landed in Joinery yet, and the example comes with it. The examples below show an input
on its own.

## Installation

```bash
pnpm add @ember-joinery/ember
```

Import Joinery's CSS once (see [Installation](/getting-started/installation.md)), then the
component where you use it:

```gts
import { Input } from '@ember-joinery/ember'
```

## Usage

```gts
<Input />
```

It renders a native `<input>`, so `type`, `placeholder`, `name`, `disabled`, `required`,
`aria-*` and listeners go on it as attributes. Its value is yours to control, or its own:

```gts
<Input @value={{this.email}} @onValueChange={{this.setEmail}} type="email" />
<Input @defaultValue="Ada" name="first-name" />
```

## Basic

<Example @name="input-basic" @title="Basic" />

## Field

Use `Field`, `FieldLabel`, and `FieldDescription` to create an input with a label and
description. Upstream's example comes with Field.

## Field Group

Use `FieldGroup` to show multiple `Field` blocks and to build forms. Upstream's example comes
with Field.

## Disabled

Use the `disabled` attribute to disable the input. To style the disabled state, add the
`data-disabled` attribute to the `Field` component. Upstream's example, in a Field, comes with
Field.

```gts
<Input type="email" placeholder="Email" disabled />
```

## Invalid

Use the `aria-invalid` attribute to mark the input as invalid. To style the invalid state, add
the `data-invalid` attribute to the `Field` component. Upstream's example, in a Field, comes
with Field.

```gts
<Input placeholder="Error" aria-invalid="true" />
```

Give it the value `"true"`: React renders upstream's bare `aria-invalid` as `"true"`, but in a
template a bare `aria-invalid` is empty, which ARIA reads as false.

## File

Use `type="file"` to create a file input. Upstream's example, in a Field, comes with Field.

```gts
<Input id="picture" type="file" />
```

Listen for the files with `{{on "change"}}` and read `event.target.files`; `@onValueChange`
hears the browser's `C:\fakepath\…` string, and `@value` can only clear a file input.

## Inline

Use `Field` with `orientation="horizontal"` to create an inline input. Pair with
[`Button`](/components/button.md) to create a search input with a button. Upstream's example
comes with Field.

## Grid

Use a grid layout to place multiple inputs side by side. Upstream's example, two Fields in a
`FieldGroup`, comes with Field.

## Required

Use the `required` attribute to indicate required inputs. Upstream's example, in a Field, comes
with Field.

```gts
<Input placeholder="This field is required" required />
```

## Badge

Use [`Badge`](/components/badge.md) in the label to highlight a recommended field. Upstream's
example comes with Field.

## Input Group

To add icons, text, or buttons inside an input, use the `InputGroup` component. See the
[Input Group](/components/input-group.md) component for more examples. Upstream's example, in a
Field, comes with Field.

## Button Group

To add buttons to an input, use the `ButtonGroup` component. See the Button Group component
for more examples. Upstream's example comes with Field and Button Group.

## Form

A full form example with multiple inputs, a select, and a button. Upstream's example comes with
Field and Select.

## RTL

Joinery's styles use logical properties, so an input lays itself out right to left inside any
element with `dir="rtl"` (see [Direction](/primitives/direction.md)). Upstream's right-to-left
example, in a Field, comes with Field.

## Controlled

Joinery's own section: upstream's Input is a plain `<input>`, so it leaves the value to React.
Joinery's takes Radix's pattern. Pass `@value` and `@onValueChange` to own the value: the input
shows `@value`, tells you each change, and shows whatever you pass back, so you can change a
value as it's typed, or refuse it. Here the username is kept lower case, without spaces:

<Example @name="input-controlled" @title="Controlled" />

```gts
import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { Input } from '@ember-joinery/ember'

export default class Username extends Component {
  @tracked username = 'ada'

  setUsername = (value: string) => (this.username = value.toLowerCase().replace(/\s+/g, ''))

  <template>
    <Input @value={{this.username}} @onValueChange={{this.setUsername}} aria-label="Username" />
  </template>
}
```

Leave `@value` out and the input keeps its own value, starting from `@defaultValue`;
`@onValueChange` still hears each change. Either way, a form reset puts back the value it
started with, and tells `@onValueChange`. The behaviour is the
[Native Value](/primitives/native-value.md) primitive, which works on any input of your own.

## API Reference

### Input

| Argument         | Type                      | Default | What it does                                                                              |
| ---------------- | ------------------------- | ------- | ----------------------------------------------------------------------------------------- |
| `@value`         | `string`                  |         | The value, when you control it: the input shows it, and a change goes to `@onValueChange` |
| `@onValueChange` | `(value: string) => void` |         | Called with each new value (on `input`), controlled or not                                |
| `@defaultValue`  | `string`                  |         | The value it starts with when you don't control it                                        |
| `@name`          | `string`                  |         | Its name, for `InputHarness` (`data-test-jn-name`); the form field's is `name`            |

It yields nothing, and takes attributes on its `<input>`: `type` (unset, so `text`, as
upstream's), `placeholder`, `name`, `disabled`, `readonly`, `required`, `aria-invalid` and the
rest.

### The `asInput` modifier

`{{asInput name=…}}` makes an `<input>` of your own look like Joinery's, such as one another
library renders: it adds the class and attributes below, and keeps them current.
`inputClasses()` and `inputAttributes(options)` return the same, for code of your own. It
leaves the value to the element; add [`{{nativeValue}}`](/primitives/native-value.md) for
`@value`'s behaviour.

```gts
import { asInput } from '@ember-joinery/ember'

<template><MaskedInput {{asInput name="phone"}} /></template>
```

### Data attributes

| Attribute           | Value       |
| ------------------- | ----------- |
| `class`             | `jn-input`  |
| `data-slot`         | `input`     |
| `data-test-jn`      | `input`     |
| `data-test-jn-name` | its `@name` |

## Keyboard interactions

| Key    | What it does                          |
| ------ | ------------------------------------- |
| `Tab`  | Moves focus to the input, and past it |
| Typing | Edits its value, as any native input  |

It's a native `<input>`, so the browser handles editing, selection and the rest. A disabled
input leaves the tab order.

## Accessibility

- Name it with a `<label for>` (or a Field, once it lands), `aria-label` or `aria-labelledby`.
  A placeholder alone is a weak name: it disappears as soon as someone types.
- Mark an error with `aria-invalid="true"`, and point `aria-describedby` at the message;
  `InputHarness` reads both.
- `disabled` takes it out of the tab order and dims it; `readonly` keeps it focusable.

## Testing

`InputHarness` from `@ember-joinery/test-support` drives an `<Input>`, or any `<input>` with
the `asInput` modifier:

```ts
import { InputHarness } from '@ember-joinery/test-support'

const email = new InputHarness('email') // <Input @name="email">
await email.fillIn('ada@example.com')
assert.strictEqual(email.value, 'ada@example.com')
assert.strictEqual(email.label, 'Email')
```

| Member               | What it is                                                                                     |
| -------------------- | ---------------------------------------------------------------------------------------------- |
| `control`            | The `<input>`                                                                                  |
| `value`              | What it holds now                                                                              |
| `type`               | Its `type`: `text`, `email`, `file`…                                                           |
| `placeholder`        | Its `placeholder`                                                                              |
| `label`              | Its accessible name: `aria-labelledby`'s text, `aria-label`, its label, `title` or placeholder |
| `description`        | The text its `aria-describedby` names                                                          |
| `isDisabled`         | Whether it is `disabled`                                                                       |
| `isReadOnly`         | Whether it is `readonly`                                                                       |
| `isRequired`         | Whether it is `required`                                                                       |
| `isInvalid`          | `aria-invalid`, other than `false` or empty                                                    |
| `isFocused`          | Whether it has focus                                                                           |
| `fileNames`          | For a file input, the names of the files chosen                                                |
| `fillIn(text)`       | Replaces what it holds, as pasting does                                                        |
| `typeIn(text)`       | Types after what it holds, one key at a time                                                   |
| `clear()`            | Empties it                                                                                     |
| `chooseFiles(files)` | For a file input, chooses files, as the file picker does                                       |
| `focus()`, `blur()`  | Moves focus to it, or away                                                                     |

## Upstream

shadcn/ui's [Input](https://ui.shadcn.com/docs/components/radix/input), from
`apps/v4/registry/bases/radix/ui/input.tsx` at shadcn-ui/ui@8ab2771, in the Nova style.
