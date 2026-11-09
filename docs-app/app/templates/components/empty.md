# Empty

Use the Empty component to display an empty state.

<Example @name="empty-demo" @title="Empty" />

## Installation

```bash
pnpm add @ember-joinery/ember lucide
```

Import Joinery's CSS once (see [Installation](/getting-started/installation.md)), then the
component where you use it:

```gts
import { Empty } from '@ember-joinery/ember'
```

## Usage

```gts
import { FolderCode } from 'lucide'
import { Button, Empty, Icon } from '@ember-joinery/ember'

<template>
  <Empty as |e|>
    <e.Header>
      <e.Media @variant="icon">
        <Icon @icon={{FolderCode}} />
      </e.Media>
      <e.Title>No data</e.Title>
      <e.Description>No data found</e.Description>
    </e.Header>
    <e.Content>
      <Button>Add data</Button>
    </e.Content>
  </Empty>
</template>
```

## Composition

Use the following composition to build an `Empty` state. Its parts are yielded (`e.Header`), so
they need no import of their own:

```text
Empty
├── e.Header
│   ├── e.Media
│   ├── e.Title
│   └── e.Description
└── e.Content
```

## Outline

Use the `border` utility class to create an outline empty state. The empty state's border is
already dashed, with no width, so a width is all it needs; without Tailwind, set
`border-width: 1px` in your own CSS.

<Example @name="empty-outline" @title="Outline" />

## Background

Use the `bg-*` and `bg-gradient-*` utilities to add a background to the empty state.

<Example @name="empty-background" @title="Background" />

## Avatar

Use `e.Media` to display an avatar in the empty state. Upstream's example comes with Avatar.

## Avatar Group

Use `e.Media` to display an avatar group in the empty state. Upstream's example comes with
Avatar.

## InputGroup

You can add an `InputGroup` component to `e.Content`. Upstream's example, a search field with a
`Kbd` hint, comes with Input Group and Kbd.

## RTL

Joinery's styles use logical properties, so an empty state lays itself out right to left inside
any element with `dir="rtl"` (see [Direction](/primitives/direction.md)): a row of actions runs
from the right. Mirror an arrow with `rtl:rotate-*` in a Tailwind app, or your own
`[dir="rtl"]` rule.

<Example @name="empty-rtl" @title="RTL" @dir="rtl" />

## API Reference

### Empty

The main component of the empty state. It fills the space it is given (`flex-1`) and centres
what it holds.

| Argument | Type     | Default | What it does                                       |
| -------- | -------- | ------- | -------------------------------------------------- |
| `@as`    | tag name | `div`   | The tag to render                                  |
| `@name`  | `string` |         | Its name, for `EmptyHarness` (`data-test-jn-name`) |

It takes attributes on its element, `class` included.

### The parts

`Empty` yields its parts. Each takes `@as`, a tag to render instead of `div`
(`<e.Title @as="h2">`), and attributes, `class` included.

| Part            | What it is                                                           |
| --------------- | -------------------------------------------------------------------- |
| `e.Header`      | Wraps the empty media, title, and description                        |
| `e.Media`       | The media of the empty state, such as an icon, an image or an avatar |
| `e.Title`       | The title of the empty state, in the theme's heading font            |
| `e.Description` | The description of the empty state; a link in it is underlined       |
| `e.Content`     | The content of the empty state, such as a button, an input or a link |

`e.Media` also takes `@variant`:

| Argument   | Type                  | Default     | What it does                              |
| ---------- | --------------------- | ----------- | ----------------------------------------- |
| `@variant` | `"default" \| "icon"` | `"default"` | `icon` puts an icon on a small muted tile |

```gts
<e.Media @variant="icon">
  <Icon @icon={{Bell}} />
</e.Media>
```

### The part modifiers

Each part is yielded as a modifier too, to make an element or component of your own that part,
with the same classes and attributes: `{{e.header}}`, `{{e.title}}`, `{{e.description}}`,
`{{e.content}}`, and `{{e.media}}`, which takes `variant=`.

```gts
<Empty as |e|>
  <e.Header>
    <img src="/empty.svg" alt="" {{e.media}} />
    <h2 {{e.title}}>No results</h2>
  </e.Header>
</Empty>
```

### Data attributes

| Element         | Attribute           | Value                                                  |
| --------------- | ------------------- | ------------------------------------------------------ |
| `Empty`         | `class`             | `jn-empty`                                             |
|                 | `data-slot`         | `empty`                                                |
|                 | `data-test-jn`      | `empty`                                                |
|                 | `data-test-jn-name` | its `@name`                                            |
| `e.Header`      | `class`             | `jn-empty-header`                                      |
|                 | `data-slot`         | `empty-header`                                         |
| `e.Media`       | `class`             | `jn-empty-media jn-empty-media-<variant>`              |
|                 | `data-slot`         | `empty-icon`, as upstream's, whatever it holds         |
|                 | `data-variant`      | its `@variant`                                         |
| `e.Title`       | `class`             | `jn-empty-title jn-font-heading`                       |
|                 | `data-slot`         | `empty-title`                                          |
| `e.Description` | `class`             | `jn-empty-description`                                 |
|                 | `data-slot`         | `empty-description`                                    |
| `e.Content`     | `class`             | `jn-empty-content`                                     |
|                 | `data-slot`         | `empty-content`                                        |
| each part       | `data-test-jn-part` | `header`, `media`, `title`, `description` or `content` |

## Keyboard interactions

None of its own: an empty state doesn't take focus. Its buttons and links are in the tab order
as usual.

## Accessibility

- The media's icon is decorative (an `<Icon>` without `@label`): the title says what the state
  means. An image that adds something needs its own `alt`.
- The title is a `div` unless you give it `@as`; where the empty state fills a page or a
  section, make it a heading at the level it belongs (`<e.Title @as="h2">`).
- An icon-only button or link in the content needs `aria-label`.

## Testing

`EmptyHarness` from `@ember-joinery/test-support` finds an empty state (`data-test-jn="empty"`):

```ts
import { ButtonHarness, EmptyHarness } from '@ember-joinery/test-support'

const empty = new EmptyHarness('projects') // <Empty @name="projects">
assert.strictEqual(empty.title, 'No Projects Yet')
await empty.find(ButtonHarness).click()
```

| Member         | What it is                                                         |
| -------------- | ------------------------------------------------------------------ |
| `title`        | Its title's text, or `''`                                          |
| `description`  | Its first description's text, or `''`                              |
| `descriptions` | Every description's text, in order (one in the header, one below…) |
| `text`         | All the text it shows                                              |
| `mediaVariant` | The media's `@variant`, or `null` without media                    |
| `header`       | The header's element (throws when there is none)                   |
| `media`        | The media's element (throws when there is none)                    |
| `content`      | The content's element (throws when there is none)                  |

## Upstream

shadcn/ui's [Empty](https://ui.shadcn.com/docs/components/radix/empty), from
`apps/v4/registry/bases/radix/ui/empty.tsx` at shadcn-ui/ui@8ab2771, in the Nova style.
