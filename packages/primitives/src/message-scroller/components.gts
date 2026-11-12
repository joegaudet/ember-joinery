/* global ScrollBehavior -- a DOM type, which ESLint's browser globals don't list */
import Component from '@glimmer/component'
import { cached } from '@glimmer/tracking'
import { registerDestructor } from '@ember/destroyable'
import type Owner from '@ember/owner'
import type { TOC } from '@ember/component/template-only'
import type { ComponentLike } from '@glint/template'
import { modifier } from 'ember-modifier'
import { As, type TagName } from '../as.gts'
import { Consume, Provide } from '../dom-context.gts'
import { part, type PartModifier } from '../part.ts'
import type { MessageScrollerScrollable, MessageScrollerVisibilityState } from './geometry.ts'
import {
  MessageScrollerState,
  type MessageScrollerDirection,
  type MessageScrollerOptions,
  type MessageScrollerScrollOptions,
} from './state.ts'
import { t, translate } from '../i18n.ts'
import { messages } from '../messages.ts'

const connectRoot = modifier<{
  Element: HTMLElement
  Args: { Positional: [MessageScrollerState] }
}>((element, [state]) => state.connectRoot(element))
const connectViewport = modifier<{
  Element: HTMLElement
  Args: { Positional: [MessageScrollerState, boolean | undefined] }
}>((element, [state, preserve]) => {
  state.preserveScrollOnPrepend = preserve ?? true
  return state.connectViewport(element)
})
const connectContent = modifier<{
  Element: HTMLElement
  Args: { Positional: [MessageScrollerState] }
}>((element, [state]) => state.connectContent(element))
const connectSpacer = modifier<{
  Element: HTMLElement
  Args: { Positional: [MessageScrollerState] }
}>((element, [state]) => state.connectSpacer(element))
const connectItem = modifier<{
  Element: HTMLElement
  Args: { Positional: [MessageScrollerState, string | undefined] }
}>((element, [state, messageId]) => state.connectItem(element, messageId))

// ----- Root ----------------------------------------------------------------------------------

export interface MessageScrollerRootSignature {
  Args: {
    /** The tag to render. Default `div`. */
    as?: TagName
    /** Its name, for `MessageScrollerHarness` (`data-test-jn-name`). */
    name?: string
  }
  Blocks: { default: [] }
  Element: HTMLElement
}

/**
 * The scroller's frame, around the viewport and its buttons: upstream's `MessageScroller.Root`.
 * Like the viewport, it carries `data-scrollable` (`start`, `end`, both or none) and
 * `data-autoscrolling`, for styling the frame by scroll state, and `data-pending-scroll` until
 * the opening position applies.
 */
export const MessageScrollerRoot: TOC<MessageScrollerRootSignature> = <template>
  <Consume @key={{MessageScrollerState}} as |context|>
    <As
      @as={{@as}}
      data-test-jn="message-scroller"
      data-test-jn-name={{@name}}
      ...attributes
      data-pending-scroll={{if context.data.pendingDefaultScroll ""}}
      {{connectRoot context.data}}
    >{{yield}}</As>
  </Consume>
</template>

// ----- Viewport ------------------------------------------------------------------------------

export interface MessageScrollerViewportSignature {
  Args: {
    /** Keep the first visible row in place when older rows are prepended. Default `true`. */
    preserveScrollOnPrepend?: boolean
    /** The scroll region's accessible name. Default `Messages`. */
    label?: string
    /** The tag to render. Default `div`. */
    as?: TagName
  }
  Blocks: { default: [] }
  Element: HTMLElement
}

/**
 * The part that scrolls: a labelled region (`role="region"`, `Messages`) a keyboard can reach
 * and scroll (`tabindex="0"`). The reader scrolling it, by wheel, touch, a scroll key or the
 * scrollbar, lets go of following and of an anchored turn. It is hidden
 * (`data-pending-scroll`) until the opening position applies, so the transcript doesn't jump.
 */
export const MessageScrollerViewport: TOC<MessageScrollerViewportSignature> = <template>
  <Consume @key={{MessageScrollerState}} as |context|>
    <As
      @as={{@as}}
      role="region"
      aria-label={{if @label @label (t messages.messageScrollerLabel)}}
      tabindex="0"
      data-test-jn-part="viewport"
      ...attributes
      data-pending-scroll={{if context.data.pendingDefaultScroll ""}}
      {{connectViewport context.data @preserveScrollOnPrepend}}
    >{{yield}}</As>
  </Consume>
</template>

// ----- Content -------------------------------------------------------------------------------

export interface MessageScrollerContentSignature {
  Args: {
    /** A class for the spacer it keeps after the rows, which makes room below an anchored turn. */
    spacerClass?: string
    /** The tag to render. Default `div`. */
    as?: TagName
  }
  /** The rows: every child is a `MessageScrollerItem`. */
  Blocks: { default: [] }
  Element: HTMLElement
}

/**
 * The transcript: its children are the rows, each a `MessageScrollerItem`. It is a live region
 * (`role="log"`, `aria-relevant="additions"`), so a new row is announced, but not every token
 * streamed into one; give it `aria-busy` while a turn streams to hold the announcement until
 * the row is done.
 */
export const MessageScrollerContent: TOC<MessageScrollerContentSignature> = <template>
  <Consume @key={{MessageScrollerState}} as |context|>
    <As
      @as={{@as}}
      role="log"
      aria-relevant="additions"
      data-test-jn-part="content"
      ...attributes
      {{connectContent context.data}}
    >
      {{yield}}
      <div
        aria-hidden="true"
        data-message-scroller-spacer=""
        hidden
        class={{@spacerClass}}
        {{connectSpacer context.data}}
      ></div>
    </As>
  </Consume>
</template>

// ----- Item ----------------------------------------------------------------------------------

export interface MessageScrollerItemSignature {
  Args: {
    /** A stable id for the row: `scrollToMessage`, visibility and prepends go by it. */
    messageId?: string
    /** Marks the row that starts a turn: when one is appended, it settles near the top. */
    scrollAnchor?: boolean
    /** The tag to render. Default `div`. */
    as?: TagName
  }
  Blocks: { default: [] }
  Element: HTMLElement
}

/**
 * One row of the transcript: a message, a marker, a typing row, a separator, a "load earlier"
 * row. Give the rows that can be jumped to a `@messageId`, and the one that starts a turn (a
 * user's message, a "joined the chat" marker) `@scrollAnchor`.
 */
export const MessageScrollerItem: TOC<MessageScrollerItemSignature> = <template>
  <Consume @key={{MessageScrollerState}} as |context|>
    <As
      @as={{@as}}
      data-message-id={{@messageId}}
      data-scroll-anchor={{if @scrollAnchor "true" "false"}}
      data-test-jn-part="item"
      data-test-jn-value={{@messageId}}
      ...attributes
      {{connectItem context.data @messageId}}
    >{{yield}}</As>
  </Consume>
</template>

// ----- Button --------------------------------------------------------------------------------

/** What the button's modifier takes. */
export interface MessageScrollerButtonOptions {
  /** The scroller, as `<MessageScrollerConsumer>` or the provider yields it (`s.state`). */
  scroller: MessageScrollerState
  /** Which edge it scrolls to. Default `end`. */
  direction?: MessageScrollerDirection
  /** The scroll's behavior. Default `smooth`. */
  behavior?: ScrollBehavior
}

/** Whether a button pointing that way has somewhere to go. */
function isActive(scroller: MessageScrollerState, direction: MessageScrollerDirection): boolean {
  return direction === 'start' ? scroller.scrollable.start : scroller.scrollable.end
}

/**
 * Makes an element (a Button of your own) the scroller's button: it scrolls to its edge, and
 * while there is nothing to scroll to it is `inert`, out of the tab order, and
 * `data-active="false"`, so it never leaves a stop for the keyboard. While it is active, the
 * element keeps a `tabindex` of its own. A click listener of yours that comes before it (as
 * `{{on "click"}}` in `...attributes` does) runs first, and stops the scroll by calling
 * `event.preventDefault()`, as upstream's `onClick` does. As a component, it is
 * `MessageScrollerButton`.
 */
export const messageScrollerButton: PartModifier<HTMLElement, MessageScrollerButtonOptions> = part<
  HTMLElement,
  MessageScrollerButtonOptions
>(({ scroller, direction = 'end', behavior = 'smooth' }) => {
  const active = isActive(scroller, direction)
  return {
    attributes: {
      'data-active': active ? 'true' : 'false',
      'data-direction': direction,
      inert: !active,
      // Unset while active, so the element's own tabindex, if it has one, comes back.
      tabindex: active ? null : '-1',
      'data-test-jn-part': 'button',
      'data-test-jn-value': direction,
    },
    on: {
      click: (event: MouseEvent) => {
        // A listener of the caller's that ran first may have taken the click over.
        if (event.defaultPrevented || !isActive(scroller, direction)) return
        ;(event.currentTarget as HTMLElement | null)?.blur()
        if (direction === 'start') scroller.scrollToStart({ behavior })
        else scroller.scrollToEnd({ behavior })
      },
    },
  }
})

export interface MessageScrollerButtonSignature {
  Args: {
    /** Which edge it scrolls to. Default `end`. */
    direction?: MessageScrollerDirection
    /** The scroll's behavior. Default `smooth`. */
    behavior?: ScrollBehavior
    /** Its text, when it has no block. Default `Scroll to end` (or `Scroll to start`). */
    label?: string
    /** The tag to render. Default `button`. */
    as?: TagName
  }
  /** Its content. Without a block, its label. */
  Blocks: { default: [] }
  Element: HTMLElement
}

class ButtonLabel extends Component<{
  Args: { label?: string; direction?: MessageScrollerDirection }
}> {
  get text(): string {
    if (this.args.label) return this.args.label
    return translate(
      this,
      this.args.direction === 'start'
        ? messages.messageScrollerToStart
        : messages.messageScrollerToEnd,
    )
  }

  <template>{{this.text}}</template>
}

/**
 * Scrolls to the start or the end of the transcript (`@direction`, default `end`): "jump to
 * latest". It is a real button, `inert` and out of the tab order while there is nothing to
 * scroll to; with `autoScroll`, pressing it follows the end again.
 */
export const MessageScrollerButton: TOC<MessageScrollerButtonSignature> = <template>
  <Consume @key={{MessageScrollerState}} as |context|>
    <As
      @as={{@as}}
      @tag="button"
      type="button"
      ...attributes
      {{messageScrollerButton scroller=context.data direction=@direction behavior=@behavior}}
    >
      {{#if (has-block)}}
        {{yield}}
      {{else}}
        <span><ButtonLabel @label={{@label}} @direction={{@direction}} /></span>
      {{/if}}
    </As>
  </Consume>
</template>

// ----- Visibility ----------------------------------------------------------------------------

class VisibilityWatcher extends Component<{
  Args: { scroller: MessageScrollerState }
  Blocks: { default: [MessageScrollerVisibilityState] }
}> {
  constructor(owner: Owner, args: { scroller: MessageScrollerState }) {
    super(owner, args)
    registerDestructor(this, args.scroller.observeVisibility())
  }

  <template>{{yield @scroller.visibility}}</template>
}

export interface MessageScrollerVisibilitySignature {
  Blocks: {
    /** Where the reader is: `currentAnchorId` and `visibleMessageIds`, kept up to date. */
    default: [MessageScrollerVisibilityState]
  }
}

/**
 * Tracks where the reader is while it is rendered, as upstream's `useMessageScrollerVisibility`
 * does while subscribed: the anchored turn they are in (`currentAnchorId`, which stays set
 * after it scrolls out of view) and the rows in view (`visibleMessageIds`). Nothing is tracked
 * while none is rendered. Rows need a `@messageId` to count.
 */
export const MessageScrollerVisibility: TOC<MessageScrollerVisibilitySignature> = <template>
  <Consume @key={{MessageScrollerState}} as |context|>
    <VisibilityWatcher @scroller={{context.data}} as |visibility|>{{yield
        visibility
      }}</VisibilityWatcher>
  </Consume>
</template>

// ----- Provider ------------------------------------------------------------------------------

/** The parts a provider yields, which a styled provider replaces with its own. */
export interface MessageScrollerParts {
  Root: ComponentLike<MessageScrollerRootSignature>
  Viewport: ComponentLike<MessageScrollerViewportSignature>
  Content: ComponentLike<MessageScrollerContentSignature>
  Item: ComponentLike<MessageScrollerItemSignature>
  Button: ComponentLike<MessageScrollerButtonSignature>
  Visibility: ComponentLike<MessageScrollerVisibilitySignature>
}

/**
 * What a provider yields: its parts, and the scroller's commands and state, for controls
 * anywhere inside it (upstream's `useMessageScroller` and `useMessageScrollerScrollable`).
 */
export interface MessageScrollerApi<Parts extends MessageScrollerParts = MessageScrollerParts> {
  Root: Parts['Root']
  Viewport: Parts['Viewport']
  Content: Parts['Content']
  Item: Parts['Item']
  Button: Parts['Button']
  Visibility: Parts['Visibility']
  /** Scrolls to the row with this `@messageId`; see `MessageScrollerState`. */
  scrollToMessage: (messageId: string, options?: MessageScrollerScrollOptions) => boolean
  /** Scrolls to the latest row, and with `@autoScroll`, follows the end again. */
  scrollToEnd: (options?: MessageScrollerScrollOptions) => boolean
  /** Scrolls to the first row. */
  scrollToStart: (options?: MessageScrollerScrollOptions) => boolean
  /** Which edges it can scroll toward (`start`, `end`): `!end` is "at the latest". */
  readonly scrollable: MessageScrollerScrollable
  /** The scroller itself, for `messageScrollerButton` and `observeVisibility()`. */
  readonly state: MessageScrollerState
}

const PRIMITIVE_PARTS: MessageScrollerParts = {
  Root: MessageScrollerRoot,
  Viewport: MessageScrollerViewport,
  Content: MessageScrollerContent,
  Item: MessageScrollerItem,
  Button: MessageScrollerButton,
  Visibility: MessageScrollerVisibility,
}

/** Each provider's yield, for `<MessageScrollerConsumer>`. */
const APIS = new WeakMap<MessageScrollerState, MessageScrollerApi>()

export interface MessageScrollerProviderSignature<
  Parts extends MessageScrollerParts = MessageScrollerParts,
> {
  Args: MessageScrollerOptions & {
    /** The parts to yield in place of the headless ones: a styled provider's own. */
    parts?: Parts
  }
  Blocks: {
    default: [MessageScrollerApi<Parts>]
  }
}

/**
 * A chat transcript's scroller: upstream's `MessageScroller.Provider`, from `@shadcn/react`. It
 * owns the scroll behaviour and renders nothing of its own; its parts render the frame, the
 * viewport, the rows and the buttons, wherever they are inside it, and controls anywhere inside
 * it can drive it:
 *
 *   <MessageScrollerProvider @autoScroll={{true}} as |s|>
 *     <s.Root>
 *       <s.Viewport>
 *         <s.Content>
 *           {{#each this.messages as |message|}}
 *             <s.Item @messageId={{message.id}} @scrollAnchor={{this.isUser message}}>…</s.Item>
 *           {{/each}}
 *         </s.Content>
 *       </s.Viewport>
 *       <s.Button />
 *     </s.Root>
 *     <button type="button" {{on "click" (fn s.scrollToMessage "intro" (hash behavior="smooth"))}}>Back to the start</button>
 *   </MessageScrollerProvider>
 *
 * The parts are also exported on their own (`MessageScrollerItem`), for a component of yours
 * that renders a row: they find the provider above them.
 */
export class MessageScrollerProvider<
  Parts extends MessageScrollerParts = MessageScrollerParts,
> extends Component<MessageScrollerProviderSignature<Parts>> {
  readonly state: MessageScrollerState

  constructor(owner: Owner, args: MessageScrollerProviderSignature<Parts>['Args']) {
    super(owner, args)
    this.state = new MessageScrollerState(() => this.args)
    registerDestructor(this, () => this.state.destroy())
  }

  @cached
  get api(): MessageScrollerApi<Parts> {
    const state = this.state
    const parts = (this.args.parts ?? PRIMITIVE_PARTS) as Parts
    const api: MessageScrollerApi<Parts> = {
      Root: parts.Root,
      Viewport: parts.Viewport,
      Content: parts.Content,
      Item: parts.Item,
      Button: parts.Button,
      Visibility: parts.Visibility,
      scrollToMessage: state.scrollToMessage,
      scrollToEnd: state.scrollToEnd,
      scrollToStart: state.scrollToStart,
      get scrollable() {
        return state.scrollable
      },
      state,
    }
    APIS.set(state, api as unknown as MessageScrollerApi)
    return api
  }

  /** Called with the arguments in the template, so a change to one reaches the scroller. */
  syncOptions = (..._options: unknown[]): undefined => {
    this.state.optionsChanged()
    return undefined
  }

  <template>
    {{this.syncOptions
      @autoScroll
      @defaultScrollPosition
      @scrollEdgeThreshold
      @scrollMargin
      @scrollPreviousItemPeek
    }}
    <Provide @data={{this.state}} @key={{MessageScrollerState}} @element={{false}}>
      {{yield this.api}}
    </Provide>
  </template>
}

export interface MessageScrollerConsumerSignature {
  Blocks: {
    /** What the provider above yields. */
    default: [MessageScrollerApi]
  }
}

/**
 * Gives what the nearest `MessageScrollerProvider` above it yields, to a component of yours
 * inside it that isn't handed it: a jump menu, a status line.
 *
 *   <MessageScrollerConsumer as |s|>
 *     {{if s.scrollable.end "New messages below" "Up to date"}}
 *   </MessageScrollerConsumer>
 */
export const MessageScrollerConsumer: TOC<MessageScrollerConsumerSignature> = <template>
  <Consume @key={{MessageScrollerState}} as |context|>
    {{yield (apiOf context.data)}}
  </Consume>
</template>

function apiOf(state: MessageScrollerState): MessageScrollerApi {
  const api = APIS.get(state)
  if (!api) throw new Error('Joinery: <MessageScrollerConsumer> found no provider above it')
  return api
}
