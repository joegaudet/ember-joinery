# Bubble

Displays conversational content in a message bubble. Supports variants, alignment, grouping,
reactions, and collapsible content.

<Example @name="bubble-demo" @title="Bubble" />

The `Bubble` component displays framed conversational content. Use it for chat text, short
structured output, quoted replies, suggestions, and reactions.

For full-featured chat interfaces, use the [`Message`](/components/message.md) component.
`Bubble` is intentionally scoped to the bubble surface. Place avatars, names, timestamps,
metadata, and message-level actions in [`Message`](/components/message.md).

ui.shadcn.com shows these examples in the Rhea style; pick Rhea in an example's style switcher to
see them as there.

## Installation

```bash
pnpm add @ember-joinery/ember
```

Import Joinery's CSS once (see [Installation](/getting-started/installation.md)), then the
components where you use them:

```gts
import { Bubble, BubbleGroup } from '@ember-joinery/ember'
```

## Usage

```gts
<Bubble as |b|>
  <b.Content>
    I checked the registry output and removed the stale route.
  </b.Content>
  <b.Reactions role="img" aria-label="Reaction: thumbs up">
    <span>👍</span>
  </b.Reactions>
</Bubble>
```

## Composition

Use the following composition to build a bubble:

```text
Bubble
├── b.Content
└── b.Reactions
```

Use `BubbleGroup` to group consecutive bubbles from the same sender:

```text
BubbleGroup
├── Bubble
│   └── b.Content
└── Bubble
    └── b.Content
```

## Features

- Seven visual variants, from a strong primary bubble to unframed ghost content
- Start and end alignment for sender and receiver bubbles
- Reactions that anchor to the bubble edge with configurable side and alignment
- Bubbles size to their content, up to 80% of the container width
- Content as a link or a button, through `@as` or the `content` modifier
- Customizable styling through `class` on every part

## Variants

Use `@variant` to change the visual treatment of the bubble.

<Example @name="bubble-variants" @title="Variants" />

| `@variant`    | Description                                            |
| ------------- | ------------------------------------------------------ |
| `default`     | A strong primary bubble, usually for the current user. |
| `secondary`   | The standard neutral bubble for conversation content.  |
| `muted`       | A lower-emphasis bubble for quiet supporting content.  |
| `tinted`      | A subtle primary-tinted bubble.                        |
| `outline`     | A bordered bubble for secondary or rich content.       |
| `ghost`       | Unframed content for assistant text or rich content.   |
| `destructive` | A destructive bubble for error or failed actions.      |

A bubble sizes to its content, up to 80% of the container width. The `ghost` variant removes the
max-width so assistant text and rich content can span the full row.

Upstream renders the ghost bubble's text with its site's Markdown component (Streamdown). Joinery
has no Markdown renderer, so the example writes out the HTML it renders.

## Alignment

Use `@align` on `Bubble` to align the bubble to the start or end of the conversation.

<Example @name="bubble-alignment" @title="Alignment" />

| `@align` | Description                                        |
| -------- | -------------------------------------------------- |
| `start`  | Align the bubble to the start of the conversation. |
| `end`    | Align the bubble to the end of the conversation.   |

**Note:** When building chat interfaces, you probably want to use alignment on the
[`Message`](/components/message.md) component itself, not the `Bubble` component: a message's
`@align="end"` moves every bubble in it to the end.

## Bubble Group

Use `BubbleGroup` to group consecutive bubbles from the same sender. Note the `@align` argument
should be set on the `Bubble` component itself, not the `BubbleGroup` component.

```text
BubbleGroup
├── Bubble
│   └── b.Content
└── Bubble
    └── b.Content
```

<Example @name="bubble-group-demo" @title="Bubble Group" />

## Links and Buttons

Upstream's `asChild` on `BubbleContent` turns a bubble into a link or button. In Joinery, give
the `Content` part `@as`, or put its modifier on your own element or component, such as
`LinkTo`.

<Example @name="bubble-link-button" @title="Links and Buttons" />

```gts
import { on } from '@ember/modifier'
import { Bubble } from '@ember-joinery/ember'

<template>
  <Bubble @variant="muted" as |b|>
    <b.Content @as="button" {{on "click" this.reply}}>Click here</b.Content>
  </Bubble>
</template>
```

```gts
<Bubble @variant="muted" as |b|>
  <LinkTo @route="help" {{b.content}}>Open the help center</LinkTo>
</Bubble>
```

## Reactions

Use the `Reactions` part for bubble reactions. You can use it to display reactions or quick
action buttons. Use `@side` and `@align` to position the row: `@side="top"` anchors it to the
upper edge. Reactions overlap the bubble edge, so leave vertical space between rows; the examples
below use a larger `gap` for this reason.

<Example @name="bubble-reactions" @title="Reactions" />

## Show More / Collapsible

Long bubble content can be composed with [`Collapsible`](/components/collapsible.md) to allow
for a show more or show less interaction. Use the collapsible's `trigger` modifier on a Button to
toggle the content.

<Example @name="bubble-collapsible" @title="Show More / Collapsible" />

Upstream puts `whitespace-pre-line` on the bubble's content. Joinery's example puts it on the
text alone: Glimmer keeps the whitespace between a template's elements, which that class would
show as blank lines. It also makes the text the collapsible's `Content` (with `@forceMount`, so
the preview shows while closed), so the trigger's `aria-controls` names an element, as an
accessible disclosure needs.

## Tooltip

Wrap a bubble's control in a [`Tooltip`](/components/tooltip.md) to reveal metadata on hover,
such as when a message was read.

<Example @name="bubble-tooltip" @title="Tooltip" />

## Popover

Pair a bubble with a [`Popover`](/components/popover.md) to surface more information on demand,
such as the full error message for a failed action.

<Example @name="bubble-popover" @title="Popover" />

## API Reference

### Bubble

The root bubble wrapper.

| Argument   | Type                                                                                       | Default     | What it does                                        |
| ---------- | ------------------------------------------------------------------------------------------ | ----------- | --------------------------------------------------- |
| `@variant` | `"default" \| "secondary" \| "muted" \| "tinted" \| "outline" \| "ghost" \| "destructive"` | `"default"` | The bubble visual treatment                         |
| `@align`   | `"start" \| "end"`                                                                         | `"start"`   | The inline alignment of the bubble                  |
| `@as`      | tag name                                                                                   | `div`       | The tag to render                                   |
| `@name`    | `string`                                                                                   |             | Its name, for `BubbleHarness` (`data-test-jn-name`) |

It yields its parts, each as a component (`b.Content`) and as a modifier for your own element
(`<LinkTo {{b.content}}>`): `Content` and `Reactions`.

### Content

The bubble content wrapper: the framed surface.

| Argument | Type     | Default | What it does                                                        |
| -------- | -------- | ------- | ------------------------------------------------------------------- |
| `@as`    | tag name | `div`   | The tag to render: `button` or `a` (upstream's `asChild`, for tags) |

As a button or a link, it starts its text at the inline start, shows a focus ring, and takes a
hover colour from the variant.

### Reactions

Displays overlapped reactions for a bubble. The modifier takes `side=` and `align=`.

| Argument | Type                | Default    | What it does                                   |
| -------- | ------------------- | ---------- | ---------------------------------------------- |
| `@side`  | `"top" \| "bottom"` | `"bottom"` | The side of the bubble to anchor the reactions |
| `@align` | `"start" \| "end"`  | `"end"`    | The inline alignment of the reactions          |
| `@as`    | tag name            | `div`      | The tag to render                              |

### BubbleGroup

Groups consecutive bubbles from the same sender. It takes `@as` and `@name`, for
`BubbleGroupHarness`.

### Data attributes

| Part        | `class`                                                                                 | `data-slot`        | `data-test-jn-part`             |
| ----------- | --------------------------------------------------------------------------------------- | ------------------ | ------------------------------- |
| Bubble      | `jn-bubble jn-bubble-variant-<variant>`, `group/bubble`                                 | `bubble`           | (`data-test-jn="bubble"`)       |
| Content     | `jn-bubble-content`                                                                     | `bubble-content`   | `content`                       |
| Reactions   | `jn-bubble-reactions jn-bubble-reactions-side-<side> jn-bubble-reactions-align-<align>` | `bubble-reactions` | `reactions`                     |
| BubbleGroup | `jn-bubble-group`                                                                       | `bubble-group`     | (`data-test-jn="bubble-group"`) |

The bubble also has `data-variant` and `data-align`, and the reactions `data-side` and
`data-align`.

## Keyboard interactions

A bubble isn't focusable. Its content is when it is a button or a link (`@as="button"`, `@as="a"`
or the `content` modifier on a `LinkTo`): it is in the tab order, `Enter` follows a link, and
`Enter` and `Space` press a button, as native elements do. So are the controls in its reactions.

## Accessibility

`Bubble` renders the presentational message surface. Keep conversation-level semantics on the
surrounding container and follow the guidelines below.

### Labeling Reactions

Reactions render as a row of emoji. A screen reader reads each glyph with no context, and
counters like `+8` are announced as "plus eight". Group the row as a single image with a
descriptive `aria-label` so it announces once. `role="img"` also hides the individual emoji from
assistive tech, so no `aria-hidden` is needed.

```gts
<b.Reactions role="img" aria-label="Reactions: thumbs up, fire, and 8 more">
  <span>👍</span>
  <span>🔥</span>
  <span>+8</span>
</b.Reactions>
```

When reactions are interactive, render buttons instead and give icon-only buttons an
`aria-label`.

```gts
<b.Reactions>
  <Button aria-label="Thumbs up" @variant="secondary" @size="icon-xs">
    <Icon @icon={{ThumbsUp}} />
  </Button>
</b.Reactions>
```

### Interactive Bubbles

When a bubble is clickable, render its content as a real `<button>` or `<a>` (`@as`, or the
`content` modifier) so it is focusable and exposes the correct role. The content ships a visible
focus ring for interactive elements, and the accessible name comes from the bubble text. No
extra label is needed.

```gts
<Bubble @variant="muted" @align="end" as |b|>
  <b.Content @as="button" type="button" {{on "click" this.reply}}>
    I forgot my password
  </b.Content>
</Bubble>
```

### Meaning Beyond Color

Bubble variants signal role and tone with color. Pair them with text, alignment, or icons so
meaning is not conveyed by color alone. For a `destructive` bubble, keep the error context in the
message text rather than relying on the color treatment.

### Upstream's colours and AA

The destructive bubble's text keeps upstream's colours: `--destructive` on its own 10% tint,
about 4:1 in the light themes, under the 4.5:1 WCAG AA asks of its 14px text (the dark themes
pass). To meet AA, darken the text in your CSS, which wins over Joinery's:

```css
.jn-bubble-variant-destructive:not(.dark *) > .jn-bubble-content {
  color: color-mix(in oklab, var(--destructive), black 15%);
}
```

Upstream's collapsible example draws its Show more button `text-muted-foreground` on the muted
bubble's `--muted`, which falls short of AA too; for your own, use `text-foreground` there.

## Testing

`BubbleHarness` from `@ember-joinery/test-support` drives a `<Bubble>`, and `BubbleGroupHarness`
a `<BubbleGroup>`:

```ts
import { BubbleHarness } from '@ember-joinery/test-support'

const reply = new BubbleHarness('reply') // <Bubble @name="reply">
assert.strictEqual(reply.text, 'I forgot my password')
assert.true(reply.isInteractive)
await reply.click()
```

| `BubbleHarness`                   | What it is                                                  |
| --------------------------------- | ----------------------------------------------------------- |
| `text`                            | Its content's text, without the reactions                   |
| `variant`                         | Its `@variant`                                              |
| `align`                           | Its `@align`                                                |
| `content`, `reactions`            | Each part; throws without it                                |
| `hasReactions`                    | Whether it has reactions                                    |
| `reactionsLabel`                  | The reactions' `aria-label`, else their text; `''` without  |
| `reactionsSide`, `reactionsAlign` | The reactions' `@side` and `@align`, or `null` without them |
| `isInteractive`                   | Whether its content is a button or a link                   |
| `isFocused`                       | Whether its content has focus                               |
| `click()`                         | Clicks its content                                          |
| `focus()`                         | Focuses its content                                         |

| `BubbleGroupHarness` | What it is                                  |
| -------------------- | ------------------------------------------- |
| `bubbles`            | A `BubbleHarness` for each bubble, in order |

## Upstream

shadcn/ui's [Bubble](https://ui.shadcn.com/docs/components/radix/bubble), from
`apps/v4/registry/bases/radix/ui/bubble.tsx` at shadcn-ui/ui@8ab2771, shown in the Rhea style.
