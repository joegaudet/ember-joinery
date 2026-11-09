# Input OTP

Accessible one-time password component with copy-paste functionality.

<Example @name="input-otp-demo" @title="Input OTP" />

## About

Upstream's Input OTP is built on [input-otp](https://github.com/guilhermerodz/input-otp) by
[@guilherme_rodz](https://twitter.com/guilherme_rodz). Joinery's is built on its own port of
it, the [Input OTP primitive](/primitives/input-otp.md), which also covers ember-primitives'
`OTP`: one native `<input>`, invisible, laid over the slots, so typing, deleting, paste, a
browser's autofill of a code it was sent, and forms all work as on any input.

## Installation

```bash
pnpm add @ember-joinery/ember
```

Import Joinery's CSS once (see [Installation](/getting-started/installation.md)), then the
component where you use it:

```gts
import { InputOTP } from '@ember-joinery/ember'
```

## Usage

```gts
<InputOTP @maxLength={{6}} as |otp|>
  <otp.Group>
    <otp.Slot @index={{0}} />
    <otp.Slot @index={{1}} />
    <otp.Slot @index={{2}} />
  </otp.Group>
  <otp.Separator />
  <otp.Group>
    <otp.Slot @index={{3}} />
    <otp.Slot @index={{4}} />
    <otp.Slot @index={{5}} />
  </otp.Group>
</InputOTP>
```

## Composition

Use the following composition to build an `InputOTP`:

```text
InputOTP
├── otp.Group
│   ├── otp.Slot
│   ├── otp.Slot
│   └── otp.Slot
├── otp.Separator
├── otp.Group
│   ├── otp.Slot
│   ├── otp.Slot
│   └── otp.Slot
├── otp.Separator
└── otp.Group
    ├── otp.Slot
    └── otp.Slot
```

## Pattern

Use the `@pattern` argument to define a custom pattern for the OTP input.

```gts
import { InputOTP, REGEXP_ONLY_DIGITS_AND_CHARS } from '@ember-joinery/ember'

<template>
  <InputOTP @maxLength={{6}} @pattern={{REGEXP_ONLY_DIGITS_AND_CHARS}} as |otp|>
    ...
  </InputOTP>
</template>
```

Upstream's example, digits only in a Field with a label, comes with Field. The
[Four Digits](#four-digits) and [Alphanumeric](#alphanumeric) examples below use patterns too.

## Separator

Use `otp.Separator` to add a separator between input groups.

<Example @name="input-otp-separator" @title="Separator" />

## Disabled

Use the `disabled` attribute to disable the input.

<Example @name="input-otp-disabled" @title="Disabled" />

## Controlled

Use the `@value` and `@onValueChange` arguments to control the input value.

<Example @name="input-otp-controlled" @title="Controlled" />

## Invalid

Use `aria-invalid="true"` on the slots to show an error state.

<Example @name="input-otp-invalid" @title="Invalid" />

## Four Digits

A common pattern for PIN codes. This uses the `@pattern={{REGEXP_ONLY_DIGITS}}` argument.

<Example @name="input-otp-four-digits" @title="Four Digits" />

## Alphanumeric

Use `REGEXP_ONLY_DIGITS_AND_CHARS` to accept both letters and numbers.

<Example @name="input-otp-alphanumeric" @title="Alphanumeric" />

## Form

Upstream's example, a "Verify your login" [Card](/components/card.md) with a resend
[Button](/components/button.md) and a verification code in a Field, comes with Field.

## RTL

Joinery's styles use logical properties, so the slots run right to left inside any element
with `dir="rtl"` (see [Direction](/primitives/direction.md)), and each group's rounded ends
follow. The arrow keys follow the slots: `ArrowLeft` selects the next character, on the left,
and `ArrowRight` the one before. input-otp leaves the arrows to the browser, which moves through
the code as the left-to-right run of digits it is, the wrong way across slots that run right
to left. Upstream's right-to-left example, in a Field with an Arabic label, comes with Field.

## API Reference

### InputOTP

| Argument                       | Type                            | Default             | What it does                                                                                |
| ------------------------------ | ------------------------------- | ------------------- | ------------------------------------------------------------------------------------------- |
| `@maxLength`                   | `number`                        |                     | How many characters the code has (required)                                                 |
| `@value`                       | `string`                        |                     | The code, when you control it: it shows it, and a change goes to `@onValueChange`           |
| `@defaultValue`                | `string`                        |                     | The code it starts with when you don't control it                                           |
| `@onValueChange`               | `(value: string) => void`       |                     | Called with each new code, controlled or not (upstream's `onChange`)                        |
| `@onComplete`                  | `(value: string) => void`       |                     | Called with the code when it becomes complete                                               |
| `@pattern`                     | `string \| RegExp`              |                     | What the code may hold: a change it doesn't match is refused                                |
| `@pasteTransformer`            | `(pasted: string) => string`    |                     | Turns pasted text into the code to insert (strip dashes, say)                               |
| `@placeholder`                 | `string`                        |                     | A character per slot while the code is empty, yielded as `slot.placeholderChar`             |
| `@autoSubmit`                  | `boolean`                       | `false`             | Submits its form as soon as the code is complete, as ember-primitives' does                 |
| `@label`                       | `string`                        | `One-time password` | Its name, when nothing else names it; given, it names it always                             |
| `@textAlign`                   | `'left' \| 'center' \| 'right'` | `left`              | Where the input's (invisible) text sits                                                     |
| `@pushPasswordManagerStrategy` | `'increase-width' \| 'none'`    | `increase-width`    | Lets the focused input reach 40px past the slots' inline end for a password manager's badge |
| `@containerClass`              | `string`                        |                     | Classes for the container around the slots (upstream's `containerClassName`)                |
| `@name`                        | `string`                        |                     | Its name, for `InputOTPHarness` (`data-test-jn-name`); the form field's is `name`           |

Its attributes go on its `<input>`, as upstream's props do: `id`, `name`, `disabled`,
`required`, `inputmode` (`numeric` unless you give another), `autocomplete`
(`one-time-code`), `aria-*` and listeners. `REGEXP_ONLY_DIGITS`, `REGEXP_ONLY_CHARS` and
`REGEXP_ONLY_DIGITS_AND_CHARS` come from `@ember-joinery/ember` too.

It yields `otp`:

| Member           | What it is                                                                                              |
| ---------------- | ------------------------------------------------------------------------------------------------------- |
| `otp.Group`      | A row of slots drawn as one field (`@as` for another tag)                                               |
| `otp.Slot`       | One character's box: `@index`, from 0 (`@as` for another tag). Mark an error with `aria-invalid="true"` |
| `otp.Separator`  | What goes between groups, a minus sign; `@icon` draws another lucide icon (`@as` for another tag)       |
| `otp.group`      | A modifier that makes your own element a group                                                          |
| `otp.separator`  | A modifier that makes your own element a separator (it draws its own content)                           |
| `otp.slots`      | Each slot's state: `index`, `char`, `placeholderChar`, `isActive`, `hasFakeCaret`                       |
| `otp.value`      | The code now                                                                                            |
| `otp.isComplete` | Whether it has all its characters                                                                       |
| `otp.isFocused`  | Whether it has focus                                                                                    |

### Data attributes

| Part      | `class`                  | `data-slot`           | Other                                                                       |
| --------- | ------------------------ | --------------------- | --------------------------------------------------------------------------- |
| Container | `jn-input-otp-container` |                       | `data-input-otp-container`, `data-test-jn="input-otp"`, `data-test-jn-name` |
| Input     | `jn-input-otp-input`     | `input-otp`           | `data-input-otp`, `data-test-jn-part="input"`                               |
| Group     | `jn-input-otp-group`     | `input-otp-group`     | `data-test-jn-part="group"`                                                 |
| Slot      | `jn-input-otp-slot`      | `input-otp-slot`      | `data-active`, `data-test-jn-part="slot"`, `data-test-jn-value` (its index) |
| Caret     | `jn-input-otp-caret`     |                       | `data-test-jn-part="caret"`, around a `jn-input-otp-caret-line`             |
| Separator | `jn-input-otp-separator` | `input-otp-separator` | `role="separator"`, `data-test-jn-part="separator"`                         |

The container isn't `jn-input-otp`: upstream gives that class to its container through
`containerClassName`, which its registry build never resolves, so on ui.shadcn.com the style
sheets' `.jn-input-otp` rule (Nova's `gap-2`) styles nothing. Joinery keeps it off to match.

## Keyboard interactions

It's one native text input, so the browser edits it; Joinery keeps the selection on one
character, as input-otp does.

| Key                       | What it does                                                                         |
| ------------------------- | ------------------------------------------------------------------------------------ |
| `Tab`                     | Moves focus to it (the last character selected, or the next empty slot), and past it |
| Typing                    | Replaces the selected character, or adds one, and moves to the next                  |
| `Backspace`               | Deletes the selected character, or the one before the caret                          |
| `Delete`                  | Deletes the selected character                                                       |
| `ArrowLeft`, `ArrowRight` | Select the character before or after; right to left, `ArrowLeft` selects the next    |
| `Home`, `End`             | Go to the first character, or after the last                                         |
| `Ctrl`+`V`, `⌘`+`V`       | Pastes into the selection, through `@pasteTransformer`, cut to `@maxLength`          |

A click puts the caret where it lands in the input's text, unless it focuses the input while
the code is complete: then the last character stays selected, as `Tab` selects it. input-otp's
styles squeeze that text into a sliver to hide it, so the caret goes to one end of the code
whichever slot the click is over: left to right, after it, selecting the last character or the
next empty slot, as on ui.shadcn.com. The arrow keys reach the others.

## Accessibility

- It is one `<input>` with `autocomplete="one-time-code"`, so a screen reader hears one field
  holding the code, and a phone offers the code it was just sent. The slots only show it.
- Name it with a `<label for>` on its `id`, `aria-label` or `aria-labelledby`. With none, it
  names itself `@label`, `One-time password` by default (upstream's examples leave it unnamed).
- `@pattern` sets the input's `pattern` too, so with `required` a form checks the code.
- Mark an error with `aria-invalid="true"`: on the slots, as upstream's example does, which
  rings them and their group, and on the input too (with `aria-describedby` for the message),
  so assistive technology hears it.

## Testing

`InputOTPHarness` from `@ember-joinery/test-support` drives an `<InputOTP>`, or the headless
one. It types, deletes and moves the caret the way a browser edits the input, and pastes and
autofills as a browser does. A click selects what Chromium does for a click at that point
(`caretPositionFromPoint`), so with a complete code, `clickSlot(2)` then `typeIn('7')` replaces
the last character, as it would for a user; `press` the arrow keys to reach another.
`fillOTP(code, within?)` is ember-primitives' helper:

```ts
import { InputOTPHarness, fillOTP } from '@ember-joinery/test-support'

const otp = new InputOTPHarness('verification') // <InputOTP @name="verification">
await otp.typeIn('123')
assert.deepEqual(otp.chars, ['1', '2', '3', '', '', ''])
assert.strictEqual(otp.activeIndex, 3)
await otp.paste('456')
assert.true(otp.isComplete)

await fillOTP('123456') // the only InputOTP in the test
```

| Member                                  | What it is                                                                              |
| --------------------------------------- | --------------------------------------------------------------------------------------- |
| `input`                                 | The `<input>` that holds the code                                                       |
| `value`, `maxLength`                    | The code, and how many characters it has                                                |
| `isComplete`                            | Whether it has them all                                                                 |
| `slots`, `slot(index)`                  | The slots, or one by its index                                                          |
| `chars`                                 | What each slot shows (`''` for an empty one)                                            |
| `activeIndexes`, `activeIndex`          | The slots the selection is on, or the first (`null` without focus)                      |
| `hasCaret(index)`                       | Whether that slot draws the caret                                                       |
| `groups`, `separators`                  | Its groups and separators                                                               |
| `label`, `description`                  | The input's accessible name, and what its `aria-describedby` names                      |
| `isDisabled`, `isRequired`, `isFocused` | Its state                                                                               |
| `isInvalid`                             | `aria-invalid` on the input or on any slot                                              |
| `typeIn(text)`                          | Types a key at a time into the selection                                                |
| `press(key)`                            | `Backspace`, `Delete`, `ArrowLeft`, `ArrowRight`, `Home` or `End`                       |
| `clickSlot(index)`                      | Clicks over that slot, and selects what the browser does (the end of the code, usually) |
| `paste(text)`                           | Pastes from the clipboard into the selection                                            |
| `autofill(code)`                        | Fills the whole code in at once, as a browser's autofill does                           |
| `fillIn(code)`, `clear()`               | Replaces the code, or empties it                                                        |
| `focus()`, `blur()`                     | Moves focus to it, or away                                                              |

## Upstream

shadcn/ui's [Input OTP](https://ui.shadcn.com/docs/components/radix/input-otp), from
`apps/v4/registry/bases/radix/ui/input-otp.tsx` at shadcn-ui/ui@8ab2771, in the Nova style, and
the [input-otp](https://input-otp.rodz.dev) library it wraps.
