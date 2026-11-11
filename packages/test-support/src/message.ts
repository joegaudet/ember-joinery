import { BubbleHarness } from './bubble.ts'
import { Harness } from './harness.ts'

function text(element: Element | null): string {
  return (element?.textContent ?? '').replace(/\s+/g, ' ').trim()
}

/**
 * Drives a `<Message>` from `@ember-joinery/ember`: one row of a conversation. It reads the
 * row's side and its header and footer, and reaches the bubbles in it:
 *
 *   const reply = new MessageHarness('reply') // <Message @name="reply">
 *   assert.strictEqual(reply.align, 'end')
 *   assert.strictEqual(reply.footerText, 'Delivered')
 *   assert.strictEqual(reply.bubbles[0]!.text, "It's a one-line change.")
 *
 * Find what else is inside it, such as its avatar or the footer's buttons, with `find()`.
 */
export class MessageHarness extends Harness {
  static override component = 'message'

  /** All the text it shows, whitespace collapsed. */
  get text(): string {
    return text(this.element)
  }

  /** Its `@align`: `start` or `end`. */
  get align(): string | null {
    return this.element.getAttribute('data-align')
  }

  /** The avatar's slot. Throws when it has none. */
  get avatar(): HTMLElement {
    return this.part('avatar')
  }

  /** Whether it has an avatar's slot, even an empty one that only keeps it in line. */
  get hasAvatar(): boolean {
    return this.queryPart('avatar') !== null
  }

  /** The content: the header, the bubbles and the footer. Throws when it has none. */
  get content(): HTMLElement {
    return this.part('content')
  }

  /** The header. Throws when it has none. */
  get header(): HTMLElement {
    return this.part('header')
  }

  /** The footer. Throws when it has none. */
  get footer(): HTMLElement {
    return this.part('footer')
  }

  /** The header's text, such as the sender's name, or `''` without one. */
  get headerText(): string {
    return text(this.queryPart('header'))
  }

  /** The footer's text, such as a status, or `''` without one. */
  get footerText(): string {
    return text(this.queryPart('footer'))
  }

  /** A harness for each bubble in it, in order. */
  get bubbles(): BubbleHarness[] {
    return this.findAll(BubbleHarness)
  }
}

/**
 * Drives a `<MessageGroup>` from `@ember-joinery/ember`: consecutive messages from one sender.
 *
 *   const group = new MessageGroupHarness()
 *   assert.strictEqual(group.messages.length, 2)
 */
export class MessageGroupHarness extends Harness {
  static override component = 'message-group'

  /** A harness for each message in the group, in order. */
  get messages(): MessageHarness[] {
    return this.findAll(MessageHarness)
  }
}
