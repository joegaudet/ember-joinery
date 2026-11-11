# Combobox

Autocomplete input with a list of suggestions.

<Example @name="combobox-demo" @title="Combobox" />

## Installation

```bash
pnpm add @ember-joinery/ember
```

Import Joinery's CSS once (see [Installation](/getting-started/installation.md)), then the
component where you use it:

```gts
import { Combobox } from '@ember-joinery/ember'
```

## Usage

`<Combobox>` takes the items and yields its parts. The List yields each item that matches what
was typed:

```gts
import { Combobox } from '@ember-joinery/ember'

const frameworks = ['Next.js', 'SvelteKit', 'Nuxt.js', 'Remix', 'Astro']

<template>
  <Combobox @items={{frameworks}} as |c|>
    <c.Input placeholder="Select a framework" />
    <c.Content>
      <c.Empty>No items found.</c.Empty>
      <c.List as |item|>
        <c.Item @value={{item}}>{{item}}</c.Item>
      </c.List>
    </c.Content>
  </Combobox>
</template>
```

Its value is its own, or yours: `@value` with `@onValueChange`, or `@defaultValue` to start
with one. The input's text works the same way (`@inputValue`, `@onInputValueChange`).

## Composition

### Simple

A single-line input and a flat list (see [Basic](#basic)).

```text
Combobox
├── c.Input
└── c.Content
    ├── c.Empty
    └── c.List
        ├── c.Item
        └── c.Item
```

### With chips

Multi-select with `@multiple`, chips, and a chips input (see [Multiple](#multiple)).

```text
Combobox
├── c.Chips
│   ├── c.Value
│   │   └── c.Chip
│   └── c.ChipsInput
└── c.Content
    ├── c.Empty
    └── c.List
        ├── c.Item
        └── c.Item
```

### With groups and collection

Nested items per group using the Collection each `c.Group` yields, with a separator between
groups (see [Groups](#groups)).

```text
Combobox
├── c.Input
└── c.Content
    ├── c.Empty
    └── c.List
        ├── c.Group
        │   ├── c.Label
        │   └── g.Collection
        │       ├── c.Item
        │       └── c.Item
        ├── c.Separator
        └── c.Group
            ├── c.Label
            └── g.Collection
                ├── c.Item
                └── c.Item
```

## Custom Items

Use `@itemToStringValue` when your items are objects (and `@itemToStringLabel` for the text the
input shows and the filter matches, when it isn't their `label`).

```gts
import { Combobox } from '@ember-joinery/ember'

const frameworks = [
  { label: 'Next.js', value: 'next' },
  { label: 'SvelteKit', value: 'sveltekit' },
  { label: 'Nuxt', value: 'nuxt' },
]

const labelOf = (framework: { label: string }) => framework.label

<template>
  <Combobox @items={{frameworks}} @itemToStringValue={{labelOf}} as |c|>
    <c.Input placeholder="Select a framework" />
    <c.Content>
      <c.Empty>No items found.</c.Empty>
      <c.List as |framework|>
        <c.Item @value={{framework}}>{{framework.label}}</c.Item>
      </c.List>
    </c.Content>
  </Combobox>
</template>
```

## Multiple Selection

Use `@multiple` with chips for multi-select behavior.

```gts
import { Combobox } from '@ember-joinery/ember'

<template>
  <Combobox
    @items={{frameworks}}
    @multiple={{true}}
    @value={{this.value}}
    @onValueChange={{this.setValue}}
    as |c|
  >
    <c.Chips>
      <c.Value as |values|>
        {{#each values as |item|}}
          <c.Chip @value={{item}}>{{item}}</c.Chip>
        {{/each}}
      </c.Value>
      <c.ChipsInput placeholder="Add framework" />
    </c.Chips>
    <c.Content @anchor={{c.chipsElement}}>
      <c.Empty>No items found.</c.Empty>
      <c.List as |item|>
        <c.Item @value={{item}}>{{item}}</c.Item>
      </c.List>
    </c.Content>
  </Combobox>
</template>
```

## Basic

A simple combobox with a list of frameworks.

<Example @name="combobox-basic" @title="Basic" />

## Multiple

A combobox with multiple selection using `@multiple` and `c.Chips`. Upstream's
`useComboboxAnchor` is the yielded `c.chipsElement`, given to the Content as `@anchor`.

<Example @name="combobox-multiple" @title="Multiple" />

## Clear Button

Use `@showClear` to show a clear button.

<Example @name="combobox-clear" @title="Clear Button" />

## Groups

Use `c.Group` and `c.Separator` to group items.

<Example @name="combobox-groups" @title="Groups" />

## Custom Items

You can render a custom component inside `c.Item`.

<Example @name="combobox-custom" @title="Custom Items" />

## Invalid

Use the `aria-invalid` attribute to make the combobox invalid.

<Example @name="combobox-invalid" @title="Invalid" />

## Disabled

Use `@disabled` on the input to disable the combobox.

<Example @name="combobox-disabled" @title="Disabled" />

## Auto Highlight

Use `@autoHighlight` to automatically highlight the first item on filter.

<Example @name="combobox-auto-highlight" @title="Auto Highlight" />

## Popup

You can trigger the combobox from a button or any other component with the `trigger` modifier
(upstream's `render` prop), with `c.TriggerIcon` for the chevron. Move `c.Input` inside
`c.Content`.

<Example @name="combobox-popup" @title="Popup" />

## Input Group

You can add an addon to the combobox by putting the `Addon` that `c.Input` yields (upstream's
`InputGroupAddon`) inside it: `<c.Input as |g|><g.Addon>…</g.Addon></c.Input>`.

<Example @name="combobox-input-group" @title="Input Group" />

## RTL

Joinery's components take their direction from the nearest `dir` (see
[Direction](/primitives/direction.md)): the chevron and the check marks move to the left, and
the arrow keys between chips flip.

<Example @name="combobox-rtl" @title="RTL" @dir="rtl" @align="start" />

## API Reference

### Combobox

| Argument                                                   | Type                                | Default     | What it does                                                      |
| ---------------------------------------------------------- | ----------------------------------- | ----------- | ----------------------------------------------------------------- |
| `@items`                                                   | array, or `{ value, items }` groups |             | What the list shows and the input filters                         |
| `@value`, `@defaultValue`, `@onValueChange`                | an item (an array with `@multiple`) | `null`      | The chosen item, controlled or not                                |
| `@multiple`                                                | `boolean`                           | `false`     | Choose several, shown as chips                                    |
| `@inputValue`, `@defaultInputValue`, `@onInputValueChange` | `string`                            |             | The input's text, controlled or not                               |
| `@open`, `@defaultOpen`, `@onOpenChange`                   | `boolean`                           | `false`     | Whether the list is open                                          |
| `@autoHighlight`                                           | `boolean \| "always"`               | `false`     | Highlight the first match as the user types                       |
| `@itemToStringLabel`, `@itemToStringValue`                 | `(item) => string`                  |             | An item's text, and its form value                                |
| `@isItemEqualToValue`                                      | `(item, value) => boolean`          | `Object.is` | Whether an item is the chosen value                               |
| `@filter`                                                  | `(item, query) => boolean \| null`  | collator    | Your own filter, or `null` to show `@items` as given              |
| `@filteredItems`, `@limit`, `@locale`                      |                                     |             | Items filtered elsewhere, the most to show, the collator's locale |
| `@openOnInputClick`, `@highlightItemOnHover`, `@loopFocus` | `boolean`                           | `true`      | Open on a press, follow the pointer, wrap the arrows              |
| `@disabled`, `@readOnly`, `@required`                      | `boolean`                           | `false`     | The input's state                                                 |
| `@formName`, `@form`                                       | `string`                            |             | Hidden inputs carry each value under this name                    |
| `@name`                                                    | `string`                            |             | Its name, for `ComboboxHarness` (`data-test-jn-name`)             |

It yields `{ Input, Trigger, TriggerIcon, Clear, Value, Content, List, Item, Group, Label,
Collection, Empty, Separator, Chips, Chip, ChipsInput, input, trigger, chipsElement, value,
inputValue, isOpen, setOpen, setValue }`. Base UI's `name` is `@formName`: `@name` names it for
its harness.

### c.Input

The `<input>` in an input group, with the chevron button at its end. Attributes
(`placeholder`, `aria-invalid`, `class`…) go on the `<input>`; upstream puts its `className` on
the group, which is `@groupClass` here (`@groupClass="w-full"`). `@showTrigger` (default `true`) shows the
chevron, `@showClear` the clear button while there is a value, and `@disabled` disables the
input and its buttons. Its block holds addons, and yields `Addon` (`as |g|`, then
`<g.Addon @align="inline-start">`), Input Group's addon, which a press focuses the input
from. Upstream leaves the buttons unnamed; Joinery
names them (`@triggerLabel`, default `Show options`; `@clearLabel`, default `Clear`).

### c.Content

| Argument       | Type                                     | Default    | What it does                               |
| -------------- | ---------------------------------------- | ---------- | ------------------------------------------ |
| `@side`        | `"top" \| "right" \| "bottom" \| "left"` | `"bottom"` | The side of the input it goes on           |
| `@align`       | `"start" \| "center" \| "end"`           | `"start"`  | Where along that side                      |
| `@sideOffset`  | `number`                                 | `6`        | Its distance from the input, in pixels     |
| `@alignOffset` | `number`                                 | `0`        | Its shift along the side                   |
| `@anchor`      | `Element`                                |            | What to place it against: `c.chipsElement` |

### The other parts

`c.List` yields each filtered item (or group) and its index. `c.Item` takes `@value` (one of
the items), `@disabled` and `@icon` (its check mark). `c.Group` takes the group's `@items` and
yields its `Collection`; `c.Label` names the group it is in. `c.Empty` speaks (a polite live
region) only while nothing matches. `c.Value` shows the chosen item's label, or yields the
value (the array of chosen items, with `@multiple`) to its block. `c.Chip` takes `@value` and
`@showRemove` (default `true`), and names its remove button with `@removeLabel` (default
`Remove`). `c.Separator` is hidden from assistive technology: a listbox may not hold one.

### Data attributes

| Part    | Attributes                                                                                                                                                                                   |
| ------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| root    | `data-test-jn="combobox"`, `data-test-jn-name`                                                                                                                                               |
| input   | `role="combobox"`, `aria-expanded`, `aria-controls`, `aria-activedescendant`, `data-popup-open`, `data-list-empty`, `data-test-jn-part="input"`                                              |
| content | `class="jn-combobox-content"`, `data-slot="combobox-content"`, `data-open` or `data-closed`, `data-empty`, `data-side`, `data-align`, `data-chips`, `data-test-jn-part="content"`            |
| item    | `class="jn-combobox-item"`, `data-slot="combobox-item"`, `role="option"`, `aria-selected`, `data-highlighted`, `data-selected`, `data-test-jn-part="item"`, `data-test-jn-value` (its label) |
| chip    | `class="jn-combobox-chip"`, `data-slot="combobox-chip"`, `data-test-jn-part="chip"`, `data-test-jn-value`                                                                                    |

## Keyboard interactions

| Key                    | What it does                                                              |
| ---------------------- | ------------------------------------------------------------------------- |
| Typing                 | Filters the list and opens it                                             |
| `ArrowDown`, `ArrowUp` | Opens it; then moves the highlight, round through the input and back      |
| `Enter`                | Chooses the highlighted item (with none, closes it, so a form can submit) |
| `Esc`                  | Closes it; on the closed list, clears the input and the value             |
| `Home`, `End`          | Moves the caret in the input                                              |
| `Backspace`            | In an empty input, removes the last chip                                  |
| `ArrowLeft`            | At the input's start, moves into the chips (`ArrowRight` right to left)   |

## Accessibility

- The input is a `combobox` for a `listbox`; focus stays in the input while the arrow keys
  highlight an item (`aria-activedescendant`), as Base UI's.
- The list is named as the input is: by its label, or else its `aria-label` or placeholder.
  With the input in the popup, the popup is a `dialog`, named by its trigger.
- Empty is a polite live region, so "No items found" is announced.
- Upstream's chevron, clear and chip remove buttons have no names; Joinery's do. A separator is
  hidden from assistive technology, since a listbox may not hold one.

## Testing

`ComboboxHarness` from `@ember-joinery/test-support` drives a combobox:

```ts
import { ComboboxHarness } from '@ember-joinery/test-support'

const framework = new ComboboxHarness('framework') // <Combobox @name="framework">
await framework.type('sv')
assert.deepEqual(framework.items, ['SvelteKit'])
await framework.pressKey('ArrowDown')
await framework.pressKey('Enter')
assert.strictEqual(framework.inputValue, 'SvelteKit')
```

| Member                                                                  | What it is                                                     |
| ----------------------------------------------------------------------- | -------------------------------------------------------------- |
| `input`, `trigger`, `clearButton`, `content`, `list`                    | Its parts (the popup's are `null` while closed)                |
| `isOpen`, `isShown`, `side`                                             | Whether it is open and in the top layer, and where it went     |
| `inputValue`, `placeholder`, `label`, `description`                     | The input's text, placeholder, and accessible name             |
| `isDisabled`, `isInvalid`, `isRequired`, `isFocused`                    | The input's state                                              |
| `items`, `itemTexts`, `item(label)`                                     | The items shown now (by label), their text, and one item       |
| `highlighted`, `isItemSelected(l)`, `isItemDisabled(l)`                 | The highlighted item, and an item's state                      |
| `groups`, `isEmpty`, `emptyText`                                        | The groups' labels, and whether nothing matches                |
| `chips`, `chip(label)`, `formValues`                                    | The chips, and the hidden inputs' values                       |
| `open()`, `close()`, `pressTrigger()`, `clear()`                        | Open and close it, press its buttons                           |
| `type(text)`, `deleteBackward(n)`, `fill(text)`                         | Type as a person does, delete, or replace the text as autofill |
| `select(label)`, `pressItem(label)`, `removeChip(label)`                | Choose an item, or remove a chip                               |
| `pressKey(key)`, `pressEscape()`, `pressOutside()`, `focus()`, `blur()` | Keys and focus                                                 |

## Upstream

shadcn/ui's [Combobox](https://ui.shadcn.com/docs/components/radix/combobox), from
`apps/v4/registry/bases/radix/ui/combobox.tsx` at shadcn-ui/ui@8ab2771, in the Nova style
(the page shows most examples in `base-nova`, whose rules are the same), on Base UI's
[Combobox](https://base-ui.com/react/components/combobox) (see the
[primitive](/primitives/combobox.md)).
