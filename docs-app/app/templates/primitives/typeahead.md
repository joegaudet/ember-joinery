# Typeahead

In a menu, a listbox or a select, typing the start of an item's text moves to it. This is the
search Radix's menus and select share: keys add up for a second, so "bl" goes past "Banana" to
"Blueberry", and pressing one letter again moves on to the next item starting with it.

<Example @name="typeahead-listbox" @title="A listbox" />

## Usage

On a container whose items take focus, the modifier does it all:

```gts
import { typeahead } from '@ember-joinery/primitives/typeahead'

<template>
  <div role="listbox" aria-label="Fruit" {{typeahead}}>
    <div role="option" tabindex="-1">Apple</div>
    <div role="option" tabindex="-1">Banana</div>
  </div>
</template>
```

It searches the focusable elements inside (those with `tabindex="-1"` too), leaving out any
with `aria-disabled="true"` or `data-disabled`, by their text. It goes well with a roving
focus group, as in the example above.

While a search is under way, Space is part of it. The modifier hears keys before the items do
and prevents that Space, so a button isn't pressed, and an item's own handler sees
`event.defaultPrevented`. A part's listeners skip a prevented event by themselves, as Radix's
do. A Space with no search under way presses the item as usual. The search clears a second
after the last key, and when focus leaves the container.

For something other than moving focus, such as a closed select whose trigger changes its value
as you type, use the pieces:

```ts
import { Typeahead, getNextMatch, isTypeaheadKey } from '@ember-joinery/primitives/typeahead'

search = new Typeahead()

onKeyDown = (event: KeyboardEvent) => {
  if (!isTypeaheadKey(event)) return
  const next = getNextMatch(this.options, this.search.type(event.key), this.selected, o => o.label)
  if (next) this.select(next)
}
```

`getNextMatch(items, search, current, textOf)` finds the first item after `current` whose text
starts with the search, ignoring case and wrapping round. A search of one letter repeated
(`"bbb"`) cycles through the items starting with it. `isTypeaheadKey` is one printable
character with no Ctrl, Alt or Meta. Call `dispose()` on a `Typeahead` when its owner goes.

## API

| Modifier argument | Type                                                | Default                | What it does                   |
| ----------------- | --------------------------------------------------- | ---------------------- | ------------------------------ |
| `items`           | `() => HTMLElement[]`                               | the focusable elements | What to search                 |
| `textValue`       | `(item: HTMLElement) => string`                     | its text, trimmed      | An item's text                 |
| `onMatch`         | `(item: HTMLElement, event: KeyboardEvent) => void` | focus it               | What to do with the match      |
| `timeout`         | `number`                                            | `1000`                 | How long a search lasts, in ms |
| `disabled`        | `boolean`                                           | `false`                | Turn it off                    |

Give `textValue` for items whose text isn't what a user would type, such as an icon and a label.

## Keyboard interactions

| Key                   | What it does                                                 |
| --------------------- | ------------------------------------------------------------ |
| A printable character | Moves to the next item whose text starts with what was typed |
| Space, mid-search     | Part of the search                                           |

## Testing

```ts
import { typeKeys } from '@ember-joinery/test-support'

await typeKeys('bl') // a key press on the focused element for each character
assert.strictEqual(listbox.focused, 'Blueberry')
```

`typeKeys` sends key events only, so it doesn't put text in an input; use `typeIn` for that.
