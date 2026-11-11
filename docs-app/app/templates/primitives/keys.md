# Keys

Keyboard shortcuts, written down: `Key` is one key, a `<kbd>`, and `KeyCombo` is a shortcut of
several, with a separator between them and the Mac's keys on a Mac. They are ember-primitives'
`Key` and `KeyCombo`.

<Example @name="keys-shortcuts" @title="A key and a shortcut" />

## Usage

```gts
import { array } from '@ember/helper'
import { Key, KeyCombo } from '@ember-joinery/primitives/keys'

<template>
  Press
  <Key>Esc</Key>
  to close.
  <KeyCombo @keys="ctrl+k" @mac="⌘+k" />
  <KeyCombo @keys={{array "Shift" "Alt" "N"}} @separator="then" />
</template>
```

In the string form, keys are joined with `+`, and the plus key itself is `++`: `"ctrl++"` is
Ctrl and +. The array form takes each key as given.

`isMac()` says whether the page runs on a Mac (or an iPad or iPhone), for handling shortcuts
the same way you show them.

## API

`KeyCombo`:

| Argument     | Type                 | Default | What it does                      |
| ------------ | -------------------- | ------- | --------------------------------- |
| `@keys`      | `string \| string[]` |         | The keys: `"ctrl+k"` or an array  |
| `@mac`       | `string \| string[]` |         | The keys to show on a Mac instead |
| `@separator` | `string`             | `+`     | What goes between the keys        |
| `@name`      | `string`             |         | The harness's name for it         |

`Key` takes `@name` and yields its label. Both take attributes.

## Testing

```ts
import { KeyHarness, KeyComboHarness } from '@ember-joinery/test-support'

new KeyHarness('escape').label // 'Esc'
const search = new KeyComboHarness('search')
search.keys // ['Ctrl', 'K'], or ['⌘', 'K'] on a Mac
search.separators // ['+']
search.label // 'Ctrl + K'
```
