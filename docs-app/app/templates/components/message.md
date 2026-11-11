# Message

Displays a message in a conversation, with optional avatar, header, footer, and alignment.

<Example @name="message-demo" @title="Message" />

The `Message` component lays out a single message in a conversation. It handles the avatar,
alignment, header, and footer around the message surface.

For AI apps, you can render reasoning steps, tool calls and assistant messages using the
`Message` component.

ui.shadcn.com shows these examples in the Rhea style; pick Rhea in an example's style switcher to
see them as there. Its avatars load images from the site's own `/avatars/` folder, which the guide
doesn't serve, so here each shows its initials, as an avatar does when its image fails.

## Installation

```bash
pnpm add @ember-joinery/ember
```

Import Joinery's CSS once (see [Installation](/getting-started/installation.md)), then the
components where you use them:

```gts
import { Avatar, Bubble, Message } from '@ember-joinery/ember'
```

## Usage

```gts
<Message as |m|>
  <m.Avatar>
    <Avatar as |a|>
      <a.Image @src="https://github.com/shadcn.png" alt="@shadcn" />
      <a.Fallback>CN</a.Fallback>
    </Avatar>
  </m.Avatar>
  <m.Content>
    <Bubble as |b|>
      <b.Content>How can I help you today?</b.Content>
    </Bubble>
  </m.Content>
</Message>
```

**Note:** `Message` owns the row layout: avatar, alignment, header, and footer. Render the
visible message surface inside it with [`Bubble`](/components/bubble.md). For the scroll
container around a conversation, use [`MessageScroller`](/components/message-scroller.md).

## Composition

Use the following composition to build a message:

```text
Message
├── m.Avatar
└── m.Content
    ├── m.Header
    ├── Bubble
    └── m.Footer
```

Use `MessageGroup` to stack consecutive messages from the same sender:

```text
MessageGroup
├── Message
└── Message
```

## Features

- Start and end alignment for sender and receiver rows via the `@align` argument
- Avatar slot that anchors to the bottom of the message and stays clear of the footer
- Header and footer slots for sender names, status, and message actions
- Footer follows the message side; actions stay aligned on `@align="end"` rows
- Group wrapper for stacking consecutive messages from the same sender
- Customizable styling through `class` on every part

## Avatar

Use the `Avatar` part to render an avatar next to the message. Set `@align="end"` on the message
to align the avatar to the end of the message.

<Example @name="message-avatar" @title="Avatar" />

| `@align` | Description                                         |
| -------- | --------------------------------------------------- |
| `start`  | Align the message to the start of the conversation. |
| `end`    | Align the message to the end of the conversation.   |

## Group

Use `MessageGroup` to stack consecutive messages from the same sender. Render an empty `Avatar`
part (`<m.Avatar />`) on the earlier messages to keep them aligned with the avatar on the last
one.

<Example @name="message-group" @title="Group" />

## Header and Footer

Use the `Header` part for a sender name and the `Footer` part for metadata such as a delivery or
read status.

<Example @name="message-header-footer" @title="Header and Footer" />

## Actions

Place message-level actions in the `Footer` part, such as copy, retry, or feedback buttons.

<Example @name="message-actions" @title="Actions" />

## Attachment

<Example @name="message-attachment" @title="Attachment" />

## API Reference

### Message

The message row wrapper. It is a layout, with no role of its own: the content you place inside
it carries the meaning.

| Argument | Type               | Default   | What it does                                         |
| -------- | ------------------ | --------- | ---------------------------------------------------- |
| `@align` | `"start" \| "end"` | `"start"` | The alignment of the message in the conversation     |
| `@as`    | tag name           | `div`     | The tag to render, such as `li` in a list of rows    |
| `@name`  | `string`           |           | Its name, for `MessageHarness` (`data-test-jn-name`) |

It yields its parts, each as a component (`m.Footer`) and as a modifier for your own element
(`<p {{m.footer}}>`): `Avatar`, `Content`, `Header` and `Footer`. Each takes `@as`, and
attributes.

### MessageGroup

Groups consecutive messages from the same sender. It takes `@as` and `@name`, for
`MessageGroupHarness`.

### Avatar

The avatar slot, aligned to the bottom of the message. When the message has a `Footer`, the
avatar shifts up to stay aligned with the message surface instead of the footer. Left empty, it
keeps its width, so a message lines up with the next one's avatar.

### Content

Wraps the header, message surface, and footer, in a column. In an `@align="end"` message, each
part in it (the header too) moves to the end.

### Header

Displays content above the message, such as a sender name, in muted small text level with the
bubble's text.

### Footer

Displays content below the message, such as status or actions. Aligns to the message side.

Beside a `ghost` bubble (or any part with `data-variant="ghost"`, such as a ghost Button), the
header and footer drop their inline padding, so they line up with the unframed text.

### Data attributes

| Part         | `class`                       | `data-slot`       | `data-test-jn-part`              |
| ------------ | ----------------------------- | ----------------- | -------------------------------- |
| Message      | `jn-message`, `group/message` | `message`         | (`data-test-jn="message"`)       |
| Avatar       | `jn-message-avatar`           | `message-avatar`  | `avatar`                         |
| Content      | `jn-message-content`          | `message-content` | `content`                        |
| Header       | `jn-message-header`           | `message-header`  | `header`                         |
| Footer       | `jn-message-footer`           | `message-footer`  | `footer`                         |
| MessageGroup | `jn-message-group`            | `message-group`   | (`data-test-jn="message-group"`) |

The message also has `data-align`.

## Keyboard interactions

A message isn't focusable; the controls inside it (its footer's buttons, a bubble that is a
button or a link) are, in the tab order.

## Accessibility

`Message` is a presentational layout wrapper. Accessibility comes from the content you place
inside it.

### Label icon-only actions

Action buttons in the `Footer` part are usually icon-only, so give each one an `aria-label`.

```gts
<m.Footer>
  <Button @variant="ghost" @size="icon" aria-label="Copy">
    <Icon @icon={{Copy}} />
  </Button>
</m.Footer>
```

### Status updates

For in-progress messages, use a [`Marker`](/components/marker.md) with `role="status"` so
assistive tech announces the update as it appears.

```gts
<Message as |m|>
  <Marker role="status" as |mk|>
    <mk.Icon>
      <Spinner />
    </mk.Icon>
    <mk.Content>Checking the logs...</mk.Content>
  </Marker>
</Message>
```

### Avatars

The avatars' initials keep upstream's colours, which fall short of WCAG AA's contrast; the
[Avatar](/components/avatar.md) page says so, and how an app can darken them.

## Testing

`MessageHarness` from `@ember-joinery/test-support` drives a `<Message>`, and
`MessageGroupHarness` a `<MessageGroup>`:

```ts
import { MessageHarness } from '@ember-joinery/test-support'

const reply = new MessageHarness('reply') // <Message @name="reply">
assert.strictEqual(reply.align, 'end')
assert.strictEqual(reply.footerText, 'Delivered')
assert.strictEqual(reply.bubbles[0]!.text, "It's a one-line change.")
```

| `MessageHarness`                        | What it is                                                       |
| --------------------------------------- | ---------------------------------------------------------------- |
| `text`                                  | All the text it shows                                            |
| `align`                                 | Its `@align`                                                     |
| `avatar`, `content`, `header`, `footer` | Each part; throws without it                                     |
| `hasAvatar`                             | Whether it has an avatar slot, even an empty one                 |
| `headerText`                            | The header's text, or `''`                                       |
| `footerText`                            | The footer's text, or `''`                                       |
| `bubbles`                               | A [`BubbleHarness`](/components/bubble.md) for each bubble in it |

| `MessageGroupHarness` | What it is                                    |
| --------------------- | --------------------------------------------- |
| `messages`            | A `MessageHarness` for each message, in order |

## Upstream

shadcn/ui's [Message](https://ui.shadcn.com/docs/components/radix/message), from
`apps/v4/registry/bases/radix/ui/message.tsx` at shadcn-ui/ui@8ab2771, shown in the Rhea style.
