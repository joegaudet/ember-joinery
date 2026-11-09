# Textarea

Displays a form textarea or a component that looks like a textarea.

<Example @name="textarea-demo" @title="Textarea" />

## Installation

```bash
pnpm add @ember-joinery/ember
```

Import Joinery's CSS once (see [Installation](/getting-started/installation.md)), then the
component where you use it:

```gts
import { Textarea } from '@ember-joinery/ember'
```

## Usage

```gts
<Textarea />
```

It renders a native `<textarea>` that grows with its text (`field-sizing: content`, from 4rem
tall), so `placeholder`, `rows`, `name`, `disabled`, `aria-*` and listeners go on it as
attributes. Its value is yours to control, or its own:

```gts
<Textarea @value={{this.message}} @onValueChange={{this.setMessage}} />
<Textarea @defaultValue="Dear Ada," name="letter" />
```

## Field

Use `Field`, `FieldLabel`, and `FieldDescription` to create a textarea with a label and
description (see [Field](/components/field.md)).

<Example @name="textarea-field" @title="Field" />

## Disabled

Use the `disabled` attribute to disable the textarea. To style the disabled state, give the
`Field` component `@disabled={{true}}` (upstream's `data-disabled`).

<Example @name="textarea-disabled" @title="Disabled" />

## Invalid

Use the `aria-invalid` attribute to mark the textarea as invalid. To style the invalid state,
give the `Field` component `@invalid={{true}}` (upstream's `data-invalid`).

<Example @name="textarea-invalid" @title="Invalid" />

Give it the value `"true"`: React renders upstream's bare `aria-invalid` as `"true"`, but in a
template a bare `aria-invalid` is empty, which ARIA reads as false.

## Button

Pair with [`Button`](/components/button.md) to create a textarea with a submit button.

<Example @name="textarea-button" @title="Button" />

## RTL

Joinery's styles use logical properties, so a textarea lays itself out right to left inside
any element with `dir="rtl"` (see [Direction](/primitives/direction.md)).

<Example @name="textarea-rtl" @title="RTL" @dir="rtl" />

## Controlled

Joinery's own section: upstream's Textarea is a plain `<textarea>`, so it leaves the value to
React. Joinery's takes Radix's pattern. Pass `@value` and `@onValueChange` to own the value:
the textarea shows `@value`, tells you each change, and shows whatever you pass back. Here the
parent counts what's left and clears it:

<Example @name="textarea-controlled" @title="Controlled" />

Leave `@value` out and the textarea keeps its own value, starting from `@defaultValue`;
`@onValueChange` still hears each change. Either way, a form reset puts back the value it
started with, and tells `@onValueChange`. The behaviour is the
[Native Value](/primitives/native-value.md) primitive.

## API Reference

### Textarea

| Argument         | Type                      | Default | What it does                                                                       |
| ---------------- | ------------------------- | ------- | ---------------------------------------------------------------------------------- |
| `@value`         | `string`                  |         | The value, when you control it: it shows it, and a change goes to `@onValueChange` |
| `@onValueChange` | `(value: string) => void` |         | Called with each new value (on `input`), controlled or not                         |
| `@defaultValue`  | `string`                  |         | The value it starts with when you don't control it                                 |
| `@name`          | `string`                  |         | Its name, for `TextareaHarness` (`data-test-jn-name`); the form field's is `name`  |

It yields nothing, and takes attributes on its `<textarea>`.

### The `asTextarea` modifier

`{{asTextarea name=…}}` makes a `<textarea>` of your own look like Joinery's, such as one an
editor library renders: it adds the class and attributes below, and keeps them current.
`textareaClasses()` and `textareaAttributes(options)` return the same. It leaves the value to
the element; add [`{{nativeValue}}`](/primitives/native-value.md) for `@value`'s behaviour.

### Data attributes

| Attribute           | Value         |
| ------------------- | ------------- |
| `class`             | `jn-textarea` |
| `data-slot`         | `textarea`    |
| `data-test-jn`      | `textarea`    |
| `data-test-jn-name` | its `@name`   |

## Keyboard interactions

| Key    | What it does                             |
| ------ | ---------------------------------------- |
| `Tab`  | Moves focus to the textarea, and past it |
| Typing | Edits its value; `Enter` adds a line     |

It's a native `<textarea>`, so the browser handles editing and selection. A disabled textarea
leaves the tab order.

## Accessibility

- Name it with a `<label for>` (or a [Field](/components/field.md)'s `FieldLabel`), `aria-label` or `aria-labelledby`.
- Mark an error with `aria-invalid="true"`, and point `aria-describedby` at the message.

## Testing

`TextareaHarness` from `@ember-joinery/test-support` drives a `<Textarea>`, or any `<textarea>`
with the `asTextarea` modifier:

```ts
import { TextareaHarness } from '@ember-joinery/test-support'

const message = new TextareaHarness('message') // <Textarea @name="message">
await message.fillIn('Hello')
assert.strictEqual(message.value, 'Hello')
```

| Member              | What it is                                                                                     |
| ------------------- | ---------------------------------------------------------------------------------------------- |
| `control`           | The `<textarea>`                                                                               |
| `value`             | What it holds now                                                                              |
| `placeholder`       | Its `placeholder`                                                                              |
| `label`             | Its accessible name: `aria-labelledby`'s text, `aria-label`, its label, `title` or placeholder |
| `description`       | The text its `aria-describedby` names                                                          |
| `isDisabled`        | Whether it is `disabled`                                                                       |
| `isReadOnly`        | Whether it is `readonly`                                                                       |
| `isRequired`        | Whether it is `required`                                                                       |
| `isInvalid`         | `aria-invalid`, other than `false` or empty                                                    |
| `isFocused`         | Whether it has focus                                                                           |
| `fillIn(text)`      | Replaces what it holds, as pasting does                                                        |
| `typeIn(text)`      | Types after what it holds, one key at a time                                                   |
| `clear()`           | Empties it                                                                                     |
| `focus()`, `blur()` | Moves focus to it, or away                                                                     |

## Upstream

shadcn/ui's [Textarea](https://ui.shadcn.com/docs/components/radix/textarea), from
`apps/v4/registry/bases/radix/ui/textarea.tsx` at shadcn-ui/ui@8ab2771, in the Nova style.
