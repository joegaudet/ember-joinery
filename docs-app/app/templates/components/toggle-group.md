# Toggle Group

A set of two-state buttons that can be toggled on or off.

<Example @name="toggle-group-demo" @title="Toggle Group" />

## Installation

```bash
pnpm add @ember-joinery/ember
```

Import Joinery's CSS once (see [Installation](/getting-started/installation.md)), then the
component where you use it:

```gts
import { ToggleGroup } from '@ember-joinery/ember'
```

## Usage

```gts
<ToggleGroup @type="single" as |g|>
  <g.Item @value="a">A</g.Item>
  <g.Item @value="b">B</g.Item>
  <g.Item @value="c">C</g.Item>
</ToggleGroup>
```

With `@type="single"`, one item is pressed at a time, or none, and the value is its `@value`
(`''` for none). With `@type="multiple"`, any number are, and the value is an array. Start it
with `@defaultValue`, or own it with `@value` and `@onValueChange`.

## Composition

Use the following composition to build a `ToggleGroup`:

```text
ToggleGroup
├── g.Item
└── g.Item
```

The group yields its items as `g.Item`, and the `g.item` modifier for an element of your own
(`<button type="button" {{g.item value="bold"}}>`), which renders the same.

## Outline

Use `@variant="outline"` for an outline style.

<Example @name="toggle-group-outline" @title="Outline" />

## Size

Use `@size` to change the size of the toggle group.

<Example @name="toggle-group-sizes" @title="Size" />

## Spacing

Use `@spacing` to add spacing between toggle group items.

<Example @name="toggle-group-spacing" @title="Spacing" />

`@spacing` counts Tailwind's spacing steps (0.25rem each), and is 2 by default. With
`@spacing={{0}}` the items join: the corners between them are square, and an outline group has
one border between each.

## Vertical

Use `@orientation="vertical"` for vertical toggle groups.

<Example @name="toggle-group-vertical" @title="Vertical" />

## Disabled

<Example @name="toggle-group-disabled" @title="Disabled" />

## Custom

A custom toggle group example. Upstream's (`toggle-group-font-weight-selector`) is laid out in
a Field, which hasn't landed in Joinery yet; it comes with Field.

## RTL

The group takes its direction from the nearest `dir` (see [Direction](/primitives/direction.md)),
or from `@dir`: right to left, the items run from the right, the left arrow moves forward, and
joined items square off the corners on their own sides.

<Example @name="toggle-group-rtl" @title="RTL" @dir="rtl" />

## API Reference

### ToggleGroup

| Argument         | Type                         | Default        | What it does                                                |
| ---------------- | ---------------------------- | -------------- | ----------------------------------------------------------- |
| `@type`          | `"single" \| "multiple"`     |                | One item pressed at a time, or any number                   |
| `@defaultValue`  | `string \| string[]`         | `''`, `[]`     | The first value, uncontrolled                               |
| `@value`         | `string \| string[]`         |                | The value, controlled                                       |
| `@onValueChange` | `(value) => void`            |                | Called with each new value                                  |
| `@variant`       | `"default" \| "outline"`     |                | Every item's variant                                        |
| `@size`          | `"default" \| "sm" \| "lg"`  |                | Every item's size                                           |
| `@spacing`       | `number`                     | `2`            | The space between items, in spacing steps; `0` joins them   |
| `@orientation`   | `"horizontal" \| "vertical"` | `"horizontal"` | Which way the items run, and which arrows move between them |
| `@disabled`      | `boolean`                    | `false`        | Whether no item can be pressed                              |
| `@rovingFocus`   | `boolean`                    | `true`         | Whether the items share one tab stop                        |
| `@loop`          | `boolean`                    | `true`         | Whether the arrows wrap round                               |
| `@dir`           | `"ltr" \| "rtl"`             | the document's | The text direction                                          |
| `@as`            | tag name                     | `div`          | The tag to render                                           |
| `@name`          | `string`                     |                | Its name, for `ToggleGroupHarness` (`data-test-jn-name`)    |

It yields `g.Item`, `g.item`, `g.value` and `g.isPressed(value)`.

### g.Item

| Argument    | Type                        | Default     | What it does                           |
| ----------- | --------------------------- | ----------- | -------------------------------------- |
| `@value`    | `string`                    |             | Its value, unique in the group         |
| `@disabled` | `boolean`                   | `false`     | Whether it can't be pressed            |
| `@variant`  | `"default" \| "outline"`    | `"default"` | Its variant, when the group gives none |
| `@size`     | `"default" \| "sm" \| "lg"` | `"default"` | Its size, when the group gives none    |
| `@as`       | tag name                    | `button`    | The tag to render                      |

It yields whether it is pressed. `{{g.item value=… disabled=… variant=… size=…}}` is the same on
your own element; `toggleGroupItemClasses()` and `toggleGroupItemAttributes()` return its look.

### Data attributes

| Part  | `class`                                                                         | Data attributes                                                                                             |
| ----- | ------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------- |
| Group | `jn-toggle-group group/toggle-group`                                            | `data-slot="toggle-group"`, `data-variant`, `data-size` (when given), `data-spacing`, `data-orientation`    |
| Item  | `jn-toggle-group-item`, and a [Toggle's](/components/toggle.md#data-attributes) | `data-slot="toggle-group-item"`, `data-variant`, `data-size`, `data-spacing`, `data-state`, `data-disabled` |

The group also has `data-test-jn="toggle-group"` and `data-test-jn-name`, and each item
`data-test-jn-part="item"` and `data-test-jn-value`, its `@value`.

## Keyboard interactions

| Key                       | What it does                                            |
| ------------------------- | ------------------------------------------------------- |
| `Tab`                     | Moves focus to the pressed item (or the first), and out |
| `ArrowRight`, `ArrowLeft` | Moves to the next or previous item, horizontally        |
| `ArrowDown`, `ArrowUp`    | Moves to the next or previous item, vertically          |
| `Home`, `End`             | Moves to the first or last item                         |
| `Enter`, `Space`          | Presses the focused item                                |

The items share one tab stop (a [roving tabindex](/primitives/roving-focus.md)), and the arrows
wrap round. Right to left, left and right swap. Upstream's arrows move along either axis,
because its wrapper doesn't pass `orientation` on to Radix; Joinery's follow `@orientation`, as
Radix's own Toggle Group does, and as APG's toolbar pattern asks.

## Accessibility

- The group is a `role="group"`; give it an `aria-label` when its purpose isn't clear from
  around it.
- A `multiple` group's items are toggle buttons (`aria-pressed`). A `single` group's are radios
  (`role="radio"` and `aria-checked`), as Radix's.
- An icon-only item needs `aria-label`.

## Testing

`ToggleGroupHarness` from `@ember-joinery/test-support` drives a `<ToggleGroup>`:

```ts
import { ToggleGroupHarness } from '@ember-joinery/test-support'

const format = new ToggleGroupHarness('format') // <ToggleGroup @name="format">
await format.toggle('bold')
assert.deepEqual(format.value, ['bold'])
```

| Member                       | What it is                                     |
| ---------------------------- | ---------------------------------------------- |
| `value`                      | The values of the items pressed, in order      |
| `itemValues`                 | Every item's value, in order                   |
| `items`, `item(value)`       | The items' elements                            |
| `type`                       | `single` (its items are radios) or `multiple`  |
| `isPressed(value)`           | Whether an item is pressed                     |
| `isDisabled(value?)`         | Whether an item, or every item, is disabled    |
| `label(value)`               | An item's name                                 |
| `orientation`                | `horizontal` or `vertical`                     |
| `variant`, `size`, `spacing` | The group's `@variant`, `@size` and `@spacing` |
| `tabStop`, `focused`         | The item Tab lands on, and the one with focus  |
| `toggle(value)`              | Presses an item, as a click does               |
| `focus(value)`, `press(key)` | Focuses an item; presses a key where focus is  |

## Upstream

shadcn/ui's [Toggle Group](https://ui.shadcn.com/docs/components/radix/toggle-group), from
`apps/v4/registry/bases/radix/ui/toggle-group.tsx` at shadcn-ui/ui@8ab2771, in the Nova style.
Upstream's changelog: on 2026-05-17 the default `spacing` changed from `0` to `2`, so items
have space between them by default; use `@spacing={{0}}` for connected items.
