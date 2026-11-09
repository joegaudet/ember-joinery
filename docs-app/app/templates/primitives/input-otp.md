# Input OTP

A one-time code field, as the [input-otp](https://input-otp.rodz.dev) library under shadcn's
Input OTP has it: one native `<input>`, invisible, laid over slots you render from the state it
yields. It covers ember-primitives' `OTP` too. It has no styles; the styled
[Input OTP](/components/input-otp.md) is built on it.

<Example @name="input-otp-headless" @title="A code field of your own" />

## Usage

```gts
import { InputOTP, REGEXP_ONLY_DIGITS } from '@ember-joinery/primitives/input-otp'

<template>
  <label for="code">Code</label>
  <InputOTP
    id="code"
    @maxLength={{6}}
    @pattern={{REGEXP_ONLY_DIGITS}}
    @onComplete={{this.verify}}
    @containerClass="my-slots"
    as |otp|
  >
    {{#each otp.slots as |slot|}}
      <otp.Slot @index={{slot.index}} class="my-slot" as |s|>
        {{s.char}}
        {{#if s.hasFakeCaret}}<span class="my-caret"></span>{{/if}}
      </otp.Slot>
    {{/each}}
  </InputOTP>
</template>
```

- **One input.** The code is in one `<input autocomplete="one-time-code" inputmode="numeric">`,
  laid over the slots with no colour of its own, so the browser types, deletes, pastes and
  autofills it, a form submits it under its `name`, and a screen reader hears one field. Its
  attributes are yours: `id`, `name`, `disabled`, `required`, `aria-*`, listeners.
- **The selection.** As input-otp does, it keeps the selection on one character: a caret
  inside the code selects the character after it (before it, moving back), so typing replaces
  it; a caret after the last character stays there, to add one. The slot it is on is active
  (`isActive`, and `data-active="true"` on `otp.Slot`), and an empty active slot is where to
  draw a caret (`hasFakeCaret`).
- **State.** Pass `@value` with `@onValueChange` to control the code, or start it with
  `@defaultValue`. `@onComplete` hears it when it becomes complete, whoever completed it. A
  form reset puts back the code it started with.
- **What it takes.** `@pattern` (a `RegExp` or its source: `REGEXP_ONLY_DIGITS`,
  `REGEXP_ONLY_CHARS`, `REGEXP_ONLY_DIGITS_AND_CHARS`) refuses any change that would leave a
  code it doesn't match, and sets the input's `pattern`, so a form checks it.
- **Paste and autofill.** Every paste goes in through `@pasteTransformer`, into the selection,
  cut to `@maxLength`, and refused whole if the pattern would refuse it; an `input` event
  follows. A browser's autofill of a code it was sent fills the input in one go, cut to length.
- **Its name.** With no `<label>`, `aria-label` or `aria-labelledby` when it renders, it names
  itself `@label` (`One-time password`).

## From ember-primitives

ember-primitives' `OTP` is a form around `OTPInput`, a fieldset of one input per character:
`<OTP @onSubmit={{this.verify}} @autoSubmit={{true}} as |o|><o.Input /><o.Submit /></OTP>`.
Joinery's is input-otp's single input, which every style sheet styles, and covers the same:

| ember-primitives                      | Joinery                                                                               |
| ------------------------------------- | ------------------------------------------------------------------------------------- |
| `@length` (default 6)                 | `@maxLength`                                                                          |
| `@onChange({ code, complete })`       | `@onValueChange(code)`, `@onComplete(code)`, and the yielded `isComplete`             |
| A field per character, from the block | A slot per character, from the yielded `slots`                                        |
| `@labelFn` (a label per field)        | `@label`, or your own `<label>`: there is one field                                   |
| Pasting splits the code across fields | Pasting fills the code from the selection, through `@pasteTransformer`                |
| Autofill into the first field         | Autofill into the one input                                                           |
| `<OTP @onSubmit>` with `{ code }`     | Your own `<form>`: the code submits under the input's `name`                          |
| `@autoSubmit`                         | `@autoSubmit` (`requestSubmit()` on the input's form)                                 |
| `o.Submit`, `o.Reset`                 | Your form's own `type="submit"` and `type="reset"` buttons; a reset restores the code |
| `disabled` on the fieldset            | `disabled` on the input                                                               |
| `fillOTP(code, selector?)`            | `fillOTP(code, within?)` from `@ember-joinery/test-support`                           |

## API

| Argument                       | Type                            | Default             | What it does                                                                                          |
| ------------------------------ | ------------------------------- | ------------------- | ----------------------------------------------------------------------------------------------------- |
| `@maxLength`                   | `number`                        |                     | How many characters the code has (required)                                                           |
| `@value`                       | `string`                        |                     | The code, controlled                                                                                  |
| `@defaultValue`                | `string`                        |                     | The first code, uncontrolled                                                                          |
| `@onValueChange`               | `(value) => void`               |                     | Called with each new code                                                                             |
| `@onComplete`                  | `(value) => void`               |                     | Called with the code when it becomes complete                                                         |
| `@pattern`                     | `string \| RegExp`              |                     | What the code may hold                                                                                |
| `@pasteTransformer`            | `(pasted) => string`            |                     | Turns pasted text into the code to insert                                                             |
| `@placeholder`                 | `string`                        |                     | A character per slot while it is empty (`aria-placeholder` too)                                       |
| `@autoSubmit`                  | `boolean`                       | `false`             | Submits the form when the code is complete                                                            |
| `@label`                       | `string`                        | `One-time password` | Its name when nothing else names it                                                                   |
| `@textAlign`                   | `'left' \| 'center' \| 'right'` | `left`              | Where the input's invisible text sits                                                                 |
| `@pushPasswordManagerStrategy` | `'increase-width' \| 'none'`    | `increase-width`    | Lets the focused input reach 40px past the slots, where there is room, for a password manager's badge |
| `@containerClass`              | `string`                        |                     | Classes for the container                                                                             |
| `@name`                        | `string`                        |                     | Its name, for `InputOTPHarness` (`data-test-jn-name`)                                                 |

It yields `{ slots, Slot, value, isComplete, isFocused, isHovering }`. Each slot is
`{ index, char, placeholderChar, isActive, hasFakeCaret }`; `Slot` takes `@index`, renders a
`<div data-active>` with its character, or yields the slot to a block of yours. The container
carries `data-input-otp-container` and `data-test-jn="input-otp"`; the input,
`data-input-otp` and `data-test-jn-part="input"`; a slot, `data-test-jn-part="slot"` and its
index as `data-test-jn-value`. Its styles go through the CSSOM (and its few shared rules, for
the selection and autofill colours, into an adopted style sheet), so a strict Content Security
Policy allows them.

## Accessibility

One `<input>` holds the code, so assistive technology reads one field; the slots only show it.
Name it with a label, and mark an error with `aria-invalid="true"` and `aria-describedby` on it.

## Testing

```ts
import { InputOTPHarness } from '@ember-joinery/test-support'

const code = new InputOTPHarness()
await code.typeIn('12')
await code.paste('3456')
assert.true(code.isComplete)
```

The [Input OTP](/components/input-otp.md#testing) page lists its members.
