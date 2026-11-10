# Message Scroller

A chat scroll container that anchors turns, opens saved transcripts, follows streamed responses,
loads history without jumping, and jumps to any message.

<Example @name="message-scroller-demo" @title="Message Scroller" />

ui.shadcn.com shows these examples in the Rhea style; pick Rhea in an example's style switcher to
see them as there. Their conversations are scripted, as upstream's are: `chat/scripted-chat.ts`
(shown with each example's source) ports the parts of `@shadcn/helpers`' `createChat()` and the
AI SDK's `useChat()` they use, and `chat/message-animated.gts` upstream's `MessageAnimated` row.

## What Makes a Great Streaming Chat Experience

Building a chat interface used to be simple. You create an inverted list with an input. Type a
message, it appends at the bottom. When a reply comes in, the list grows and scrolls. Done.

Streaming breaks that model. Messages arrive in chunks while you may still be reading,
scrolling, or looking somewhere else entirely.

Now the challenge is preserving the reader's place while the conversation keeps changing. Get
that wrong and the experience feels jumpy: people are pulled to the bottom, lose context, and
have to find their way back.

In practice, this comes down to scroll: when to follow, when to hold, and when to let the reader
decide. A great streaming chat should:

1. **Move only when the reader asked to move.** If someone is reading, don’t pull them somewhere
   else. Auto-scroll should never be the default.
2. **Follow only while they’re following.** If they’re at the live edge, keep the stream in
   view. If they scroll away, leave them there.
3. **Every interaction is a signal.** Scrolling is not the only one. Selecting text, using the
   keyboard, opening a link, or searching should all stop the interface from moving.
4. **Start a new turn near the top of the viewport.** This gives the new turn somewhere it can
   be read from the beginning.
5. **Then stream in the answer.** The answer should grow into the screen, not immediately push
   everything away.
6. **Keep part of the previous conversation in context.** The prompt and reply should stay
   visually connected, and enough of the previous turn should remain visible so the reader knows
   where they are.
7. **Let new content arrive offscreen.** The conversation can keep streaming without changing
   what the reader is looking at.
8. **Show what’s happening out of view.** Make it clear when a response is still streaming or
   when new messages have arrived.
9. **Make it easy to return to the latest reply.** A “Jump to latest” action should bring the
   reader back and resume following.
10. **Let people jump anywhere in the conversation.** Long threads need message links, search,
    unread markers, and direct navigation.
11. **Reopen where the reader left off.** A saved conversation should open at the last
    meaningful turn. Often this is the last user message. Not the absolute bottom.
12. **Keep the reader’s place when layout changes.** Images load. Markdown expands. Code blocks
    render. Older messages appear above. None of that should make the reader lose their place.
13. **Handle interruptions without stealing position.** Stopping, retrying, regenerating,
    branching, or errors should not unexpectedly move the conversation.
14. **Stay responsive in long threads.** Streaming text, markdown, code, images, and long
    history should still feel responsive.
15. **Be accessible without the noise.** Keep the transcript navigable, preserve keyboard focus,
    and announce important events at a comfortable pace.

**Never move the reader against their intent.**

## MessageScroller

MessageScroller is a chat transcript scroller built for these behaviors.
`MessageScrollerProvider` owns the scroll state and transcript-row behavior: opening position,
streamed output, new-turn anchoring, prepended history, visibility, and scroll controls.
`MessageScroller` (the provider's `s.Root`) is the styled frame that renders inside it.

MessageScroller is scoped to the scroll viewport. It does not own messages, AI state,
transport, persistence, branching, or model state. Your product code stays focused on composing
messages, markers, tools, attachments, and prompt inputs.

It gives you the scroll behavior that chat needs, without taking over the rest of the chat UI.
And it stays fast, even in long conversations with rich markdown.

## Installation

```bash
pnpm add @ember-joinery/ember
```

Import Joinery's CSS once (see [Installation](/getting-started/installation.md)), then the
components where you use them:

```gts
import { Message, MessageScrollerProvider } from '@ember-joinery/ember'
```

## Usage

```gts
<MessageScrollerProvider as |s|>
  <s.Root>
    <s.Viewport>
      <s.Content>
        {{#each this.messages key="id" as |message|}}
          <s.Item @messageId={{message.id}} @scrollAnchor={{this.isUser message}}>
            <Message …>…</Message>
          </s.Item>
        {{/each}}
      </s.Content>
    </s.Viewport>
    <s.Button />
  </s.Root>
</MessageScrollerProvider>
```

The provider yields its parts (`s.Root` is upstream's `MessageScroller`, and so on), the commands
(`s.scrollToMessage`, `s.scrollToEnd`, `s.scrollToStart`) and the scroll state
(`s.scrollable`). The parts are exported on their own too (`MessageScroller`,
`MessageScrollerViewport`, `MessageScrollerContent`, `MessageScrollerItem`,
`MessageScrollerButton`), for a component of yours that renders a row or a control: they find
the provider above them, as `<MessageScrollerConsumer as |s|>` does for anything else.

`MessageScroller` fills its parent, so place it inside a height-constrained container.

```gts
<div class="flex h-screen flex-col">
  <MessageScrollerProvider as |s|>
    <s.Root class="flex-1">{{! transcript }}</s.Root>
  </MessageScrollerProvider>
</div>
```

## Composition

```gts
<MessageScrollerProvider as |s|>
  <s.Root>
    <s.Viewport>
      <s.Content>
        <s.Item>
          {{! a message, marker, or row }}
        </s.Item>
        <s.Item />
        <s.Item />
      </s.Content>
    </s.Viewport>
    <s.Button />
  </s.Root>
</MessageScrollerProvider>
```

- **`MessageScrollerProvider`** — the headless root. Owns scroll state and the behavior
  arguments for opening position, auto-scroll, anchoring, scroll commands, and visibility
  tracking.
- **`MessageScroller`** (`s.Root`) — the styled frame. Lays out the viewport, content, and
  controls inside the provider.
- **`MessageScrollerViewport`** (`s.Viewport`) — the scrollable element. Receives native scroll
  events and preserves the visible row when older messages are prepended.
- **`MessageScrollerContent`** (`s.Content`) — the transcript container. Holds the rows and
  provides the live-region defaults for new messages.
- **`MessageScrollerItem`** (`s.Item`) — the transcript row boundary. Wrap every direct child
  of the content so the scroller can measure, anchor, preserve position, track visibility, and
  jump to it. An item can be a message, marker, typing indicator, separator, join/leave event,
  or "load earlier" row.
- **`MessageScrollerButton`** (`s.Button`) — the scroll control. Scrolls to the start or end of
  the transcript and is inert until there is content in its direction.

## Core Concepts

### Anchoring Turns

A turn is the part of the conversation that starts a new exchange. In a simple AI chat, that is
usually the user's message and the assistant reply that follows.

An anchor is the row the viewport should treat as the start of that turn. Mark that row with
`@scrollAnchor`. When a new anchor is appended, the viewport moves it near the top and keeps a
peek of the previous item above it, so the new turn does not feel detached from its context.

```gts
{{! This tells the scroller to anchor the user's message for the next turn. }}
<s.Item @messageId={{message.id}} @scrollAnchor={{this.isUser message}} />
```

Scroll anchors are not tied to message role. You can turn any row into an anchor: a user
message, a system marker, a handoff event, or anything else that starts a meaningful turn.
`MessageScroller` only needs to know which row should anchor the viewport.

In the following example, the user's message is anchored. When you send a new message, the
viewport anchors it near the top and appends the assistant reply below it. Toggle the anchor to
the assistant's message to see the difference.

<Example @name="message-scroller-anchoring" @title="Anchoring Turns" />

### Group Chat

In a group chat, the turn boundary is more specific than "the user message". It is often the
message that asks the model to respond, or a marker like "Marcus joined the chat". Typing
indicators and history controls usually should not anchor.

Because anchoring is role-independent, you can anchor a marker just as easily as a message.

```gts
<s.Item @messageId="marcus-joined" @scrollAnchor={{true}}>
  <Marker @variant="separator" as |m|>
    <m.Content>Marcus joined the chat</m.Content>
  </Marker>
</s.Item>
```

<Example @name="message-scroller-group-chat" @title="Group Chat" />

### Keeping Context Visible

When a new turn starts, it should still feel like part of the same continuous thread.
`@scrollPreviousItemPeek` keeps a slice of the previous item visible above the anchor, so the
reader keeps their context instead of feeling like the conversation restarted on a blank page.

```gts
{{! Keep 64px of the previous turn visible above the newly anchored row. }}
<MessageScrollerProvider @scrollPreviousItemPeek={{64}} as |s|>
  <s.Root>{{! anchored turns }}</s.Root>
</MessageScrollerProvider>
```

Adjust the peek amount in the example below to see how it affects the conversation.

<Example @name="message-scroller-previous-context" @title="Keeping Context Visible" />

### Following the Live Edge

When the reader is at the live edge, either because they stayed there or returned there,
`@autoScroll` keeps streamed replies in view as they grow. Scrolling away from the live edge
releases the view, whether by wheel, touch, keyboard scroll keys, or dragging the scrollbar. An
explicit message jump releases it too. New chunks can then arrive without moving the reader.

`@autoScroll` composes with turn anchoring. When a new turn anchors near the top, the view stays
put while the reply streams into the room below it. Once the reply fills the viewport, the reader
is back at the live edge and follow-output takes over from the anchor.

```gts
<MessageScrollerProvider @autoScroll={{true}} as |s|>
  <s.Root>{{! streamed turns }}</s.Root>
</MessageScrollerProvider>
```

<Example @name="message-scroller-streaming" @title="Following the Live Edge" />

Calling `scrollToEnd`, or pressing the button, re-engages follow-output when `@autoScroll` is
enabled, so a reader who scrolled away can return to the live edge and keep following. The root
and viewport expose `data-autoscrolling` while that programmatic scroll to the latest message
runs, so you can conditionally apply styles during the transition.

### Opening Saved Threads

It can seem reasonable to reopen a saved thread at the absolute end of the transcript, but that
often drops the reader into the conversation without enough context. A better default is
`"last-anchor"`: show the last meaningful turn, like the user's latest message, with the reply
below it.

That gives the reader an immediate place in the thread. They can see what they asked, where the
answer starts, and continue from there without reconstructing the conversation from the bottom
edge.

```gts
<MessageScrollerProvider @defaultScrollPosition="last-anchor" as |s|>
  <s.Root>{{! transcript }}</s.Root>
</MessageScrollerProvider>
```

<Example @name="message-scroller-opening-position" @title="Opening Saved Threads" />

`"last-anchor"` is keyed on `@scrollAnchor`, not message role. If no anchor exists, or the last
anchored turn already fits in the viewport, it falls back to `"end"`.

Use `"start"` when you want to resume at the beginning of a conversation, or `"end"` when the
absolute latest message is the right place to land.

### Avoiding a Flash on Reload

A scroll container always opens at the top. HTML has no way to set `scrollTop`, so a
server-rendered transcript shows the oldest messages first. After JavaScript runs,
`@defaultScrollPosition` moves the view, and you see a jump.

When `@defaultScrollPosition` is `"end"` or `"last-anchor"`, the viewport has
`data-pending-scroll` until that position is applied. The styled viewport stays hidden while the
attribute is present, so you see the frame instead of the jump. `"start"` does not need this.

If you want `"end"` visible on first paint, add an inline script right after the viewport. Give
the viewport an `id`, scroll it to the bottom, and remove `data-pending-scroll`:

```html
<script>
  ;(function () {
    var viewport = document.getElementById('messages')
    if (!viewport) {
      return
    }
    viewport.scrollTop = viewport.scrollHeight
    viewport.removeAttribute('data-pending-scroll')
  })()
</script>
```

Put the script in your page's server-rendered HTML, not in the scroller. It only works for
`"end"`, and only when the messages are already in the HTML. If you use a Content Security
Policy, give it a `nonce`.

Do not use this script with `"last-anchor"`. Skip it when messages load on the client.

### Loading Earlier Messages

Loading earlier messages should not move the conversation the reader is already looking at. When
older rows are prepended above the current transcript, the viewport preserves the visible row so
the reader stays in the same place while history loads above them.

This is enabled by default through the viewport's `@preserveScrollOnPrepend`.

<Example @name="message-scroller-load-history" @title="Loading Earlier Messages" />

Use stable `@messageId` values for message rows. That gives the scroller a specific row to
preserve instead of guessing from whichever pixel happens to sit at the viewport edge.

### Animating New Messages

A row can be animated directly. Keep `@messageId` and `@scrollAnchor` on it, and use transform
and opacity for the entrance: upstream wraps its item with motion; here the example's row plays
the same keyframes with the Web Animations API (`element.animate()`) in a modifier on its
`MessageScrollerItem`.

A common chat pattern is to animate the user's message when it is sent, then let the assistant
reply stream into a regular row below it. Start the user row below its final position so it
feels like it rises from the live edge of the viewport.

<Example @name="message-scroller-animation" @title="Animating New Messages" />

Avoid animating height, margin, or padding for row entrances; those changes can fight the
scroller's positioning work. If the reader prefers reduced motion, skip the entrance animation
and keep the scroll behavior the same.

### Jumping to Messages

Search results, permalinks, outline items, and toolbar buttons often need to drive the transcript
from outside the message list. Use the commands the provider yields for those controls. Because
they come from `MessageScrollerProvider`, they work in any component inside the provider,
including controls rendered outside the `MessageScroller` frame.

```gts
<MessageScrollerProvider as |s|>
  <Button {{on "click" (fn s.scrollToMessage "intro" (hash behavior="smooth"))}}>Back to the start</Button>
  {{! s.scrollToEnd, s.scrollToStart }}
</MessageScrollerProvider>
```

<Example @name="message-scroller-commands" @title="Jumping to Messages" />

`scrollToMessage` targets the `@messageId` on an item, so rows that need to be addressable
should have stable ids. `scrollToMessage` returns `false` when the target is not mounted and
cannot be queued.

`scrollToMessage` can queue a target before items exist, which covers client-resolved permalinks
while the transcript mounts. After rows have mounted, a missing id returns `false` instead of
starting a guessed retry loop. A `true` result means the scroll ran or was queued, not that the
row is already in view.

### Tracking the Reader's Position

Use `s.Visibility` (upstream's `useMessageScrollerVisibility`) to track the reader's position in
the conversation. A common example is a table-of-contents or a jump menu that highlights the
current anchored turn.

```gts
<s.Visibility as |visibility|>
  {{visibility.currentAnchorId}}
  {{visibility.visibleMessageIds}}
</s.Visibility>
```

<Example @name="message-scroller-visibility" @title="Tracking the Reader's Position" />

`currentAnchorId` answers "where am I" by reporting the current anchored turn, and it stays set
after that anchor scrolls above the viewport. `visibleMessageIds` answers "what is on screen",
in document order.

Visibility is pay-for-what-you-use. Tracking only runs while an `s.Visibility` is rendered, and
rows need a `@messageId` to participate.

### Reading Scroll State

Use `s.scrollable` (upstream's `useMessageScrollerScrollable`) when you need scroll state in a
template or in JavaScript, such as a status indicator or a custom "jump to latest" control. It
reports which edges the viewport can still scroll toward; "at the start/end" is the negation
(`!start` / `!end`), and "scrollable at all" is `start || end`. For styling the scroller itself,
prefer the `data-scrollable` attribute.

```gts
{{#if s.scrollable.end}}New messages below{{/if}}
```

<Example @name="message-scroller-scrollable" @title="Reading Scroll State" />

## Performance

`MessageScroller` is ported from upstream's, which is benchmarked against large transcripts with
markdown and composed message rows.

Its performance goal is to keep the scroll hot path out of the templates: no re-render of
transcript rows, no forced layout on every scroll, and as little off-screen paint work as the
browser can avoid.

Scroll position, anchoring, and follow-output are tracked imperatively and mirrored onto the root
and viewport through `data-*` attributes, so scrolling and streaming do not re-render transcript
rows. Only `s.scrollable`, which changes when an edge is reached or left, and `s.Visibility`'s
state are tracked.

The styled `MessageScrollerItem` also ships with `content-visibility: auto` and
`contain-intrinsic-size`. Rows stay in the DOM for selection, copy, find-in-page, server
rendering, and assistive tech, but the browser can skip rendering work for rows far outside the
viewport.

Visibility tracking is pay-for-what-you-use. A jump menu or active turn indicator costs nothing
until an `s.Visibility` is rendered.

This is comfortable for the expected range of a chat transcript: hundreds to low thousands of
turns, including messages with markdown and composed components.

## Virtualization

Virtualization is intentionally left outside the primitive. `MessageScroller` renders real DOM
rows and stays fast well into the thousands of turns (see [Performance](#performance)), so most
transcripts never need it.

When a transcript is large enough to need virtualization, use the viewport as the scroll element
and let the virtualizer own the rows: give `s.Content` the virtualizer's sized box (`class="block
min-h-full"`, as upstream's TanStack Virtual example does) and render only the rows it asks for,
each absolutely placed.

## Accessibility

`MessageScroller` keeps the scroll container keyboard reachable and the transcript announceable
without forcing a specific message UI.

The viewport is a labelled, keyboard-focusable scroll region by default. It uses
`role="region"`, `aria-label="Messages"` (`@label`), and `tabindex="0"`, so keyboard users can
focus the transcript and scroll it directly.

The content marks the transcript as a live region with `role="log"` and
`aria-relevant="additions"`. New rows can be announced, but streamed text mutations do not have
to be announced token by token.

```gts
<s.Content aria-busy={{if this.isStreaming "true" "false"}}>
  {{! messages }}
</s.Content>
```

Pass `aria-busy` while a turn streams if announcements should wait for the completed message
row.

The button renders a real button. When there is nothing to scroll toward, it sets `inert`, uses
`tabindex="-1"`, and exposes `data-active="false"` so inactive scroll controls do not create
extra focus stops. Its label is `@label`, "Scroll to end" (or "Scroll to start") by default.

## Unstyled

The behavior in `MessageScroller` comes from `@ember-joinery/primitives/message-scroller`, as
upstream's comes from `@shadcn/react`. To use it directly with your own markup and styles, see
[Message Scroller](/primitives/message-scroller.md) under Primitives.

## API Reference

### MessageScrollerProvider

The headless root. It owns scroll state and the behavior arguments, and yields them to the parts
and the controls inside it. It renders no DOM of its own.

| Argument                  | Type                                | Default | What it does                                                                                                                                                                                                          |
| ------------------------- | ----------------------------------- | ------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `@autoScroll`             | `boolean`                           | `false` | Follow new content only while the reader is already at the live edge. Wheel, touch, keyboard scroll, and explicit jumps release it.                                                                                   |
| `@defaultScrollPosition`  | `"start" \| "end" \| "last-anchor"` | `"end"` | Opening position on the first render with rows, applied once. `"last-anchor"` opens at the last `@scrollAnchor` row and falls back to `"end"` when the turn fits or no anchor exists. See Avoiding a Flash on Reload. |
| `@scrollEdgeThreshold`    | `number`                            | `8`     | Distance from either edge that still counts as being at the start or end. Controls state attributes and scroll button visibility.                                                                                     |
| `@scrollMargin`           | `number`                            | `0`     | Margin applied to the aligned edge for `scrollToMessage`, visibility, and programmatic targets.                                                                                                                       |
| `@scrollPreviousItemPeek` | `number`                            | `64`    | Extra margin added to `@scrollMargin` when a newly appended `@scrollAnchor` item is positioned so part of the previous item stays visible.                                                                            |

It yields `s.Root`, `s.Viewport`, `s.Content`, `s.Item`, `s.Button` and `s.Visibility`, the
commands `s.scrollToMessage(messageId, options?)`, `s.scrollToEnd(options?)` and
`s.scrollToStart(options?)`, `s.scrollable` (`{ start, end }`) and `s.state`, the scroller
itself.

All commands return `false` when the command could not be applied. `scrollToStart` and
`scrollToEnd` return `false` only when the viewport is not rendered yet. `scrollToMessage`
returns `false` when the target is not mounted and cannot be queued. Their options:

| Option         | Type                                              | Default                        | What it does                                         |
| -------------- | ------------------------------------------------- | ------------------------------ | ---------------------------------------------------- |
| `align`        | `"start"` \| `"center"` \| `"end"` \| `"nearest"` | `"start"`                      | How a message target aligns in the viewport.         |
| `behavior`     | `ScrollBehavior`                                  | `"auto"`                       | Native scroll behavior for the command.              |
| `scrollMargin` | `number`                                          | the provider's `@scrollMargin` | Margin applied to the aligned edge for this command. |

### MessageScroller

The frame and layout container (`s.Root`). It fills its parent, so use it inside a
height-constrained layout, within a `MessageScrollerProvider`. It takes `@as` and `@name`, for
`MessageScrollerHarness`.

### MessageScrollerViewport

The scrollable viewport (`s.Viewport`).

| Argument                   | Type      | Default      | What it does                                                              |
| -------------------------- | --------- | ------------ | ------------------------------------------------------------------------- |
| `@preserveScrollOnPrepend` | `boolean` | `true`       | Keep the first visible message item stable when older rows are prepended. |
| `@label`                   | `string`  | `"Messages"` | Accessible name for the scrollable chat transcript.                       |
| `@as`                      | tag name  | `div`        | The tag to render.                                                        |

A `role`, `aria-label` or `tabindex` of your own overrides its defaults.

### MessageScrollerContent

The transcript content element (`s.Content`). Every direct child should be an item.

| Argument       | Type     | Default | What it does                                                            |
| -------------- | -------- | ------- | ----------------------------------------------------------------------- |
| `@spacerClass` | `string` |         | Class name for the internal spacer used to make room for anchored rows. |
| `@as`          | tag name | `div`   | The tag to render.                                                      |

It is `role="log"` and `aria-relevant="additions"`; give it `aria-busy` while a turn streams, if
needed.

### MessageScrollerItem

One transcript row (`s.Item`): a message, marker, typing row, separator, or load-more row.

| Argument        | Type      | Default | What it does                                                                   |
| --------------- | --------- | ------- | ------------------------------------------------------------------------------ |
| `@messageId`    | `string`  |         | Stable row id used by `scrollToMessage`, visibility, and prepend preservation. |
| `@scrollAnchor` | `boolean` | `false` | Marks this row as a turn boundary that can anchor newly appended turns.        |
| `@as`           | tag name  | `div`   | The tag to render.                                                             |

### MessageScrollerButton

A [Button](/components/button.md) that scrolls to the start or end of the transcript (`s.Button`).
It is inert and removed from the tab order when there is nothing to scroll toward.

| Argument     | Type               | Default                                    | What it does                                                            |
| ------------ | ------------------ | ------------------------------------------ | ----------------------------------------------------------------------- |
| `@direction` | `"start" \| "end"` | `"end"`                                    | Transcript edge the button scrolls toward.                              |
| `@behavior`  | `ScrollBehavior`   | `"smooth"`                                 | Native scroll behavior used when the button scrolls to its target edge. |
| `@variant`   | `Button` variant   | `"secondary"`                              | The button variant.                                                     |
| `@size`      | `Button` size      | `"icon-sm"`                                | The button size.                                                        |
| `@label`     | `string`           | `"Scroll to end"` (or `"Scroll to start"`) | Its accessible name, without a block.                                   |
| `@name`      | `string`           |                                            | Its name, for `ButtonHarness`.                                          |

Without a block, it shows an arrow (pointing up for `start`) and its label for assistive
technology.

### MessageScrollerVisibility

`s.Visibility` yields the reader's position while it is rendered: `currentAnchorId` (the current
anchored turn, based on the last `@scrollAnchor` item at or above the reading line) and
`visibleMessageIds` (the message ids intersecting the viewport, in document order). Filter
`visibleMessageIds` when you need a narrower outline, such as user messages, anchored turns, or
search hits.

### Data attributes

| Part     | `class`                                         | `data-slot`                 | Data attributes                                                 |
| -------- | ----------------------------------------------- | --------------------------- | --------------------------------------------------------------- |
| Root     | `jn-message-scroller`, `group/message-scroller` | `message-scroller`          | `data-scrollable`, `data-autoscrolling`, `data-pending-scroll`  |
| Viewport | `jn-message-scroller-viewport`                  | `message-scroller-viewport` | `data-scrollable`, `data-autoscrolling`, `data-pending-scroll`  |
| Content  | `jn-message-scroller-content`                   | `message-scroller-content`  |                                                                 |
| Item     | `jn-message-scroller-item`                      | `message-scroller-item`     | `data-message-id`, `data-scroll-anchor` (`"true"` \| `"false"`) |
| Button   | a Button's, and `jn-message-scroller-button`    | `message-scroller-button`   | `data-direction`, `data-active` (`"true"` \| `"false"`)         |

`data-scrollable` is `"start"`, `"end"`, `"start end"` or absent (query one with
`[data-scrollable~="end"]`); `data-autoscrolling` is present while the viewport scrolls itself to
the latest message; `data-pending-scroll` is present until the opening position (`"end"` or
`"last-anchor"`) is applied, or skipped for an empty transcript. The harness finds the root by
`data-test-jn="message-scroller"`, and its parts by `data-test-jn-part`: `viewport`, `content`,
`item` (with `data-test-jn-value`, its `@messageId`) and `button` (its direction).

## Keyboard interactions

| Key                                         | What it does                                                                           |
| ------------------------------------------- | -------------------------------------------------------------------------------------- |
| Tab                                         | Moves focus to the viewport, then into the transcript, then to an active scroll button |
| ArrowUp, ArrowDown, PageUp, PageDown, Space | Scroll the focused viewport, as the browser does, and release following                |
| Home, End                                   | Scroll to the start or the end, and release following                                  |
| Enter, Space (on the button)                | Scroll to its edge; with `@autoScroll`, following the end again                        |

## Testing

`MessageScrollerHarness` from `@ember-joinery/test-support` drives a `<MessageScroller>`
(`s.Root @name="chat"`). Its actions scroll as a reader does, and wait for the scroller to
settle:

```ts
import { MessageScrollerHarness } from '@ember-joinery/test-support'

const chat = new MessageScrollerHarness('chat')
assert.true(chat.isAtEnd)
await chat.scrollBy(-200) // the reader scrolls up: following lets go
assert.true(chat.isButtonActive())
await chat.clickButton() // jump to latest
assert.strictEqual(chat.itemTop('turn-3'), 64)
```

| `MessageScrollerHarness`                            | What it is                                                                |
| --------------------------------------------------- | ------------------------------------------------------------------------- |
| `viewport`, `content`, `label`                      | The viewport and the content; the viewport's accessible name              |
| `items`, `messageIds`, `anchorIds`, `item(id)`      | The rows, their `@messageId`s, the anchored ones, and one row             |
| `scrollTop`, `maxScrollTop`, `isAtStart`, `isAtEnd` | Where it is scrolled to, and how far it can go                            |
| `scrollable`, `canScrollToStart`, `canScrollToEnd`  | The edges it says it can scroll toward (`data-scrollable`)                |
| `isPendingScroll`, `isAutoscrolling`                | Its `data-pending-scroll` and `data-autoscrolling`                        |
| `itemTop(id)`, `isItemVisible(id)`, `visibleIds`    | Where a row is below the viewport's top, in CSS pixels; which rows show   |
| `button(direction)`, `isButtonActive(direction)`    | A scroll button, and whether it has somewhere to go                       |
| `clickButton(direction)`                            | Presses it and waits for the scroll                                       |
| `scrollTo(top)`, `scrollBy(delta)`                  | Scroll as a reader's wheel does                                           |
| `pressKey(key)`, `focus()`                          | A scroll key in the viewport, scrolling it as the browser would; focus it |
| `settle()`                                          | Waits for its frames, a smooth scroll and the observers' reports          |

## Upstream

shadcn/ui's [Message Scroller](https://ui.shadcn.com/docs/components/radix/message-scroller), from
`apps/v4/registry/bases/radix/ui/message-scroller.tsx` and `packages/react/src/message-scroller`
at shadcn-ui/ui@8ab2771, shown in the Rhea style.
