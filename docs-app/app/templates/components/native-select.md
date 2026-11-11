# Native Select

A styled native HTML select element with consistent design system integration.

For a styled select component, see the Select component, which comes with the menus.

<Example @name="native-select-demo" @title="Native Select" />

## Installation

```bash
pnpm add @ember-joinery/ember lucide
```

Import Joinery's CSS once (see [Installation](/getting-started/installation.md)), then the
component where you use it:

```gts
import { NativeSelect } from '@ember-joinery/ember'
```

## Usage

`NativeSelect` yields its parts, `Option` and `OptGroup` (upstream's `NativeSelectOption` and
`NativeSelectOptGroup`):

```gts
<NativeSelect aria-label="Fruit" as |s|>
  <s.Option @value="">Select a fruit</s.Option>
  <s.Option @value="apple">Apple</s.Option>
  <s.Option @value="banana">Banana</s.Option>
  <s.Option @value="blueberry">Blueberry</s.Option>
  <s.Option @value="pineapple">Pineapple</s.Option>
</NativeSelect>
```

Its value is yours to control, or its own:

```gts
<NativeSelect @value={{this.fruit}} @onValueChange={{this.setFruit}} as |s|>…</NativeSelect>
<NativeSelect @defaultValue="apple" name="fruit" as |s|>…</NativeSelect>
```

## Composition

### Simple

Options placed directly under `NativeSelect` (no `OptGroup`).

```text
NativeSelect
├── Option
├── Option
├── Option
└── Option
```

### With groups

Use `OptGroup` to organize options into categories.

```text
NativeSelect
├── OptGroup
│   ├── Option
│   └── Option
└── OptGroup
    ├── Option
    └── Option
```

## Groups

Use `OptGroup` to organize options into categories.

<Example @name="native-select-groups" @title="Groups" />

## Disabled

Add the `disabled` attribute to the `NativeSelect` component to disable the select.

<Example @name="native-select-disabled" @title="Disabled" />

## Invalid

Use `aria-invalid="true"` to show validation errors, and `@invalid={{true}}` on the
[Field](/components/field.md) component (upstream's `data-invalid`) for styling. In a template a bare
`aria-invalid` is empty, which ARIA reads as false, so give it the value.

<Example @name="native-select-invalid" @title="Invalid" />

## Native Select vs Select

- Use `NativeSelect` for native browser behavior, better performance, or mobile-optimized
  dropdowns.
- Use `Select` for custom styling, animations, or complex interactions.

## RTL

Joinery's styles use logical properties, so a native select lays itself out right to left
inside any element with `dir="rtl"` (see [Direction](/primitives/direction.md)): the chevron,
and the room for it, move to the left.

<Example @name="native-select-rtl" @title="RTL" @dir="rtl" />

## Controlled

Joinery's own section. Pass `@value` and `@onValueChange` to own the value: the select shows
`@value`, tells you each choice, and shows whatever you pass back. Here a button sets it too:

<Example @name="native-select-controlled" @title="Controlled" />

Leave `@value` out and the select keeps its own value, starting from `@defaultValue` (or, with
neither, its first option, or the one you mark `selected`); `@onValueChange` still hears each
choice. A form reset puts back the value it started with, and tells `@onValueChange`. When its
options change (an `{{#each}}`, data that loads later), it shows its value again. The behaviour
is the [Native Value](/primitives/native-value.md) primitive.

## Size

Joinery's own example: upstream's `size="sm"` is `@size="sm"`, rendered as `data-size`.

<Example @name="native-select-size" @title="Size" />

## Icon

Joinery's own example. Upstream's Native Select is copied into your app, so you change its
chevron by editing it. Joinery's comes from the package, so give it the icon with `@icon`: any
`lucide` icon, imported one at a time.

<Example @name="native-select-icon" @title="Icon" />

## API Reference

### NativeSelect

The main select component that wraps the native HTML select element.

| Argument         | Type                      | Default       | What it does                                                                          |
| ---------------- | ------------------------- | ------------- | ------------------------------------------------------------------------------------- |
| `@value`         | `string`                  |               | The value, when you control it: it shows it, and a choice goes to `@onValueChange`    |
| `@onValueChange` | `(value: string) => void` |               | Called with each new value (on `input`), controlled or not                            |
| `@defaultValue`  | `string`                  |               | The value it starts with when you don't control it                                    |
| `@size`          | `"default" \| "sm"`       | `"default"`   | How tall it is                                                                        |
| `@icon`          | a `lucide` icon           | `ChevronDown` | The icon at its end                                                                   |
| `@name`          | `string`                  |               | Its name, for `NativeSelectHarness` (`data-test-jn-name`); the form field's is `name` |

Attributes go on the `<select>`: `id`, `name`, `disabled`, `required`, `aria-invalid`,
listeners, and `class` too. Upstream puts its `className` on the wrapper instead, but an Ember
component has one `...attributes`. A fixed width on the select (`class="w-[140px]"`) sizes the
wrapper too, which fits it; a percentage (`w-full`) doesn't, so for a select as wide as its
container, give the wrapper the width in your own CSS
(`[data-slot="native-select-wrapper"] { width: 100%; }`).

It yields its parts, each as a component and as a modifier for an element of your own:

| Part       | What it is                                                                 |
| ---------- | -------------------------------------------------------------------------- |
| `Option`   | An option (`<option>`): `@value` is its value; `disabled` goes on it       |
| `OptGroup` | A group of options (`<optgroup>`): give it its `label`, and `disabled`     |
| `option`   | `<option value="x" {{s.option value="x"}}>`: your own `<option>` an option |
| `optGroup` | `<optgroup {{s.optGroup}}>`: your own `<optgroup>` a group                 |

### Data attributes

| Element  | Attribute                                 | Value                                                 |
| -------- | ----------------------------------------- | ----------------------------------------------------- |
| wrapper  | `class`                                   | `jn-native-select-wrapper`, and `group/native-select` |
| wrapper  | `data-slot`                               | `native-select-wrapper`                               |
| wrapper  | `data-size`                               | its `@size`                                           |
| wrapper  | `data-test-jn`                            | `native-select`                                       |
| wrapper  | `data-test-jn-name`                       | its `@name`                                           |
| select   | `class`                                   | `jn-native-select`                                    |
| select   | `data-slot`                               | `native-select`                                       |
| select   | `data-size`                               | its `@size`                                           |
| select   | `data-test-jn-part`                       | `select`                                              |
| icon     | `class`                                   | `jn-native-select-icon` and `jn-size-own` (see below) |
| icon     | `data-slot`                               | `native-select-icon`                                  |
| icon     | `data-test-jn-part`                       | `icon`                                                |
| option   | `class`, `data-slot`                      | `jn-native-select-option`, `native-select-option`     |
| option   | `data-test-jn-part`, `data-test-jn-value` | `option`, its `@value`                                |
| optgroup | `class`, `data-slot`                      | `jn-native-select-optgroup`, `native-select-optgroup` |
| optgroup | `data-test-jn-part`                       | `group`                                               |

`jn-size-own` styles nothing. Upstream's icon carries its style rule's `size-4` after the
registry build, which the style sheets' `svg:not([class*='size-'])` rules look for, so an icon
size a container sets leaves the chevron at its own; the marker does the same.

## Keyboard interactions

It's the browser's own `<select>`, so the browser's keys work, as its menu does:

| Key                       | What it does                                       |
| ------------------------- | -------------------------------------------------- |
| `Tab`                     | Moves focus to the select, and past it             |
| `Space`, `Enter`, `Alt+↓` | Opens its menu (it varies by browser and platform) |
| `↑`, `↓`                  | Chooses the previous or next option                |
| Typing                    | Chooses the option that starts with what you type  |

## Accessibility

- Name it with a `<label for>` (or a [Field](/components/field.md)'s `FieldLabel`), `aria-label` or `aria-labelledby`.
  Upstream's examples leave theirs unnamed; Joinery's give each an `aria-label`, so the audit
  every example runs passes.
- The chevron is hidden from assistive technology, and a click on it reaches the select.
- Mark an error with `aria-invalid="true"`, and point `aria-describedby` at the message.

## Testing

`NativeSelectHarness` from `@ember-joinery/test-support` drives a `<NativeSelect>`. It chooses
an option as the browser's menu does (`input`, then `change`):

```ts
import { NativeSelectHarness } from '@ember-joinery/test-support'

const status = new NativeSelectHarness('status') // <NativeSelect @name="status">
await status.select('done')
assert.strictEqual(status.value, 'done')
assert.strictEqual(status.selectedText, 'Done')
```

| Member                    | What it is                                                                      |
| ------------------------- | ------------------------------------------------------------------------------- |
| `control`                 | The `<select>`                                                                  |
| `icon`                    | The icon at its end                                                             |
| `value`                   | The chosen option's value                                                       |
| `selectedText`            | The chosen option's text                                                        |
| `options`, `optionTexts`  | Every option's value, and its text, in order                                    |
| `groups`                  | Every group's `label`                                                           |
| `optionsIn(group)`        | The values of the options in a group                                            |
| `isOptionDisabled(value)` | Whether an option, or its group, is `disabled`                                  |
| `size`                    | Its `@size`                                                                     |
| `label`                   | Its accessible name: `aria-labelledby`'s text, `aria-label` or its label        |
| `description`             | The text its `aria-describedby` names                                           |
| `isDisabled`              | Whether it is `disabled`                                                        |
| `isRequired`              | Whether it is `required`                                                        |
| `isInvalid`               | `aria-invalid`, other than `false` or empty                                     |
| `isFocused`               | Whether it has focus                                                            |
| `select(value)`           | Chooses the option with that value; fails on a disabled select, as a user would |
| `focus()`, `blur()`       | Moves focus to it, or away                                                      |

## Upstream

shadcn/ui's [Native Select](https://ui.shadcn.com/docs/components/radix/native-select), from
`apps/v4/registry/bases/radix/ui/native-select.tsx` at shadcn-ui/ui@8ab2771, in the Nova style.
