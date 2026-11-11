// A message row for the Message Scroller examples: upstream's `components/message-animated.tsx`.
// It renders the message in a `MessageScrollerItem` (a user's turn is an anchor unless told
// otherwise), its text in a Bubble a paragraph at a time, and plays an entrance on a user's
// row, unless the reader prefers reduced motion. Upstream animates with motion; here the row
// plays the same keyframes with the Web Animations API, on transform and opacity only, so the
// scroller's measurements aren't disturbed. Upstream's reasoning parts are left out: no
// scripted message here has one.
import Component from '@glimmer/component'
import { modifier } from 'ember-modifier'
import { Bubble, Message, MessageScrollerItem, type BubbleVariant } from '@ember-joinery/ember'
import { MESSAGE_ANIMATIONS, type MessageAnimationPreset } from './message-animations.ts'

const prefersReducedMotion = () =>
  typeof matchMedia === 'function' && matchMedia('(prefers-reduced-motion: reduce)').matches

/**
 * Plays a preset once, when the row first renders: its preset never changes, so a row already
 * shown doesn't replay.
 */
const enter = modifier<{
  Element: HTMLElement
  Args: { Positional: [MessageAnimationPreset | undefined] }
}>((element, [preset]) => {
  if (!preset || prefersReducedMotion() || typeof element.animate !== 'function') return
  element.animate(preset.keyframes, preset.options)
})

/** A message to show: a chat message with text parts, or one with its text alone. */
export interface MessageAnimatedMessage {
  id: string
  role: string
  text?: string
  parts?: ReadonlyArray<{ type: string; text?: unknown }>
}

export interface MessageAnimatedSignature {
  Args: {
    message: MessageAnimatedMessage
    /** Default: a user's message is an anchor, an assistant's isn't. */
    scrollAnchor?: boolean
    /** The entrance a user's row plays. Default `slide-up`. */
    animationPreset?: MessageAnimationPreset
    /** Default `muted`. */
    userVariant?: BubbleVariant
    /** Default `ghost`. */
    assistantVariant?: BubbleVariant
  }
}

export default class MessageAnimated extends Component<MessageAnimatedSignature> {
  // The preset at first render: a row keeps the entrance it was shown with.
  readonly preset = this.args.animationPreset ?? MESSAGE_ANIMATIONS['slide-up']

  get isUser(): boolean {
    return this.args.message.role === 'user'
  }

  get scrollAnchor(): boolean {
    return this.args.scrollAnchor ?? this.isUser
  }

  get variant(): BubbleVariant {
    return this.isUser
      ? (this.args.userVariant ?? 'muted')
      : (this.args.assistantVariant ?? 'ghost')
  }

  /** Each text part's paragraphs, split on blank lines. */
  get parts(): { key: string; paragraphs: string[] }[] {
    const { message } = this.args
    const texts = message.parts
      ? message.parts.flatMap(part =>
          part.type === 'text' && typeof part.text === 'string' ? [part.text] : [],
        )
      : typeof message.text === 'string'
        ? [message.text]
        : []
    return texts.map((text, index) => ({
      key: `${message.id}-${index}`,
      paragraphs: text
        .split(/\n\s*\n/)
        .map(paragraph => paragraph.trim())
        .filter(Boolean),
    }))
  }

  <template>
    <MessageScrollerItem
      @messageId={{@message.id}}
      @scrollAnchor={{this.scrollAnchor}}
      {{enter (if this.isUser this.preset)}}
    >
      <Message @align={{if this.isUser "end" "start"}} as |m|>
        <m.Content>
          {{#each this.parts key="key" as |part|}}
            <Bubble @variant={{this.variant}} as |b|>
              <b.Content class="space-y-2">
                {{#each part.paragraphs as |paragraph|}}
                  <p class="whitespace-pre-wrap">{{paragraph}}</p>
                {{/each}}
              </b.Content>
            </Bubble>
          {{/each}}
        </m.Content>
      </Message>
    </MessageScrollerItem>
  </template>
}
