// `@ember-joinery/primitives/message-scroller`: a chat transcript's scroll container, which
// anchors turns, opens saved transcripts, follows streamed responses, loads history without
// jumping and jumps to any message, as `@shadcn/react`'s MessageScroller (which shadcn's
// Message Scroller wraps). The files beside this index are private to the feature.
export {
  MessageScrollerButton,
  MessageScrollerConsumer,
  MessageScrollerContent,
  MessageScrollerItem,
  MessageScrollerProvider,
  MessageScrollerRoot,
  MessageScrollerViewport,
  MessageScrollerVisibility,
  messageScrollerButton,
  type MessageScrollerApi,
  type MessageScrollerButtonOptions,
  type MessageScrollerButtonSignature,
  type MessageScrollerConsumerSignature,
  type MessageScrollerContentSignature,
  type MessageScrollerItemSignature,
  type MessageScrollerParts,
  type MessageScrollerProviderSignature,
  type MessageScrollerRootSignature,
  type MessageScrollerViewportSignature,
  type MessageScrollerVisibilitySignature,
} from './components.gts'
export {
  DEFAULT_SCROLL_EDGE_THRESHOLD,
  DEFAULT_SCROLL_MARGIN,
  DEFAULT_SCROLL_PREVIOUS_ITEM_PEEK,
  MessageScrollerState,
  USER_SCROLL_KEYS,
  type MessageScrollerDefaultScrollPosition,
  type MessageScrollerDirection,
  type MessageScrollerOptions,
  type MessageScrollerScrollOptions,
} from './state.ts'
export type {
  MessageScrollerScrollAlign,
  MessageScrollerScrollable,
  MessageScrollerVisibilityState,
} from './geometry.ts'
