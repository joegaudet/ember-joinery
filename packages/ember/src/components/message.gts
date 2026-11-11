import type { TOC } from '@ember/component/template-only'
import type { ComponentLike } from '@glint/template'
import { As, type TagName } from '@ember-joinery/primitives/as'
import type { PartModifier } from '@ember-joinery/primitives/part'
import {
  staticPart,
  staticPartModifier,
  type StaticPartSignature,
} from '../-private/static-part.gts'

/** Which side of the conversation a message sits on: the start (others) or the end (you). */
export type MessageAlign = 'start' | 'end'

const AVATAR = { class: 'jn-message-avatar', slot: 'message-avatar', part: 'avatar' } as const
const CONTENT = { class: 'jn-message-content', slot: 'message-content', part: 'content' } as const
const HEADER = { class: 'jn-message-header', slot: 'message-header', part: 'header' } as const
const FOOTER = { class: 'jn-message-footer', slot: 'message-footer', part: 'footer' } as const

/** What a message yields: its parts, each as a component and as a modifier for your own element. */
export interface MessageParts {
  /**
   * The avatar's slot, at the bottom of the row; beside a footer, it moves up to stay level
   * with the bubble. Leave it empty to keep a message in line with the avatar of the next one.
   */
  Avatar: ComponentLike<StaticPartSignature>
  /** Wraps the header, the bubble and the footer, in a column. */
  Content: ComponentLike<StaticPartSignature>
  /** Above the bubble, such as the sender's name. Stays at the start whatever the alignment. */
  Header: ComponentLike<StaticPartSignature>
  /** Below the bubble, such as a status or actions. Follows the message's side. */
  Footer: ComponentLike<StaticPartSignature>
  /** Makes your own element the avatar's slot. */
  avatar: PartModifier<HTMLElement>
  /** Makes your own element the content. */
  content: PartModifier<HTMLElement>
  /** Makes your own element the header. */
  header: PartModifier<HTMLElement>
  /** Makes your own element the footer. */
  footer: PartModifier<HTMLElement>
}

const PARTS: MessageParts = {
  Avatar: staticPart(AVATAR),
  Content: staticPart(CONTENT),
  Header: staticPart(HEADER),
  Footer: staticPart(FOOTER),
  avatar: staticPartModifier(AVATAR),
  content: staticPartModifier(CONTENT),
  header: staticPartModifier(HEADER),
  footer: staticPartModifier(FOOTER),
}

export interface MessageSignature {
  Args: {
    /** Default `start`. `end` puts the message, its avatar and its footer at the end of the row. */
    align?: MessageAlign
    /** The tag to render instead of `div`, such as `li` or `article`. */
    as?: TagName
    /** The message's name, for its harness (`data-test-jn-name`). */
    name?: string
  }
  Blocks: {
    default: [MessageParts]
  }
  Element: HTMLElement
}

/**
 * Lays out one message in a conversation: shadcn's Message. It owns the row (the avatar, the
 * alignment, the header and the footer); put the message itself in it as a `Bubble`.
 *
 *   <Message @align="end" as |m|>
 *     <m.Avatar><Avatar as |a|>…</Avatar></m.Avatar>
 *     <m.Content>
 *       <Bubble as |b|><b.Content>How can I help you today?</b.Content></Bubble>
 *       <m.Footer>Delivered</m.Footer>
 *     </m.Content>
 *   </Message>
 *
 * It is a layout, with no role of its own; what you put in it carries the meaning.
 */
const Message: TOC<MessageSignature> = <template>
  <As
    @as={{@as}}
    class="jn-message group/message"
    data-slot="message"
    data-align={{if @align @align "start"}}
    data-test-jn="message"
    data-test-jn-name={{@name}}
    ...attributes
  >{{yield PARTS}}</As>
</template>

export default Message

export interface MessageGroupSignature {
  Args: {
    /** The tag to render instead of `div`, such as `ol` or `section`. */
    as?: TagName
    /** The group's name, for its harness (`data-test-jn-name`). */
    name?: string
  }
  Blocks: { default: [] }
  Element: HTMLElement
}

/**
 * Stacks consecutive messages from the same sender, closer together than the conversation's
 * rows. Give the earlier ones an empty avatar slot (`<m.Avatar />`), so they line up with the
 * last one's avatar.
 *
 *   <MessageGroup>
 *     <Message as |m|><m.Avatar /><m.Content>…</m.Content></Message>
 *     <Message as |m|><m.Avatar><Avatar as |a|>…</Avatar></m.Avatar><m.Content>…</m.Content></Message>
 *   </MessageGroup>
 */
export const MessageGroup: TOC<MessageGroupSignature> = <template>
  <As
    @as={{@as}}
    class="jn-message-group"
    data-slot="message-group"
    data-test-jn="message-group"
    data-test-jn-name={{@name}}
    ...attributes
  >{{yield}}</As>
</template>
