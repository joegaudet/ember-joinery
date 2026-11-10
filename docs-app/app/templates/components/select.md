# Select

Displays a list of options for the user to pick from—triggered by a button.

<Example @name="select-demo" @title="Select" />

## Installation

```bash
pnpm add @ember-joinery/ember
```

Import Joinery's CSS once (see [Installation](/getting-started/installation.md)), then the
component where you use it:

```gts
import { Select } from '@ember-joinery/ember'
```

## Usage

`<Select>` yields its parts:

```gts
import { Select } from '@ember-joinery/ember'

<template>
  <Select as |s|>
    <s.Trigger class="w-[180px]" aria-label="Theme">
      <s.Value @placeholder="Theme" />
    </s.Trigger>
    <s.Content>
      <s.Group>
        <s.Item @value="light">Light</s.Item>
        <s.Item @value="dark">Dark</s.Item>
        <s.Item @value="system">System</s.Item>
      </s.Group>
    </s.Content>
  </Select>
</template>
```

Its value is its own, or yours: pass `@value` with `@onValueChange` to control it, or
`@defaultValue` to start with one. `@open`, `@defaultOpen` and `@onOpenChange` do the same for
whether it is open. Name the trigger, with `aria-label` or a `<Label for>` and the trigger's
`id`: it is a `combobox`, which its text doesn't name.

## Composition

Use the following composition to build a `Select`:

```text
Select
├── s.Trigger
│   └── s.Value
└── s.Content
    ├── s.Group
    │   ├── s.Label
    │   ├── s.Item
    │   └── s.Item
    ├── s.Separator
    └── s.Group
        ├── s.Label
        ├── s.Item
        └── s.Item
```

## Align Item With Trigger

Use `@position` on `s.Content` to control alignment. When `@position="item-aligned"` (default),
the popup positions so the selected item appears over the trigger. When `@position="popper"`,
the popup aligns to the trigger edge.

Upstream's example, `select-align-item`, toggles between the two with a Switch in a Field, so it
comes with Field. Both positions are tested in Joinery's own suite.

## Groups

Use `s.Group`, `s.Label`, and `s.Separator` to organize items.

<Example @name="select-groups" @title="Groups" />

## Scrollable

A select with many items that scrolls.

<Example @name="select-scrollable" @title="Scrollable" />

## Disabled

<Example @name="select-disabled" @title="Disabled" />

## Invalid

Add the `data-invalid` attribute to the `Field` component and the `aria-invalid` attribute to
`s.Trigger` to show an error state.

```gts
<Field data-invalid>
  <FieldLabel>Fruit</FieldLabel>
  <s.Trigger aria-invalid="true">
    <s.Value />
  </s.Trigger>
</Field>
```

Upstream's example, `select-invalid`, is a Field, so it comes with Field.

## RTL

Joinery's components take their direction from the nearest `dir` (see
[Direction](/primitives/direction.md)): the item-aligned list lines the chosen option's text up
with the value at the right, and the check marks move to the left.

<Example @name="select-rtl" @title="RTL" @dir="rtl" />

## API Reference

### Select

| Argument         | Type                      | Default | What it does                                                    |
| ---------------- | ------------------------- | ------- | --------------------------------------------------------------- |
| `@value`         | `string`                  |         | The chosen option's value, controlled (`''` for none)           |
| `@defaultValue`  | `string`                  |         | The value to start with, uncontrolled                           |
| `@onValueChange` | `(value: string) => void` |         | Called with each value the user chooses                         |
| `@open`          | `boolean`                 |         | Whether it is open, controlled                                  |
| `@defaultOpen`   | `boolean`                 | `false` | Whether it starts open                                          |
| `@onOpenChange`  | `(open: boolean) => void` |         | Called with each state the user asks for                        |
| `@disabled`      | `boolean`                 | `false` | Disables the trigger                                            |
| `@required`      | `boolean`                 | `false` | `aria-required` on the trigger, `required` on the hidden select |
| `@formName`      | `string`                  |         | The form field's name: a hidden `<select>` carries the value    |
| `@form`          | `string`                  |         | The id of the form the hidden `<select>` belongs to             |
| `@autoComplete`  | `string`                  |         | The hidden `<select>`'s `autocomplete`, for autofill            |
| `@dir`           | `"ltr" \| "rtl"`          |         | The direction, when it isn't the page's                         |
| `@name`          | `string`                  |         | Its name, for `SelectHarness` (`data-test-jn-name`)             |

It renders an element with `display: contents` and yields `{ Trigger, Value, Content, Item,
Group, Label, Separator, Arrow, trigger, value, isOpen, setOpen, setValue }`. Radix's `name` is
`@formName`, as on Joinery's other controls: `@name` names it for its harness.

### s.Trigger and s.Value

`s.Trigger` is the `<button>` (`role="combobox"`) that opens it: `@size` is `default` (32px tall)
or `sm` (28px), and `@icon` replaces its chevron. `s.Value` shows the chosen option's text, or
`@placeholder` while nothing is chosen; a block of its own shows that instead.

### s.Content

| Argument                                    | Type                                     | Default          | What it does                                     |
| ------------------------------------------- | ---------------------------------------- | ---------------- | ------------------------------------------------ |
| `@position`                                 | `"item-aligned" \| "popper"`             | `"item-aligned"` | Over the trigger, or anchored to it              |
| `@side`                                     | `"top" \| "right" \| "bottom" \| "left"` | `"bottom"`       | With `popper`: the side of the trigger           |
| `@align`                                    | `"start" \| "center" \| "end"`           | `"center"`       | With `popper`: where along that side             |
| `@sideOffset`, `@alignOffset`               | `number`                                 | `0`              | With `popper`: offsets, in pixels                |
| `@avoidCollisions`, `@collisionPadding`     |                                          | `true`, `10`     | With `popper`: flip and shift to stay in view    |
| `@onCloseAutoFocus`                         | `(event) => void`                        |                  | Before focus goes back; `preventDefault()` stops |
| `@onEscapeKeyDown`, `@onPointerDownOutside` | `(event) => void`                        |                  | `preventDefault()` keeps it open                 |

It holds the scroll buttons and the viewport around your options, as upstream's does.

### s.Item, s.Group, s.Label, s.Separator

`s.Item` takes `@value` (not `''`), `@disabled`, `@textValue` (what typeahead matches, when its
text isn't plain) and `@icon` (its check mark); its block is the option's text, which the value
shows when it is chosen. `s.Group` is a `role="group"`, named by the `s.Label` inside it.
`s.Separator` is hidden from assistive technology.

### Data attributes

| Part    | Attributes                                                                                                                                                                              |
| ------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| root    | `data-test-jn="select"`, `data-test-jn-name`, `data-test-jn-value` (the value)                                                                                                          |
| trigger | `class="jn-select-trigger"`, `data-slot="select-trigger"`, `data-size`, `role="combobox"`, `aria-expanded`, `data-state`, `data-placeholder`, `data-test-jn-part="trigger"`             |
| content | `class="jn-select-content"`, `data-slot="select-content"`, `role="listbox"`, `data-state`, `data-align-trigger`, `data-side`, `data-test-jn-part="content"`, `data-test-jn-owner`       |
| item    | `class="jn-select-item"`, `data-slot="select-item"`, `role="option"`, `data-state` (`checked`), `data-highlighted`, `data-disabled`, `data-test-jn-part="option"`, `data-test-jn-value` |
| group   | `class="jn-select-group"`, `data-slot="select-group"`, `role="group"`, `aria-labelledby`                                                                                                |

## Keyboard interactions

| Key                                      | What it does                                                                      |
| ---------------------------------------- | --------------------------------------------------------------------------------- |
| `Space`, `Enter`, `ArrowDown`, `ArrowUp` | On the trigger, opens it, on the chosen option (or the first)                     |
| `ArrowDown`, `ArrowUp`                   | Moves focus to the next or previous option, skipping disabled ones                |
| `Home`, `End`                            | Moves focus to the first or last option                                           |
| `Space`, `Enter`                         | Chooses the focused option and closes it                                          |
| `Esc`                                    | Closes it, and moves focus back to the trigger                                    |
| A letter                                 | On the trigger, chooses the next option starting with it; in the list, focuses it |

## Accessibility

- The trigger is a `combobox` button for a `listbox` of `option`s, as Radix's; the list is named
  by the trigger, and each option by its text.
- While it is open, focus stays in the list, and the rest of the page is inert: Radix hides it
  from assistive technology, and inert also keeps focus and the pointer off it.
- Name the trigger: a `combobox` isn't named by its text, so upstream's examples, which have no
  label, are given `aria-label` here.
- Inside a form, a hidden native `<select>` carries the value under `@formName`, so the form
  submits it and the browser can autofill it.

## Testing

`SelectHarness` from `@ember-joinery/test-support` drives a select:

```ts
import { SelectHarness } from '@ember-joinery/test-support'

const fruit = new SelectHarness('fruit') // <Select @name="fruit">
await fruit.select('banana')
assert.strictEqual(fruit.value, 'banana')
assert.strictEqual(fruit.valueText, 'Banana')
```

| Member                                         | What it is                                                         |
| ---------------------------------------------- | ------------------------------------------------------------------ |
| `trigger`, `content`                           | Its trigger, and its list (or `null` while closed)                 |
| `isOpen`, `isShown`, `position`, `side`        | Whether it is open and in the top layer, and where the list went   |
| `value`, `valueText`, `isPlaceholder`          | The chosen value, what the trigger shows, and whether it's empty   |
| `label`, `description`, `contentLabel`         | The trigger's accessible name and description, and the list's name |
| `isDisabled`, `isInvalid`, `isRequired`        | From the trigger's `disabled` and ARIA                             |
| `options`, `optionTexts`, `option(value)`      | The options' values and text, and one option's element             |
| `highlighted`, `groups`, `optionsIn(group)`    | The focused option, the groups' labels, and a group's options      |
| `isOptionSelected(v)`, `isOptionDisabled(v)`   | An option's state                                                  |
| `canScrollUp`, `canScrollDown`, `nativeSelect` | The scroll buttons, and the hidden `<select>` in a form            |
| `open()`, `openWithKeyboard(key)`, `close()`   | A press on the trigger, a key on it, or Escape                     |
| `select(value)`, `pressOption(value)`          | Opens it and presses an option, or presses one                     |
| `pressKey(key)`, `typeahead(text)`, `focus()`  | Keys and typing where focus is                                     |

## Upstream

shadcn/ui's [Select](https://ui.shadcn.com/docs/components/radix/select), from
`apps/v4/registry/bases/radix/ui/select.tsx` at shadcn-ui/ui@8ab2771, in the Nova style, on
Radix's [Select](https://www.radix-ui.com/docs/primitives/components/select) (see the
[primitive](/primitives/select.md)).
