# Toggle Group

A set of two-state buttons that can be toggled on or off. It is Radix's `ToggleGroup`, and
covers ember-primitives' too (its `multi` is `@type="multiple"` here). It has no styles; the
styled [Toggle Group](/components/toggle-group.md) is built on it.

<Example @name="toggle-group-headless" @title="Text alignment" />

## Usage

```gts
import { array } from '@ember/helper'
import { ToggleGroup } from '@ember-joinery/primitives/toggle-group'

<template>
  <ToggleGroup @type="multiple" @defaultValue={{array "bold"}} aria-label="Format" as |g|>
    <g.Item @value="bold" aria-label="Bold">B</g.Item>
    <g.Item @value="italic" aria-label="Italic">I</g.Item>
    <button type="button" aria-label="Underline" {{g.item value="underline"}}>U</button>
  </ToggleGroup>
</template>
```

- **`@type="single"`**: one item pressed at a time, or none; the value is a string, `''` for
  none. Its items are radios (`role="radio"`, `aria-checked`), as in Radix.
- **`@type="multiple"`**: any number pressed; the value is an array. Its items are toggle
  buttons (`aria-pressed`).
- **Focus.** The items share one tab stop, on the [roving focus](/primitives/roving-focus.md):
  Tab enters on a pressed item (or the item focused last, or the first), the arrows along
  `@orientation` move between items and wrap round (`@loop`), and Home and End go to the ends.
  `@rovingFocus={{false}}` makes each item its own tab stop.
- Each item is `g.Item` (a `<button type="button">`, or `@as` any tag), or the `g.item`
  modifier on an element of your own. Both yield or carry `data-state` (`on` or `off`) and
  `data-disabled`.

### In a component

`ToggleGroupState` is the group's behaviour, for a component that renders its own group, as
the styled one does. Its `itemSpec(options)` is what an item puts on its element, so a
component can add its own classes to it in a `part()` of its own:

```ts
import { ToggleGroupState } from '@ember-joinery/primitives/toggle-group'
import { part } from '@ember-joinery/primitives/part'

class Toolbar extends Component {
  group = new ToggleGroupState({ type: () => 'multiple', value: () => this.args.value })
  item = part(named => ({ ...this.group.itemSpec(named), class: 'my-item' }))
}
```

```gts
<div role="group" {{this.group.group}}>
  <button type="button" {{this.item value="bold"}}>Bold</button>
</div>
```

## API

| Argument         | Type                         | Default        | What it does                                             |
| ---------------- | ---------------------------- | -------------- | -------------------------------------------------------- |
| `@type`          | `"single" \| "multiple"`     |                | One item pressed at a time, or any number                |
| `@defaultValue`  | `string \| string[]`         | `''`, `[]`     | The first value, uncontrolled                            |
| `@value`         | `string \| string[]`         |                | The value, controlled                                    |
| `@onValueChange` | `(value) => void`            |                | Called with each new value                               |
| `@disabled`      | `boolean`                    | `false`        | Whether no item can be pressed                           |
| `@rovingFocus`   | `boolean`                    | `true`         | Whether the items share one tab stop                     |
| `@orientation`   | `"horizontal" \| "vertical"` |                | Which arrows move focus; unset, all four                 |
| `@loop`          | `boolean`                    | `true`         | Whether the arrows wrap round                            |
| `@dir`           | `"ltr" \| "rtl"`             | the document's | The text direction                                       |
| `@as`            | tag name                     | `div`          | The tag to render                                        |
| `@name`          | `string`                     |                | Its name, for `ToggleGroupHarness` (`data-test-jn-name`) |

It yields `g.Item` (`@value`, `@disabled`, `@as`; it yields whether it is pressed), `g.item`
(the same, `{{g.item value=… disabled=…}}`), `g.value`, and `g.isPressed(value)`.

## Testing

```ts
import { ToggleGroupHarness } from '@ember-joinery/test-support'

const align = new ToggleGroupHarness()
await align.toggle('center')
assert.deepEqual(align.value, ['center'])
```

See the styled [Toggle Group](/components/toggle-group.md#testing) for every member.
