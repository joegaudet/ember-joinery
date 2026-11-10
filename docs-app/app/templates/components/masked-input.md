# Masked Input

A text input that shapes what is typed into it as it is typed: a phone number, a postal code, a
price, a date or a time.

<div class="callout">

**An opt-in add-on.** Masked Input is in its own package, `@ember-joinery/maskito`, built on
[Maskito](https://maskito.dev). Nothing in Joinery's core packages imports it, so an app that
doesn't install it doesn't load Maskito.

</div>

shadcn/ui has no masked input, so this one is shadcn's [Input](/components/input.md) with a mask
on it: it renders the same `<input>`, with the same classes, and follows the style, base colour
and radius you pick, as Input does. Its sibling in the same package is
[Phone Input](/components/phone-input.md).

<Example @name="masked-input-demo" @title="Masked Input" />

## Installation

Masked Input is an add-on, so it comes in its own package, with Maskito's packages
(`@maskito/core`, `@maskito/kit` and `@maskito/phone`, and `libphonenumber-js` for phone numbers)
as its dependencies, so they need no install of their own:

```bash
pnpm add @ember-joinery/maskito @ember-joinery/ember
```

It ships no CSS of its own: Joinery's `joinery.css` (or any of its styles) styles it, as it does
every component. Import that once (see [Installation](/getting-started/installation.md)), then
the component where you use it:

```gts
import { MaskedInput, numberMask } from '@ember-joinery/maskito'
```

Each module is also a subpath of its own (`@ember-joinery/maskito/components/masked-input`,
`/maskito`, `/presets`), for a bundler that doesn't drop what an app leaves unused.

## Usage

```gts
const phoneMask = {
  mask: ['(', /\d/, /\d/, /\d/, ')', ' ', /\d/, /\d/, /\d/, '-', /\d/, /\d/, /\d/, /\d/],
}

<template>
  <MaskedInput @mask={{phoneMask}} @value={{this.phone}} @onValueChange={{this.setPhone}} />
</template>
```

`@mask` takes any [Maskito options](https://maskito.dev/core-concepts/overview): a `mask` of
fixed characters and patterns (as above), a regular expression, or a preset's. The mask shapes
what is typed, pasted, dropped and autofilled; a character it doesn't take is turned away, and
its fixed characters (the brackets, the space, the dash) go in as the digits reach them and are
stepped over by Backspace.

The value is the masked text, `(555) 123-4567`, controlled or not (`@value`, `@defaultValue`
and `@onValueChange`), as [Input](/components/input.md)'s is. A value you pass is shown masked,
so `5551234567` shows as `(555) 123-4567`; `@onValueChange` hears the masked text the next time
it changes. A new `@mask` replaces the mask, and none takes it off. Build the options once (a
constant, a getter with `@cached`, or a preset helper whose arguments don't change): the same
object keeps the same mask, its undo history and its caret.

## Presets

The package wraps `@maskito/kit`'s generators as presets, functions you can call in a template
with named arguments, and pairs each with what reads its text back:

| Preset                  | Masks                                                  | Reads back                                       |
| ----------------------- | ------------------------------------------------------ | ------------------------------------------------ |
| `numberMask(params)`    | A number: separators, decimals, `min`, `max`, a prefix | `parseNumber(text, params)`, `formatNumber(n)`   |
| `dateMask(params)`      | A date: `dd/mm/yyyy`, or `mode`, `separator`, `locale` | `parseDate(text, params)`, `formatDate(date)`    |
| `timeMask(params)`      | A time: `HH:MM`, or `mode` (`HH:MM:SS`, `HH:MM AA`…)   | `parseTime(text, params)` (ms), `formatTime(ms)` |
| `dateTimeMask(params)`  | A date and a time: `dd/mm/yyyy, HH:MM`                 |                                                  |
| `dateRangeMask(params)` | Two dates: `dd/mm/yyyy – dd/mm/yyyy`                   |                                                  |

Each takes the generator's own parameters (`maximumFractionDigits`, `thousandSeparator`,
`prefix`, `postfix`, `mode`, `min`, `max`, `locale`…), all of them optional. Without a mode or a
locale, dates are `dd/mm/yyyy` with slashes. Give the reader the same parameters as the preset,
so it reads the same separators.

```gts
<MaskedInput @mask={{numberMask maximumFractionDigits=2 thousandSeparator="," prefix="$"}} />
<MaskedInput @mask={{dateMask mode="mm/dd/yyyy"}} />
<MaskedInput @mask={{timeMask mode="HH:MM AA"}} />
```

<Example @name="masked-input-presets" @title="Presets" />

## Your own input

The `{{maskito}}` modifier masks an `<input>` or `<textarea>` of your own, such as an Input
Group's: give it the same options as `@mask`. Every `input` listener on the element, wherever
it is added, reads the masked text, and `maskText(text, options)` shows a value set from code
as the mask would.

```gts
import { maskito, maskText } from '@ember-joinery/maskito'

<input {{g.input}} {{maskito this.cardMask}} {{on "input" this.update}} />
```

<Example @name="masked-input-input-group" @title="In an Input Group" />

## RTL

Masked Input takes its direction from the page, as Input does: right to left inside any element
with `dir="rtl"` (see [Direction](/primitives/direction.md)). Its mask works the same either way.
A number, a date or a time keeps its digits in order; give an input `dir="ltr"` if what it holds
should read left to right whatever the page's direction, as [Phone Input](/components/phone-input.md)
does.

<Example @name="masked-input-rtl" @title="RTL" @dir="rtl" />

## API Reference

### MaskedInput

| Argument         | Type                      | Default | What it does                                                  |
| ---------------- | ------------------------- | ------- | ------------------------------------------------------------- |
| `@mask`          | `MaskitoOptions \| null`  |         | The mask: Maskito options, a preset's or your own             |
| `@value`         | `string`                  |         | The masked text, controlled; a value you pass is shown masked |
| `@defaultValue`  | `string`                  |         | The text it starts with, uncontrolled                         |
| `@onValueChange` | `(value: string) => void` |         | Called with the masked text whenever it changes               |
| `@name`          | `string`                  |         | Its name, for `MaskedInputHarness` (`data-test-jn-name`)      |

It renders a native `<input>`: give it `id`, `name`, `placeholder`, `inputmode`, `disabled`,
`aria-invalid` and listeners as attributes, `class` included.

### The modifier and the helpers

| Export                     | What it is                                                                     |
| -------------------------- | ------------------------------------------------------------------------------ |
| `{{maskito options}}`      | Masks an input or textarea of your own; `null` or `undefined` takes it off     |
| `maskText(text, options)`  | Text as the mask would shape it                                                |
| `numberMask`, `dateMask`…  | The presets above, each returning Maskito options                              |
| `parseNumber`, `parseDate` | Read a preset's text back; `formatNumber`, `formatDate`, `formatTime` write it |
| `MaskitoOptions`           | Maskito's options type                                                         |

### Data attributes

| Attribute           | Value                                 |
| ------------------- | ------------------------------------- |
| `class`             | `jn-input`, Input's                   |
| `data-slot`         | `input`, so the style sheets style it |
| `data-test-jn`      | `masked-input`                        |
| `data-test-jn-name` | `@name`                               |

## Keyboard interactions

A masked input is a text input: it is in the tab order, and every key works as it does in one.
The mask decides what a key puts in: a character it doesn't take does nothing, Backspace and
Delete step over its fixed characters, and Ctrl+Z and Ctrl+Shift+Z (⌘Z and ⇧⌘Z) undo and redo
the masked text.

## Accessibility

- It is a native `<input>`, named as any input is: by a `<FieldLabel for>`, `aria-label` or
  `aria-labelledby`. Say what the mask expects in the placeholder or a `FieldDescription`
  (`aria-describedby`), since a character turned away gives no message.
- Give it the `inputmode` its mask needs (`numeric`, `decimal`, `tel`), so a phone shows the
  right keyboard, and `autocomplete` where the browser can fill it in (`cc-number`, `bday`).
- Mark an error with `aria-invalid="true"`, as Input's: its ring turns destructive.

## Testing

`MaskedInputHarness`, from `@ember-joinery/maskito/test-support`, is an
[`InputHarness`](/components/input.md) (`value`, `label`, `description`, `isInvalid`,
`fillIn()`…) that also types the way a browser does, with the `beforeinput` events the mask
answers:

```ts
import { MaskedInputHarness } from '@ember-joinery/maskito/test-support'

const phone = new MaskedInputHarness('phone')
await phone.typeText('5551234567')
assert.strictEqual(phone.value, '(555) 123-4567')
await phone.backspace(5)
assert.strictEqual(phone.value, '(555) 12')
```

| Member                 | What it is                                                              |
| ---------------------- | ----------------------------------------------------------------------- |
| `typeText(text)`       | Types at the end, a character at a time, as a keyboard does             |
| `backspace(n)`         | Presses Backspace at the end, `n` times (default 1)                     |
| `deleteForward(at, n)` | Presses Delete `n` times with the caret at `at` (default 1)             |
| `paste(text)`          | Selects everything and pastes over it                                   |
| `drop(text)`           | Drops text at the end, as a drag and drop does                          |
| `undo()`, `redo()`     | Presses Ctrl+Z and Ctrl+Shift+Z                                         |
| `fillIn(text)`         | Replaces the text at once, as autofill does; the mask shapes the result |
| `value`, `label`…      | `InputHarness`'s                                                        |

## Built on

[Maskito](https://github.com/taiga-family/maskito) 5 (Apache 2.0): its core, `@maskito/core`,
which masks the element, and `@maskito/kit`'s number, date and time generators, which the
presets call. Formwright's `@ember-formwright/maskito` offers the same as its `masked` control;
this is the standalone component, for use without a form library. The first example on this
page ports Formwright's guide example for it.
