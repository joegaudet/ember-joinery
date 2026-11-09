# Card

Displays a card with header, content, and footer.

<Example @name="card-demo" @title="Card" />

## Installation

```bash
pnpm add @ember-joinery/ember
```

Import Joinery's CSS once (see [Installation](/getting-started/installation.md)), then the
component where you use it:

```gts
import { Card } from '@ember-joinery/ember'
```

## Usage

```gts
<Card as |c|>
  <c.Header>
    <c.Title>Card Title</c.Title>
    <c.Description>Card Description</c.Description>
    <c.Action>Card Action</c.Action>
  </c.Header>
  <c.Content>
    <p>Card Content</p>
  </c.Content>
  <c.Footer>
    <p>Card Footer</p>
  </c.Footer>
</Card>
```

## Composition

Use the following composition to build a `Card`. Its parts are yielded (`c.Header`), so they
need no import of their own:

```text
Card
├── c.Header
│   ├── c.Title
│   ├── c.Description
│   └── c.Action
├── c.Content
└── c.Footer
```

## Size

Use `@size="sm"` to set the size of the card to small. The small size variant uses smaller
spacing.

<Example @name="card-small" @title="Size" />

## Spacing

In addition to `@size`, you can use the `--card-spacing` CSS variable to control the spacing
between sections and the inset of card parts. In a Tailwind app, set it with an arbitrary
property class, as upstream does; without Tailwind, set it in your own CSS or a `style`:

```gts
<Card class="[--card-spacing:--spacing(6)]" as |c|>…</Card>
<Card style="--card-spacing: 1.5rem" as |c|>…</Card>
```

Upstream's example switches the spacing with a Toggle Group around the login form; it comes
with Toggle Group.

Use negative margins with `-mx-(--card-spacing)` to make content go edge to edge while keeping
it aligned with the card inset. When the edge-to-edge content sits above a footer, use
`-mb-(--card-spacing)` on `c.Content` to remove the section gap.

<Example @name="card-edge-to-edge" @title="Edge to edge" />

A region that scrolls needs to take focus, so a keyboard can scroll it: Joinery's example gives
the terms `tabindex="0"`, which upstream's leaves out.

## Image

Add an image before the card header to create a card with an image: the card drops its top
padding, and the image takes the card's top corners.

<Example @name="card-image" @title="Image" />

## RTL

Joinery's styles use logical properties, so a card lays itself out right to left inside any
element with `dir="rtl"` (see [Direction](/primitives/direction.md)): the header's action moves
to the left.

<Example @name="card-rtl" @title="RTL" @dir="rtl" />

## API Reference

### Card

The `Card` component is the root container for card content.

| Argument | Type                | Default     | What it does                                      |
| -------- | ------------------- | ----------- | ------------------------------------------------- |
| `@size`  | `"default" \| "sm"` | `"default"` | How roomy it is                                   |
| `@as`    | tag name            | `div`       | The tag to render, such as `section` or `article` |
| `@name`  | `string`            |             | Its name, for `CardHarness` (`data-test-jn-name`) |

It takes attributes on its element, `class` and `style` included.

| CSS variable     | Default                     | What it does                                         |
| ---------------- | --------------------------- | ---------------------------------------------------- |
| `--card-spacing` | `1rem`; `0.75rem` with `sm` | The gap between sections, and the inset of each part |

### The parts

`Card` yields its parts. Each takes `@as`, a tag to render instead of `div`
(`<c.Title @as="h3">`), and attributes, `class` included.

| Part            | What it is                                                                     |
| --------------- | ------------------------------------------------------------------------------ |
| `c.Header`      | The header: a title, a description, and an optional action                     |
| `c.Title`       | The card title, in the theme's heading font                                    |
| `c.Description` | Helper text under the title                                                    |
| `c.Action`      | Content in the top inline-end of the header (for example, a button or a badge) |
| `c.Content`     | The main card body                                                             |
| `c.Footer`      | Actions and secondary content at the bottom of the card                        |

### The part modifiers

Each part is yielded as a modifier too, to make an element or component of your own that part,
with the same classes and attributes: `{{c.header}}`, `{{c.title}}`, `{{c.description}}`,
`{{c.action}}`, `{{c.content}}` and `{{c.footer}}`.

```gts
<Card as |c|>
  <c.Header>
    <LinkTo @route="event" {{c.title}}>Design systems meetup</LinkTo>
  </c.Header>
</Card>
```

### Data attributes

| Element         | Attribute           | Value                                                             |
| --------------- | ------------------- | ----------------------------------------------------------------- |
| `Card`          | `class`             | `jn-card`, `group/card`                                           |
|                 | `data-slot`         | `card`                                                            |
|                 | `data-size`         | its `@size`                                                       |
|                 | `data-test-jn`      | `card`                                                            |
|                 | `data-test-jn-name` | its `@name`                                                       |
| `c.Header`      | `class`             | `jn-card-header`, `group/card-header`                             |
|                 | `data-slot`         | `card-header`                                                     |
| `c.Title`       | `class`             | `jn-card-title jn-font-heading`                                   |
|                 | `data-slot`         | `card-title`                                                      |
| `c.Description` | `class`             | `jn-card-description`                                             |
|                 | `data-slot`         | `card-description`                                                |
| `c.Action`      | `class`             | `jn-card-action`                                                  |
|                 | `data-slot`         | `card-action`                                                     |
| `c.Content`     | `class`             | `jn-card-content`                                                 |
|                 | `data-slot`         | `card-content`                                                    |
| `c.Footer`      | `class`             | `jn-card-footer`                                                  |
|                 | `data-slot`         | `card-footer`                                                     |
| each part       | `data-test-jn-part` | `header`, `title`, `description`, `action`, `content` or `footer` |

## Keyboard interactions

None of its own: a card doesn't take focus. What is inside it, such as a footer's buttons, is in
the tab order as usual.

## Accessibility

- A card is a `div` with no role, as upstream's. Where it stands for a section of the page,
  give it `@as="section"` or `@as="article"` and a heading for its title
  (`<c.Title @as="h3">`), so a screen reader can find it.
- The title is a `div` unless you give it `@as`; for a page with an outline, make it the
  heading level it belongs at.

## Testing

`CardHarness` from `@ember-joinery/test-support` finds a card (`data-test-jn="card"`). A page
object can extend it and declare what the card holds with `@child`:

```ts
import { ButtonHarness, CardHarness, child } from '@ember-joinery/test-support'

class TermsCard extends CardHarness {
  static named = 'terms' // <Card @name="terms">; leave it out for the first card
  @child(ButtonHarness, { index: 0 }) declare decline: ButtonHarness
  @child(ButtonHarness, { index: 1 }) declare accept: ButtonHarness
}

const terms = new TermsCard()
assert.strictEqual(terms.title, 'Terms of Service')
await terms.accept.click()
```

The [edge-to-edge example](#spacing)'s Test tab has the whole of it.

| Member        | What it is                                              |
| ------------- | ------------------------------------------------------- |
| `title`       | Its title's text, or `''`                               |
| `description` | Its description's text, or `''`                         |
| `text`        | All the text it shows                                   |
| `size`        | Its `@size`                                             |
| `header`      | The header's element (throws when there is none)        |
| `action`      | The header action's element (throws when there is none) |
| `content`     | The content's element (throws when there is none)       |
| `footer`      | The footer's element (throws when there is none)        |

## Upstream

shadcn/ui's [Card](https://ui.shadcn.com/docs/components/radix/card), from
`apps/v4/registry/bases/radix/ui/card.tsx` at shadcn-ui/ui@8ab2771, in the Nova style.
