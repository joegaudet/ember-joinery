# Button Group

A container that groups related buttons together with consistent styling.

<Example @name="button-group-demo" @title="Button Group" />

## Installation

```bash
pnpm add @ember-joinery/ember
```

Import Joinery's CSS once (see [Installation](/getting-started/installation.md)), then the
component where you use it:

```gts
import { ButtonGroup } from '@ember-joinery/ember'
```

## Usage

```gts
<ButtonGroup>
  <Button>Button 1</Button>
  <Button>Button 2</Button>
</ButtonGroup>
```

## Composition

Use the following composition to build a `ButtonGroup`:

```text
ButtonGroup
├── Button or Input
├── g.Separator
└── g.Text
```

## Accessibility

- The `ButtonGroup` component has the `role` attribute set to `group`.
- Use <kbd>Tab</kbd> to navigate between the buttons in the group.
- Use `aria-label` or `aria-labelledby` to label the button group.

```gts
<ButtonGroup aria-label="Button group">
  <Button>Button 1</Button>
  <Button>Button 2</Button>
</ButtonGroup>
```

## ButtonGroup vs ToggleGroup

- Use the `ButtonGroup` component when you want to group buttons that perform an action.
- Use the `ToggleGroup` component when you want to group buttons that toggle a state.

## Orientation

Set `@orientation` to change the button group layout.

<Example @name="button-group-orientation" @title="Orientation" />

Upstream's icon buttons here have no names; Joinery's are named (`aria-label`), so they pass the
accessibility audit every example runs. The same goes for the next two examples.

## Size

Control the size of buttons using `@size` on individual buttons.

<Example @name="button-group-size" @title="Size" />

## Nested

Nest `<ButtonGroup>` components to create button groups with spacing.

<Example @name="button-group-nested" @title="Nested" />

Upstream's icon button and input are unnamed; Joinery's are named (`aria-label`). The addon is
the tooltip's trigger (`<g.Addon {{t.trigger}}>`, upstream's `TooltipTrigger asChild`).

## Separator

The group's `Separator` part visually divides buttons within a group.

Buttons with `@variant="outline"` do not need a separator since they have a border. For other
variants, a separator is recommended to improve the visual hierarchy.

<Example @name="button-group-separator" @title="Separator" />

## Split

Create a split button group by adding two buttons separated by a `Separator`.

<Example @name="button-group-split" @title="Split" />

## Input

Wrap an `Input` component with buttons.

<Example @name="button-group-input" @title="Input" />

## Input Group

Wrap an [`InputGroup`](/components/input-group.md) component to create complex input layouts.

<Example @name="button-group-input-group" @title="Input Group" />

## Dropdown Menu

Create a split button group with a [`DropdownMenu`](/components/dropdown-menu.md) component.

<Example @name="button-group-dropdown" @title="Dropdown Menu" />

## Select

Pair with a [`Select`](/components/select.md) component.

<Example @name="button-group-select" @title="Select" />

## Popover

Use with a [`Popover`](/components/popover.md) component.

<Example @name="button-group-popover" @title="Popover" />

## RTL

Joinery's styles use logical properties, so a group joins its buttons right to left inside any
element with `dir="rtl"` (see [Direction](/primitives/direction.md)): the first button is on the
right, with its rounded corners there.

<Example @name="button-group-rtl" @title="RTL" @dir="rtl" />

## API Reference

### ButtonGroup

The `ButtonGroup` component is a container that groups related buttons together with consistent
styling.

| Argument       | Type                         | Default        | What it does                                             |
| -------------- | ---------------------------- | -------------- | -------------------------------------------------------- |
| `@orientation` | `"horizontal" \| "vertical"` | `"horizontal"` | A row, or a column                                       |
| `@as`          | tag name                     | `div`          | The tag to render                                        |
| `@name`        | `string`                     |                | Its name, for `ButtonGroupHarness` (`data-test-jn-name`) |

```gts
<ButtonGroup>
  <Button>Button 1</Button>
  <Button>Button 2</Button>
</ButtonGroup>
```

Nest multiple button groups to create complex layouts with spacing.

```gts
<ButtonGroup>
  <ButtonGroup />
  <ButtonGroup />
</ButtonGroup>
```

It yields its parts, each as a component and as a modifier for your own element: `Separator`
and `separator`, `Text` and `text`. `buttonGroupClasses({ orientation })` returns the classes it
renders, upstream's `buttonGroupVariants`, for code of your own.

### Separator

The group's `Separator` part visually divides buttons within a group: upstream's Separator, in
the input colour, decorative (`role="none"` and `aria-hidden="true"`, from the primitives'
[`separatorAria()`](/primitives/separator.md)).

| Argument       | Type                         | Default      | What it does                          |
| -------------- | ---------------------------- | ------------ | ------------------------------------- |
| `@orientation` | `"horizontal" \| "vertical"` | `"vertical"` | Which way it runs                     |
| `@decorative`  | `boolean`                    | `true`       | `false` gives it the `separator` role |
| `@as`          | tag name                     | `div`        | The tag to render                     |

```gts
<ButtonGroup as |g|>
  <Button>Button 1</Button>
  <g.Separator />
  <Button>Button 2</Button>
</ButtonGroup>
```

### Text

Use the `Text` part to display text within a button group.

| Argument | Type     | Default | What it does                                       |
| -------- | -------- | ------- | -------------------------------------------------- |
| `@as`    | tag name | `div`   | The tag to render (upstream's `asChild`, for tags) |

```gts
<ButtonGroup as |g|>
  <g.Text>Text</g.Text>
  <Button>Button</Button>
</ButtonGroup>
```

Upstream's `asChild` renders a custom component as the text, for example a label. In Joinery,
give `@as` a tag, or put the `text` modifier on your own component:

```gts
<ButtonGroup as |g|>
  <g.Text @as="label" for="name">Text</g.Text>
  <input placeholder="Type something here..." id="name" />
</ButtonGroup>
```

### Data attributes

| Part        | Attribute            | Value                                                                             |
| ----------- | -------------------- | --------------------------------------------------------------------------------- |
| ButtonGroup | `class`              | `jn-button-group jn-button-group-orientation-<orientation>`, `group/button-group` |
|             | `role`               | `group`                                                                           |
|             | `data-slot`          | `button-group`                                                                    |
|             | `data-orientation`   | its `@orientation`, when given (as upstream's)                                    |
|             | `data-test-jn`       | `button-group`                                                                    |
| Separator   | `class`, `data-slot` | `jn-button-group-separator`, `button-group-separator`                             |
|             | `role`               | `none`, or `separator` with `@decorative={{false}}`                               |
|             | `aria-hidden`        | `true` while it is decorative                                                     |
|             | `aria-orientation`   | `vertical`, on a vertical one with `@decorative={{false}}`                        |
|             | `data-orientation`   | its `@orientation`                                                                |
|             | `data-test-jn-part`  | `separator`                                                                       |
| Text        | `class`              | `jn-button-group-text` (no `data-slot`, as upstream's)                            |
|             | `data-test-jn-part`  | `text`                                                                            |

### Overlays in a group

A trigger can be a group's part: a Dropdown Menu's, a Popover's, a Select's or a Tooltip's, as in
the examples above, and so can a Combobox's input. Radix's overlay roots (and Base UI's Combobox)
render no element, so upstream's trigger is the group's
own child; a Joinery overlay's root is an element with `display: contents` around its trigger, so
it adds no box, and `button-group.css` restates the group's rules one root down, so the trigger
joins its neighbours as upstream's does. The same goes for an Input Group's addon that is an
overlay's trigger (`button-group-nested`).

## Keyboard interactions

| Key         | What it does                                               |
| ----------- | ---------------------------------------------------------- |
| `Tab`       | Moves focus to the next button in the group, and out of it |
| `Shift+Tab` | Moves focus to the previous button                         |

A button group has no keys of its own: each button is in the tab order, and a focused one rises
above its neighbours, so its focus ring shows whole. For a set of buttons the arrow keys move
between, use Toggle Group or a toolbar.

## Testing

`ButtonGroupHarness` from `@ember-joinery/test-support` drives a `<ButtonGroup>`:

```ts
import { ButtonGroupHarness, ButtonHarness } from '@ember-joinery/test-support'

const controls = new ButtonGroupHarness('media') // <ButtonGroup @name="media">
assert.strictEqual(controls.label, 'Media controls')
assert.strictEqual(controls.orientation, 'vertical')
await controls.find(ButtonHarness).click()
```

| Member        | What it is                                                       |
| ------------- | ---------------------------------------------------------------- |
| `role`        | Its role, `group`                                                |
| `label`       | Its accessible name: `aria-label`, else `aria-labelledby`'s text |
| `orientation` | Its `@orientation`                                               |
| `buttons`     | A `ButtonHarness` for each button, nested groups' included       |
| `groups`      | A `ButtonGroupHarness` for each group nested in it               |
| `separators`  | Its own separators                                               |
| `texts`       | The text of each of its own text parts                           |

## Upstream

shadcn/ui's [Button Group](https://ui.shadcn.com/docs/components/radix/button-group), from
`apps/v4/registry/bases/radix/ui/button-group.tsx` at shadcn-ui/ui@8ab2771, in the Nova style.
