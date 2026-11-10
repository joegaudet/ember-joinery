/* global ScrollBehavior -- a DOM type, which ESLint's browser globals don't list */
import type { TOC } from '@ember/component/template-only'
import type { ComponentLike } from '@glint/template'
import { ArrowDown } from 'lucide'
import {
  MessageScrollerConsumer,
  MessageScrollerContent as PrimitiveContent,
  MessageScrollerItem as PrimitiveItem,
  MessageScrollerProvider as PrimitiveProvider,
  MessageScrollerRoot,
  MessageScrollerViewport as PrimitiveViewport,
  MessageScrollerVisibility,
  messageScrollerButton,
  type MessageScrollerApi,
  type MessageScrollerContentSignature,
  type MessageScrollerDirection,
  type MessageScrollerItemSignature,
  type MessageScrollerOptions,
  type MessageScrollerRootSignature,
  type MessageScrollerViewportSignature,
  type MessageScrollerVisibilitySignature,
} from '@ember-joinery/primitives/message-scroller'
import { VisuallyHidden } from '@ember-joinery/primitives/visually-hidden'
import Button, { type ButtonSize, type ButtonVariant } from './button.gts'
import Icon from './icon.gts'

export { MessageScrollerConsumer, MessageScrollerVisibility }

/**
 * The scroller's frame: shadcn's `MessageScroller`. It fills its parent (`size-full`), so put
 * it in a container of a set height; the viewport scrolls inside it, and the buttons float
 * over it.
 */
export const MessageScroller: TOC<MessageScrollerRootSignature> = <template>
  <MessageScrollerRoot
    @as={{@as}}
    @name={{@name}}
    class="jn-message-scroller group/message-scroller"
    data-slot="message-scroller"
    ...attributes
  >{{yield}}</MessageScrollerRoot>
</template>

/**
 * The part that scrolls: a labelled region (`Messages`, `@label`) a keyboard can scroll. Its
 * bottom edge fades while there is more below, and it stays hidden until the opening position
 * applies.
 */
export const MessageScrollerViewport: TOC<MessageScrollerViewportSignature> = <template>
  <PrimitiveViewport
    @as={{@as}}
    @label={{@label}}
    @preserveScrollOnPrepend={{@preserveScrollOnPrepend}}
    class="jn-message-scroller-viewport"
    data-slot="message-scroller-viewport"
    ...attributes
  >{{yield}}</PrimitiveViewport>
</template>

/** The transcript: a live region of rows, in a column with the style's gap between them. */
export const MessageScrollerContent: TOC<MessageScrollerContentSignature> = <template>
  <PrimitiveContent
    @as={{@as}}
    @spacerClass={{@spacerClass}}
    class="jn-message-scroller-content"
    data-slot="message-scroller-content"
    ...attributes
  >{{yield}}</PrimitiveContent>
</template>

/**
 * One row of the transcript. A row far out of view skips its rendering work
 * (`content-visibility: auto`) but stays in the page, for selection, find-in-page and
 * assistive technology.
 */
export const MessageScrollerItem: TOC<MessageScrollerItemSignature> = <template>
  <PrimitiveItem
    @as={{@as}}
    @messageId={{@messageId}}
    @scrollAnchor={{@scrollAnchor}}
    class="jn-message-scroller-item"
    data-slot="message-scroller-item"
    ...attributes
  >{{yield}}</PrimitiveItem>
</template>

export interface MessageScrollerButtonSignature {
  Args: {
    /** Which edge it scrolls to. Default `end`. */
    direction?: MessageScrollerDirection
    /** The scroll's behavior. Default `smooth`. */
    behavior?: ScrollBehavior
    /** Default `secondary`. */
    variant?: ButtonVariant
    /** Default `icon-sm`. */
    size?: ButtonSize
    /**
     * Its accessible name, without a block. Default `Scroll to end` (`Scroll to start` with
     * `@direction="start"`).
     */
    label?: string
    /** Its name, for `ButtonHarness` (`data-test-jn-name`). */
    name?: string
  }
  /** Its content. Without a block, an arrow (pointing up for `start`) and its label. */
  Blocks: { default: [] }
  /** A `<button>`, as Joinery's Button. */
  Element: HTMLButtonElement | HTMLAnchorElement
}

function defaultLabel(label: string | undefined, direction: MessageScrollerDirection | undefined) {
  return label ?? (direction === 'start' ? 'Scroll to start' : 'Scroll to end')
}

/**
 * "Jump to latest": a Button floating over the viewport's bottom edge (or its top, with
 * `@direction="start"`) that scrolls there. It shows only while there is somewhere to go, and
 * is `inert` and out of the tab order otherwise; with `@autoScroll`, pressing it follows the
 * end again.
 */
export const MessageScrollerButton: TOC<MessageScrollerButtonSignature> = <template>
  <MessageScrollerConsumer as |s|>
    <Button
      @variant={{if @variant @variant "secondary"}}
      @size={{if @size @size "icon-sm"}}
      @name={{@name}}
      type="button"
      class="jn-message-scroller-button"
      data-slot="message-scroller-button"
      ...attributes
      {{messageScrollerButton scroller=s.state direction=@direction behavior=@behavior}}
    >
      {{#if (has-block)}}
        {{yield}}
      {{else}}
        <Icon @icon={{ArrowDown}} />
        <VisuallyHidden>{{defaultLabel @label @direction}}</VisuallyHidden>
      {{/if}}
    </Button>
  </MessageScrollerConsumer>
</template>

/** The parts shadcn's provider yields: the styled ones. */
export interface StyledMessageScrollerParts {
  Root: typeof MessageScroller
  Viewport: typeof MessageScrollerViewport
  Content: typeof MessageScrollerContent
  Item: typeof MessageScrollerItem
  Button: ComponentLike<MessageScrollerButtonSignature>
  Visibility: ComponentLike<MessageScrollerVisibilitySignature>
}

const PARTS: StyledMessageScrollerParts = {
  Root: MessageScroller,
  Viewport: MessageScrollerViewport,
  Content: MessageScrollerContent,
  Item: MessageScrollerItem,
  Button: MessageScrollerButton,
  Visibility: MessageScrollerVisibility,
}

export interface MessageScrollerProviderSignature {
  Args: MessageScrollerOptions
  Blocks: {
    /**
     * Its parts (`s.Root`, `s.Viewport`, `s.Content`, `s.Item`, `s.Button`, `s.Visibility`)
     * and the scroller's commands and state (`s.scrollToMessage`, `s.scrollToEnd`,
     * `s.scrollToStart`, `s.scrollable`).
     */
    default: [MessageScrollerApi<StyledMessageScrollerParts>]
  }
}

/**
 * A chat scroll container that anchors turns, opens saved transcripts, follows streamed
 * responses, loads history without jumping, and jumps to any message: shadcn's Message
 * Scroller. The provider owns the scroll behaviour and renders nothing of its own; it yields
 * the styled parts and the commands, so controls anywhere inside it can drive the transcript:
 *
 *   <MessageScrollerProvider @autoScroll={{true}} as |s|>
 *     <s.Root>
 *       <s.Viewport>
 *         <s.Content>
 *           {{#each this.messages as |message|}}
 *             <s.Item @messageId={{message.id}} @scrollAnchor={{message.isUser}}>
 *               <Message …>…</Message>
 *             </s.Item>
 *           {{/each}}
 *         </s.Content>
 *       </s.Viewport>
 *       <s.Button />
 *     </s.Root>
 *   </MessageScrollerProvider>
 *
 * The parts are exported on their own too (`MessageScrollerItem`), for a component of yours
 * that renders a row; they find the provider above them.
 */
export const MessageScrollerProvider: TOC<MessageScrollerProviderSignature> = <template>
  <PrimitiveProvider
    @autoScroll={{@autoScroll}}
    @defaultScrollPosition={{@defaultScrollPosition}}
    @scrollEdgeThreshold={{@scrollEdgeThreshold}}
    @scrollMargin={{@scrollMargin}}
    @scrollPreviousItemPeek={{@scrollPreviousItemPeek}}
    @parts={{PARTS}}
    as |s|
  >{{yield s}}</PrimitiveProvider>
</template>

/** Re-exported for typing a component that takes what the provider yields. */
export type { MessageScrollerApi }
