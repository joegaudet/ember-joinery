# Combobox

An input with a list of suggestions, as Base UI's `Combobox`: typing filters the items, the
arrow keys highlight one while focus stays in the input, and Enter or a press chooses it. It has
no styles; the styled [Combobox](/components/combobox.md) is built on it.

<Example @name="combobox-headless" @title="A combobox of your own" />

## Usage

```gts
import { Combobox } from '@ember-joinery/primitives/combobox'

<template>
  <Combobox @items={{this.fruits}} as |c|>
    <c.Input aria-label="Fruit" />
    <c.Trigger aria-label="Show fruits">▼</c.Trigger>
    <c.Clear aria-label="Clear" />
    <c.Content @align="start" @sideOffset={{4}}>
      <c.Empty>No fruit matches.</c.Empty>
      <c.List as |fruit|>
        <c.Item @value={{fruit}} as |item|>
          {{fruit}}
          <item.ItemIndicator>✓</item.ItemIndicator>
        </c.Item>
      </c.List>
    </c.Content>
  </Combobox>
</template>
```

- **Items.** `@items` is a list of items, or of groups (`{ value, items }`), which the List
  yields one at a time; a Group yields the `Collection` of its own. An item's text is its
  `label`, its `value` or itself (`@itemToStringLabel` to say otherwise).
- **Filtering.** The default filter matches the query anywhere in the label with an
  `Intl.Collator` (case, accents and punctuation ignored), and a single combobox whose input
  shows its value's label shows every item until the user types. `@filter` takes your own, and
  `@filter={{null}}` shows `@items` unfiltered, for results you fetch as `@onInputValueChange`
  tells you the query. `@limit` caps the list.
- **One or several.** The value is one item (or `null`), or with `@multiple` an array, shown in
  chips: `{{c.chips}}` on their container, and `c.Chip` for each, which yields its `Remove`
  button. Backspace in the empty input removes the last; the arrows move between them.
- **The input inside the popup.** Put `c.Input` inside `c.Content`, and the trigger becomes the
  combobox: the popup is a `dialog` named by it, focus moves to the input when it opens and back
  to the trigger when it closes, and the input starts empty each time.
- **Placement.** The popup goes below the input (the trigger, with the input inside it), or
  against `@anchor`, with Base UI's custom properties (`--anchor-width`, `--available-height`…).
- **Dismissal.** Escape, a press outside, or focus leaving closes it; Escape on the closed list
  clears the input and the value. It isn't modal: the page stays as it is.
- **Forms.** With `@formName`, hidden inputs carry each value (`@itemToStringValue` for an
  object's).

## From Base UI

Base UI's parts are yielded under their names, but `Positioner`, `Popup` and `Portal` are one
`Content`, in the top layer; `GroupLabel` is `GroupLabel` here and `Label` in the styled
Combobox, as shadcn names it. Its props are arguments: `items`, `value`, `inputValue`, `open`,
`multiple`, `autoHighlight`, `filter`, `itemToStringLabel`… Base UI's `name` is `@formName`,
and `@name` names it for `ComboboxHarness`. The separator is hidden from assistive technology
rather than `role="separator"`, which a listbox may not hold.
