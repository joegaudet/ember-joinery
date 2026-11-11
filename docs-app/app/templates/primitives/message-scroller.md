# Message Scroller

A chat transcript's scroll container, headless: it anchors turns, opens saved transcripts,
follows streamed responses, loads history without jumping, and jumps to any message. It is
`@shadcn/react`'s `MessageScroller` (which shadcn's [Message Scroller](/components/message-scroller.md)
wraps), and owns all of the scroll behaviour, with no styles of its own.

<Example @name="message-scroller-headless" @title="A transcript with markup of your own" />

## Usage

```gts
import { MessageScrollerProvider } from '@ember-joinery/primitives/message-scroller'

<template>
  <MessageScrollerProvider @autoScroll={{true}} as |s|>
    <s.Root class="relative flex flex-1 flex-col overflow-hidden">
      <s.Viewport class="flex flex-1 flex-col overflow-y-auto">
        <s.Content class="flex flex-col gap-4 p-6">
          {{#each this.messages key="id" as |message|}}
            <s.Item @messageId={{message.id}} @scrollAnchor={{this.isUser message}}>
              {{! your message UI }}
            </s.Item>
          {{/each}}
        </s.Content>
      </s.Viewport>
      <s.Button class="absolute bottom-2 left-1/2 inert:opacity-0">Jump to latest</s.Button>
    </s.Root>
  </MessageScrollerProvider>
</template>
```

The parts are components of their own too (`MessageScrollerRoot`, `MessageScrollerViewport`,
`MessageScrollerContent`, `MessageScrollerItem`, `MessageScrollerButton`,
`MessageScrollerVisibility`), and `<MessageScrollerConsumer as |s|>` gives what the provider
yields to a component of yours that isn't handed it. They find the provider through the DOM, so
they can go anywhere inside it. The styled parts are the same, with upstream's classes.

| Styled component          | Unstyled part                                                           |
| ------------------------- | ----------------------------------------------------------------------- |
| `MessageScrollerProvider` | `MessageScrollerProvider` (from the primitives)                         |
| `MessageScroller`         | `MessageScrollerRoot`                                                   |
| `MessageScrollerViewport` | `MessageScrollerViewport`                                               |
| `MessageScrollerContent`  | `MessageScrollerContent`                                                |
| `MessageScrollerItem`     | `MessageScrollerItem`                                                   |
| `MessageScrollerButton`   | `MessageScrollerButton`, or `messageScrollerButton` on your own element |

### Avoiding a flash on reload

When `@defaultScrollPosition` is `"end"` or `"last-anchor"`, the viewport (and the root) has
`data-pending-scroll` until that position is applied. Hide the viewport while it is set, with
`visibility: hidden` so its layout still exists for the opening scroll. Scope the rule to the
viewport, so you don't hide the root:

```css
#messages[data-pending-scroll] {
  visibility: hidden;
}
```

### The button

`MessageScrollerButton` is a `<button>` (`@as` for another tag). Without a block it shows its
`@label`, "Scroll to end" (or "Scroll to start"). While there is nothing to scroll toward it is
`inert`, out of the tab order and `data-active="false"`; style that state with `inert:` or
`[data-active=false]`. A `tabindex` of your own comes back while it is active, and a click
listener of yours that comes before it (`{{on "click"}}` on the button) runs first and can stop
the scroll with `event.preventDefault()`. The `messageScrollerButton` modifier makes your own
element the button, given the scroller (`s.state`):
`<Button {{messageScrollerButton scroller=s.state}}>`. That is how the styled button renders
Joinery's Button.

### In a scaled ancestor

Upstream measures the rows on screen (`getBoundingClientRect()`) and scrolls in CSS pixels, so a
scroller inside a `transform: scale()` lands in the wrong place. Joinery's turns each
measurement back into CSS pixels by the viewport's scale, so it lands where it would unscaled.

## API

| Part                               | Arguments                                                                                                   |
| ---------------------------------- | ----------------------------------------------------------------------------------------------------------- |
| `<MessageScrollerProvider>`        | `@autoScroll`, `@defaultScrollPosition`, `@scrollEdgeThreshold`, `@scrollMargin`, `@scrollPreviousItemPeek` |
| `<s.Root>`                         | `@as`, `@name`                                                                                              |
| `<s.Viewport>`                     | `@preserveScrollOnPrepend` (`true`), `@label` (`Messages`), `@as`                                           |
| `<s.Content>`                      | `@spacerClass`, `@as`                                                                                       |
| `<s.Item>`                         | `@messageId`, `@scrollAnchor`, `@as`                                                                        |
| `<s.Button>`                       | `@direction` (`end`), `@behavior` (`smooth`), `@label`, `@as`                                               |
| `<s.Visibility as \|visibility\|>` | yields `currentAnchorId` and `visibleMessageIds`                                                            |

The provider also yields `s.scrollToMessage`, `s.scrollToEnd`, `s.scrollToStart`,
`s.scrollable` and `s.state`; the [component's page](/components/message-scroller.md#api-reference)
describes each, and the data attributes. `MessageScrollerState` is the engine the parts register
with; `s.state.observeVisibility()` starts tracking the reader's place from JavaScript, until the
function it returns is called.

## Testing

`MessageScrollerHarness` drives it, as on [Message Scroller's page](/components/message-scroller.md#testing).
