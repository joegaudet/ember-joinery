# Input Group

Add addons, buttons, and helper content to inputs.

<Example @name="input-group-demo" @title="Input Group" />

## Installation

```bash
pnpm add @ember-joinery/ember
```

Import Joinery's CSS once (see [Installation](/getting-started/installation.md)), then the
component where you use it:

```gts
import { InputGroup } from '@ember-joinery/ember'
```

## Usage

```gts
import { Search } from 'lucide'
import { Icon, InputGroup } from '@ember-joinery/ember'

<template>
  <InputGroup as |g|>
    <g.Input placeholder="Search..." />
    <g.Addon>
      <Icon @icon={{Search}} />
    </g.Addon>
  </InputGroup>
</template>
```

## Composition

Use the following composition to build an `InputGroup`:

```text
InputGroup
├── g.Input or g.Textarea
├── g.Addon
├── g.Button
└── g.Text
```

## Align

Use the `@align` argument on `g.Addon` to position the addon relative to the input.

For proper focus management, `g.Addon` should always be placed after `g.Input` or
`g.Textarea` in the DOM. Use the `@align` argument to visually position the addon.

### inline-start

Use `@align="inline-start"` to position the addon at the start of the input. This is the
default.

<Example @name="input-group-inline-start" @title="inline-start" />

### inline-end

Use `@align="inline-end"` to position the addon at the end of the input.

<Example @name="input-group-inline-end" @title="inline-end" />

### block-start

Use `@align="block-start"` to position the addon above the input.

<Example @name="input-group-block-start" @title="block-start" />

### block-end

Use `@align="block-end"` to position the addon below the input.

<Example @name="input-group-block-end" @title="block-end" />

## Icon

<Example @name="input-group-icon" @title="Icon" />

## Text

<Example @name="input-group-text" @title="Text" />

## Button

<Example @name="input-group-button" @title="Button" />

A group button is `g.Button`: ghost and `xs` by default, with `@variant` and `@size` (`xs`,
`sm`, `icon-xs`, `icon-sm`). To open a popover from an addon, as the second group does, give the
addon the popover's `trigger` modifier (`<g.Addon {{popover.trigger}}>`), as upstream's
`PopoverTrigger asChild` does: a click on the button inside it opens the popover.

## Kbd

<Example @name="input-group-kbd" @title="Kbd" />

## Dropdown

Upstream's example, a group button that opens a `DropdownMenu`, comes with Dropdown Menu.

## Spinner

<Example @name="input-group-spinner" @title="Spinner" />

## Textarea

<Example @name="input-group-textarea" @title="Textarea" />

## Custom Input

Add `{{g.control}}` (or the `data-slot="input-group-control"` attribute) to your custom input
for automatic focus state handling.

Here's an example of a custom textarea that grows with its text: upstream's is a third-party
library's, Joinery's a plain `<textarea>` with `field-sizing-content`.

<Example @name="input-group-custom" @title="Custom Input" />

## RTL

Joinery's styles use logical properties, so an input group lays itself out right to left
inside any element with `dir="rtl"` (see [Direction](/primitives/direction.md)): an
`inline-start` addon goes on the right, and its padding follows.

<Example @name="input-group-rtl" @title="RTL" @dir="rtl" />

## API Reference

### InputGroup

The main component that wraps inputs and addons. It yields its parts, `g`, and takes
attributes on its `role="group"` `<div>`.

| Argument | Type     | Default | What it does                                            |
| -------- | -------- | ------- | ------------------------------------------------------- |
| `@as`    | `string` | `div`   | The tag to render instead                               |
| `@name`  | `string` |         | Its name, for `InputGroupHarness` (`data-test-jn-name`) |

```gts
<InputGroup as |g|>
  <g.Input />
  <g.Addon />
</InputGroup>
```

### g.Addon

Displays icons, text, buttons, or other content alongside inputs. A press on it (anywhere but
on a button in it) focuses the group's input, as upstream's does.

For proper focus navigation, the addon should be placed after the input. Set the `@align`
argument to position the addon.

| Argument | Type                                                             | Default          |
| -------- | ---------------------------------------------------------------- | ---------------- |
| `@align` | `"inline-start" \| "inline-end" \| "block-start" \| "block-end"` | `"inline-start"` |
| `@as`    | `string`                                                         | `"div"`          |

```gts
<g.Addon @align="inline-end">
  <Icon @icon={{Search}} />
</g.Addon>
```

**For `g.Input`, use the `inline-start` or `inline-end` alignment. For `g.Textarea`, use the
`block-start` or `block-end` alignment.**

An addon can have several `g.Button`s and icons.

```gts
<g.Addon>
  <g.Button>Button</g.Button>
  <g.Button>Button</g.Button>
</g.Addon>
```

### g.Button

Displays buttons within input groups: Joinery's [Button](/components/button.md) at its default
size, with the group's own size classes and `type="button"` (give another `type` to submit).

| Argument   | Type                                                                          | Default    |
| ---------- | ----------------------------------------------------------------------------- | ---------- |
| `@size`    | `"xs" \| "icon-xs" \| "sm" \| "icon-sm"`                                      | `"xs"`     |
| `@variant` | `"default" \| "destructive" \| "outline" \| "secondary" \| "ghost" \| "link"` | `"ghost"`  |
| `@name`    | `string`                                                                      |            |
| `@as`      | `string`, such as `"a"` for a link (which then has no `type`)                 | `"button"` |

```gts
<g.Button>Button</g.Button>
<g.Button @size="icon-xs" aria-label="Copy">
  <Icon @icon={{Copy}} />
</g.Button>
```

### g.Input

Replacement for `<Input />` when building input groups: Joinery's
[Input](/components/input.md), with the input group styles pre-applied and the unified
`data-slot="input-group-control"` for focus state handling. It takes Input's arguments
(`@value`, `@defaultValue`, `@onValueChange`, `@name`) and attributes.

```gts
<InputGroup as |g|>
  <g.Input placeholder="Enter text..." />
  <g.Addon>
    <Icon @icon={{Search}} />
  </g.Addon>
</InputGroup>
```

### g.Textarea

Replacement for `<Textarea />` when building input groups: Joinery's
[Textarea](/components/textarea.md), with the textarea group styles pre-applied and the unified
`data-slot="input-group-control"` for focus state handling. It takes Textarea's arguments and
attributes.

```gts
<InputGroup as |g|>
  <g.Textarea placeholder="Enter message..." />
  <g.Addon @align="block-end">
    <g.Button>Send</g.Button>
  </g.Addon>
</InputGroup>
```

### g.Text

Text beside the control, in a `<span>` (or `@as`): a prefix (`https://`), a unit (`USD`) or a
count.

### The modifiers

Each part is also a modifier, for an element or component of your own, which adds the part's
classes and attributes, as upstream's `asChild` does: `{{g.input}}` and `{{g.textarea}}` (each
with `name=`), `{{g.addon align=…}}`, `{{g.button variant=… size=… name=…}}`, `{{g.text}}`, and
`{{g.control}}`, which adds only `data-slot="input-group-control"`, for a control you style
yourself. `inputGroupAddonClasses()`, `inputGroupAddonAttributes()`,
`inputGroupButtonClasses()` and `inputGroupButtonAttributes()` return the same, for code of
your own.

```gts
<InputGroup as |g|>
  <MaskedInput {{g.input name="phone"}} />
  <span {{g.addon align="inline-start"}}>+1</span>
</InputGroup>
```

### Data attributes

| Part     | `class`                                                                 | `data-slot`           | Other                                                                      |
| -------- | ----------------------------------------------------------------------- | --------------------- | -------------------------------------------------------------------------- |
| Group    | `jn-input-group group/input-group`                                      | `input-group`         | `role="group"`, `data-test-jn="input-group"`, `data-test-jn-name`          |
| Input    | `jn-input jn-input-group-input`                                         | `input-group-control` | Input's `data-test-jn="input"`                                             |
| Textarea | `jn-textarea jn-input-group-textarea`                                   | `input-group-control` | Textarea's `data-test-jn="textarea"`                                       |
| Addon    | `jn-input-group-addon jn-input-group-addon-align-<align>`               | `input-group-addon`   | `role="group"`, `data-align`, `data-test-jn-part="addon"`                  |
| Button   | Button's, and `jn-input-group-button jn-input-group-button-size-<size>` | `button`              | `data-size` (the group's size), Button's `data-variant` and `data-test-jn` |
| Text     | `jn-input-group-text`                                                   |                       | `data-test-jn-part="text"`                                                 |

Put `data-disabled="true"` on the group to dim its addons with a disabled control, as
upstream's rules look for.

## Keyboard interactions

| Key   | What it does                                                               |
| ----- | -------------------------------------------------------------------------- |
| `Tab` | Moves focus to the control, then through the addons' buttons, in DOM order |

The control is a native input or textarea, so the browser handles editing. That's why the
addons go after it in the DOM: `@align` places them, and focus follows the DOM.

## Accessibility

- The group and each addon are `role="group"`, as upstream's. Name the control as you would
  an Input: a `<label for>`, `aria-label` or `aria-labelledby` (a placeholder alone is weak).
- Name an icon-only `g.Button` with `aria-label` (or a `sr-only` span inside it).
- Mark an error with `aria-invalid="true"` on the control: the whole group takes the
  destructive border and ring, and the control's own ring stays off.

## Testing

`InputGroupHarness` from `@ember-joinery/test-support` drives an `<InputGroup>`: its control,
its addons and their text. Reach its buttons with `find()` or `@child`:

```ts
import { ButtonHarness, InputGroupHarness } from '@ember-joinery/test-support'

const search = new InputGroupHarness('search') // <InputGroup @name="search">
await search.fillIn('shadcn')
assert.strictEqual(search.addonText('inline-end'), '12 results')
await search.find(ButtonHarness, 'copy').click()
```

| Member                                 | What it is                                                           |
| -------------------------------------- | -------------------------------------------------------------------- |
| `control`                              | The control: its input, its textarea, or one of your own             |
| `value`, `placeholder`                 | What the control holds, and its placeholder                          |
| `label`, `description`                 | The control's accessible name, and what its `aria-describedby` names |
| `isDisabled`, `isInvalid`, `isFocused` | The control's state                                                  |
| `addons`, `addon(align?)`              | The addons, or the first at `align`                                  |
| `aligns`                               | Each addon's `@align`, in DOM order                                  |
| `addonText(align?)`, `texts`           | An addon's text, and each `g.Text`'s                                 |
| `icons`                                | The icons it shows                                                   |
| `clickAddon(align?)`                   | Clicks an addon, which focuses the input                             |
| `fillIn(text)`, `typeIn(text)`         | Replaces what the control holds, or types after it                   |
| `focus()`, `blur()`                    | Moves focus to the control, or away                                  |

## Changelog

### 2025-10-06 `InputGroup`

Upstream's changelog adds the `min-w-0` class to the `InputGroup` component (see the
[diff](https://github.com/shadcn-ui/ui/pull/8341/files#diff-0e2ee95d0050ca4c5d82339df86c54e14a6739dc4638fdda0eec8f73aebc2da9)),
so the group can shrink below its content's width in a flex row. Joinery's has had it from the
start: it is in the group's own rule, `.jn-input-group`.

## Upstream

shadcn/ui's [Input Group](https://ui.shadcn.com/docs/components/radix/input-group), from
`apps/v4/registry/bases/radix/ui/input-group.tsx` at shadcn-ui/ui@8ab2771, in the Nova style.
