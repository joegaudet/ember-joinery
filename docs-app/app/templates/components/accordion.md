# Accordion

A vertically stacked set of interactive headings that each reveal a section of content.

<Example @name="accordion-demo" @title="Accordion" @align="start" />

## Installation

```bash
pnpm add @ember-joinery/ember lucide
```

Import Joinery's CSS once (see [Installation](/getting-started/installation.md)), then the
component where you use it:

```gts
import { Accordion } from '@ember-joinery/ember'
```

## Usage

```gts
<Accordion @type="single" @collapsible={{true}} @defaultValue="item-1" as |accordion|>
  <accordion.Item @value="item-1" as |item|>
    <item.Trigger>Is it accessible?</item.Trigger>
    <item.Content>Yes. It adheres to the WAI-ARIA design pattern.</item.Content>
  </accordion.Item>
</Accordion>
```

Name the block parameters after what they are, as here: `as |a|` would turn every `<a>` link
inside into a call to it.

## Composition

Use the following composition to build an `Accordion`:

```text
Accordion
├── accordion.Item
│   ├── item.Trigger
│   └── item.Content
└── accordion.Item
    ├── item.Trigger
    └── item.Content
```

`item.Trigger` renders the item's heading (an `<h3>`) with the button inside it, and its
chevrons.

## Basic

A basic accordion that shows one item at a time. The first item is open by default.

<Example @name="accordion-basic" @title="Basic" @align="start" />

## Multiple

Use `@type="multiple"` to allow multiple items to be open at the same time.

<Example @name="accordion-multiple" @title="Multiple" @align="start" />

## Disabled

Use `@disabled` on an item to disable it.

<Example @name="accordion-disabled" @title="Disabled" @align="start" />

## Borders

Add `border` to the `Accordion` and `border-b last:border-b-0` to the item to add borders to
the items. Without Tailwind, set the same in your own CSS, which wins over Joinery's (its rules
are in the `joinery` layer).

<Example @name="accordion-borders" @title="Borders" @align="start" />

## Card

Wrap the `Accordion` in a `Card` component. Upstream's example comes with Card, which hasn't
landed in Joinery yet.

## RTL

Joinery's styles use logical properties, so an accordion lays itself out right to left inside
any element with `dir="rtl"` (see [Direction](/primitives/direction.md)): the questions start
on the right and the chevrons sit at the left. Its arrow keys follow the direction too.

<Example @name="accordion-rtl" @title="RTL" @dir="rtl" @align="start" />

## API Reference

### Accordion

| Argument         | Type                                     | Default    | What it does                                                |
| ---------------- | ---------------------------------------- | ---------- | ----------------------------------------------------------- |
| `@type`          | `"single" \| "multiple"`                 |            | One item open at a time, or any number                      |
| `@value`         | `string` (single), `string[]` (multiple) |            | The controlled value: the open item's, or the open items'   |
| `@defaultValue`  | `string` (single), `string[]` (multiple) |            | The first value, when uncontrolled                          |
| `@onValueChange` | `(value) => void`                        |            | Called with each new value; `''` when a single one closes   |
| `@collapsible`   | `boolean`                                | `false`    | For `single`: whether the open item can close, leaving none |
| `@disabled`      | `boolean`                                | `false`    | Whether no item can be opened or closed                     |
| `@orientation`   | `"vertical" \| "horizontal"`             | `vertical` | Which arrow keys move between the triggers                  |
| `@dir`           | `"ltr" \| "rtl"`                         | the page's | The direction the left and right arrows follow              |
| `@as`            | tag name                                 | `div`      | The tag to render                                           |
| `@name`          | `string`                                 |            | Its name, for `AccordionHarness` (`data-test-jn-name`)      |

It yields `Item` and `value`.

### Item

| Argument    | Type      | Default | What it does                              |
| ----------- | --------- | ------- | ----------------------------------------- |
| `@value`    | `string`  |         | The item's value, unique in its accordion |
| `@disabled` | `boolean` | `false` | Whether it can't be opened or closed      |
| `@as`       | tag name  | `div`   | The tag to render                         |

It yields `Trigger`, `Content`, `trigger` (the trigger's behaviour, classes and `data-slot` as
a modifier for your own element, without the heading or chevrons), `isOpen`, `isDisabled` and
`toggle`.

### Trigger

| Argument     | Type        | Default                 | What it does                                    |
| ------------ | ----------- | ----------------------- | ----------------------------------------------- |
| `@icon`      | lucide icon | lucide's `chevron-down` | The icon shown while the item is closed         |
| `@openIcon`  | lucide icon | lucide's `chevron-up`   | The icon shown while it is open                 |
| `@headingAs` | tag name    | `h3`                    | The heading's tag: the level that fits the page |
| `@as`        | tag name    | `button`                | The button's tag                                |

### Content

As upstream's `className`, its `class` and attributes go on the inner element, which holds the
padding; the outer one is the `region`, and animates. `@forceMount={{true}}` keeps it rendered
and shown while closed. Its height animates from `--radix-accordion-content-height`, measured
each time it opens or closes.

### Data attributes

| Part      | Attribute                                         | Value                                                                                |
| --------- | ------------------------------------------------- | ------------------------------------------------------------------------------------ |
| root      | `class`, `data-slot`                              | `jn-accordion`, `accordion`                                                          |
| item      | `class`, `data-slot`                              | `jn-accordion-item`, `accordion-item`                                                |
| header    | `class`                                           | `jn-accordion-header`                                                                |
| trigger   | `class`, `data-slot`                              | `jn-accordion-trigger group/accordion-trigger`, `accordion-trigger`                  |
| icons     | `class`, `data-slot`                              | `jn-accordion-trigger-icon`, `accordion-trigger-icon`                                |
| content   | `class`, `data-slot`                              | `jn-accordion-content`, `accordion-content`; inside it, `jn-accordion-content-inner` |
| all parts | `data-state`, `data-disabled`, `data-orientation` | `open` or `closed`; present while disabled; the orientation                          |

For the harness: `data-test-jn="accordion"` on the root, and `data-test-jn-part` (`item`,
`header`, `trigger`, `content`) with `data-test-jn-value` (the item's `@value`) on each part.

## Keyboard interactions

| Key                       | What it does                                                       |
| ------------------------- | ------------------------------------------------------------------ |
| `Tab`                     | Moves focus to the next trigger, or into open content              |
| `Enter`, `Space`          | Opens or closes the focused item                                   |
| `ArrowDown`, `ArrowUp`    | Moves to the next or previous trigger, wrapping round              |
| `ArrowRight`, `ArrowLeft` | The same, with `@orientation="horizontal"` (swapped right to left) |
| `Home`, `End`             | Moves to the first or last trigger                                 |

That is the [APG accordion pattern](https://www.w3.org/WAI/ARIA/apg/patterns/accordion/), as
Radix's accordion has it. Disabled triggers are passed over.

## Accessibility

- Each trigger is a `<button>` in a heading, with `aria-expanded` and `aria-controls`.
- Each content is a `region` labelled by its trigger (`aria-labelledby`), and is `hidden` while
  closed, so nothing in it takes focus or is read.
- In a `single` accordion that isn't `@collapsible`, the open item's trigger is
  `aria-disabled="true"`: it can't close the item.
- Pick the heading level that fits the page with `@headingAs` on each trigger.

## Testing

`AccordionHarness` from `@ember-joinery/test-support` drives an `<Accordion>`, styled or
headless, finding items by their `@value`:

```ts
import { AccordionHarness } from '@ember-joinery/test-support'

const faq = new AccordionHarness('faq') // <Accordion @name="faq">
await faq.toggle('returns')
assert.deepEqual(faq.openValues, ['returns'])
await faq.focus('returns')
await faq.press('ArrowDown')
assert.strictEqual(faq.focused, 'support')
```

| Member                                                             | What it is                                                      |
| ------------------------------------------------------------------ | --------------------------------------------------------------- |
| `itemValues`                                                       | Each item's value, in order                                     |
| `openValues`                                                       | The open items' values, in order                                |
| `titles`                                                           | Each trigger's text, in order                                   |
| `item(value)`, `header(value)`, `trigger(value)`, `content(value)` | An item's parts                                                 |
| `title(value)`                                                     | An item's trigger text                                          |
| `text(value)`                                                      | An item's content text, `''` while closed                       |
| `isOpen(value)`                                                    | Whether an item is open, from its trigger's `aria-expanded`     |
| `isShown(value)`                                                   | Whether an item's content shows: open, or still animating out   |
| `isDisabled(value)`                                                | Whether an item can't be opened or closed                       |
| `isLocked(value)`                                                  | Whether an open item's trigger can't close it (`aria-disabled`) |
| `orientation`                                                      | `vertical` or `horizontal`                                      |
| `focused`                                                          | The value of the item whose trigger has focus, or `null`        |
| `toggle(value)`, `open(value)`, `close(value)`                     | Clicks an item's trigger (`open` and `close` only when needed)  |
| `focus(value)`                                                     | Focuses an item's trigger                                       |
| `press(key)`                                                       | Presses a key on the focused trigger                            |

## Upstream

shadcn/ui's [Accordion](https://ui.shadcn.com/docs/components/radix/accordion), from
`apps/v4/registry/bases/radix/ui/accordion.tsx` at shadcn-ui/ui@8ab2771, in the Nova style.
The behaviour is Radix's Accordion, which also covers ember-primitives' (see
[the primitive](/primitives/accordion.md)).
