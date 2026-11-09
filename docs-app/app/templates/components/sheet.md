# Sheet

Extends the Dialog component to display content that complements the main content of the
screen.

<Example @name="sheet-demo" @title="Sheet" />

## Installation

```bash
pnpm add @ember-joinery/ember lucide
```

Import Joinery's CSS once (see [Installation](/getting-started/installation.md)), then the
component where you use it:

```gts
import { Sheet } from '@ember-joinery/ember'
```

## Usage

```gts
<Sheet as |s|>
  <s.Trigger>Open</s.Trigger>
  <s.Content>
    <s.Header>
      <s.Title>Are you absolutely sure?</s.Title>
      <s.Description>This action cannot be undone.</s.Description>
    </s.Header>
  </s.Content>
</Sheet>
```

A Sheet is a [Dialog](/components/dialog.md) that comes in from an edge of the screen, and
everything a Dialog does, a Sheet does: its parts, the `trigger` and `close` modifiers for your
own elements (`<Button {{s.trigger}}>`), and its state, its own or yours with `@open` and
`@onOpenChange`.

## Composition

Use the following composition to build a `Sheet`:

```text
Sheet
├── Trigger
└── Content
    ├── Header
    │   ├── Title
    │   └── Description
    └── Footer
```

## Side

Use `@side` on the Content to set the edge of the screen where the sheet appears. Values are
`top`, `right`, `bottom`, or `left`.

<Example @name="sheet-side" @title="Side" />

The scrolling region takes focus (`tabindex="0"`), so a keyboard can scroll it; upstream's
doesn't, and the accessibility audit every example runs asks for it.

## No Close Button

Use `@showCloseButton={{false}}` on the Content to hide the close button.

<Example @name="sheet-no-close-button" @title="No Close Button" />

## RTL

Joinery's styles use logical properties, so a sheet lays itself out right to left inside any
element with `dir="rtl"` (see [Direction](/primitives/direction.md)): its text starts on the
right, and its close button sits in the top left. `@side` stays physical, as upstream's does,
so a right-to-left page opens its sheet from the left with `@side="left"`.

<Example @name="sheet-rtl" @title="RTL" @dir="rtl" />

## API Reference

### Sheet

It takes a [Dialog](/components/dialog.md)'s arguments (`@open`, `@defaultOpen`,
`@onOpenChange`, `@modal`, `@onClose` and `@name`, for `SheetHarness`) and yields the same
parts and state.

### Content

| Argument           | Type                                     | Default      | What it does                                 |
| ------------------ | ---------------------------------------- | ------------ | -------------------------------------------- |
| `@side`            | `"top" \| "right" \| "bottom" \| "left"` | `"right"`    | The edge it comes in from                    |
| `@showCloseButton` | `boolean`                                | `true`       | Show the close button in the corner          |
| `@closeLabel`      | `string`                                 | `"Close"`    | The close button's name for screen readers   |
| `@closeIcon`       | a `lucide` icon                          | lucide's `x` | The close button's icon (upstream's `XIcon`) |

It also takes a Dialog Content's focus and dismissal handlers, `@forceMount` and `@as`.

### Data attributes

| Part         | `class`                               | `data-slot`         | Also                                       |
| ------------ | ------------------------------------- | ------------------- | ------------------------------------------ |
| Root         |                                       |                     | `data-test-jn="sheet"`                     |
| Trigger      |                                       | `sheet-trigger`     | `data-state`, `aria-expanded`              |
| Overlay      | `jn-sheet-overlay`                    | `sheet-overlay`     | `data-state`                               |
| Content      | `jn-sheet-content`                    | `sheet-content`     | `data-side`, `data-state`, `role="dialog"` |
| Close button | `jn-sheet-close` and a ghost Button's | `sheet-close`       | `data-test-jn-part="close-button"`         |
| Header       | `jn-sheet-header`                     | `sheet-header`      |                                            |
| Footer       | `jn-sheet-footer`                     | `sheet-footer`      |                                            |
| Title        | `jn-sheet-title jn-font-heading`      | `sheet-title`       | `id`, named by `aria-labelledby`           |
| Description  | `jn-sheet-description`                | `sheet-description` | `id`, named by `aria-describedby`          |
| Close        |                                       | `sheet-close`       |                                            |

The content slides in from its side on `data-state="open"`, and out on `closed`.

## Keyboard interactions

A Sheet's keys are a [Dialog](/components/dialog.md)'s: `Space` or `Enter` on the trigger
opens it, `Tab` and `Shift` + `Tab` go round inside it, and `Esc` closes it, with focus back on
the trigger.

## Accessibility

As a [Dialog](/components/dialog.md)'s: the content has the `dialog` role and is named by its
Title, focus moves in and back, and the page behind is inert and doesn't scroll.

## Testing

`SheetHarness` from `@ember-joinery/test-support` drives a `<Sheet>`. It is a `DialogHarness`
(see [Dialog](/components/dialog.md)), with `side`, the edge it comes in from:

```ts
import { SheetHarness } from '@ember-joinery/test-support'

const sheet = new SheetHarness('filters')
await sheet.open()
assert.strictEqual(sheet.side, 'right')
await sheet.pressOutside()
assert.false(sheet.isOpen)
```

## Upstream

shadcn/ui's [Sheet](https://ui.shadcn.com/docs/components/radix/sheet), from
`apps/v4/registry/bases/radix/ui/sheet.tsx` at shadcn-ui/ui@8ab2771, in the Nova style, on
Radix's Dialog. The headless part is [Dialog](/primitives/dialog.md) in
`@ember-joinery/primitives`, with `@slot="sheet"`.
