import { click, focus } from '@ember/test-helpers'
import { Harness } from './harness.ts'

function text(element: Element | null): string {
  return (element?.textContent ?? '').replace(/\s+/g, ' ').trim()
}

/**
 * Drives a `<Bubble>` from `@ember-joinery/ember`. It reads the bubble's text, look and side,
 * its reactions, and clicks a bubble whose content is a button or a link:
 *
 *   const reply = new BubbleHarness('reply') // <Bubble @name="reply">
 *   assert.strictEqual(reply.text, 'I forgot my password')
 *   assert.strictEqual(reply.reactionsLabel, 'Reaction: thumbs up')
 *   await reply.click()
 *
 * Find what is inside its reactions, such as a button, with `find()`.
 */
export class BubbleHarness extends Harness {
  static override component = 'bubble'

  /** Its content's text, whitespace collapsed; the reactions are left out. */
  get text(): string {
    return this.parts('content').map(text).join(' ')
  }

  /** Its `@variant`: `default`, `secondary`, `muted`, `tinted`, `outline`, `ghost` or `destructive`. */
  get variant(): string | null {
    return this.element.getAttribute('data-variant')
  }

  /** Its `@align`: `start` or `end`. */
  get align(): string | null {
    return this.element.getAttribute('data-align')
  }

  /** Its content, the framed surface. Throws when it has none. */
  get content(): HTMLElement {
    return this.part('content')
  }

  /** Its reactions. Throws when it has none. */
  get reactions(): HTMLElement {
    return this.part('reactions')
  }

  /** Whether it has reactions. */
  get hasReactions(): boolean {
    return this.queryPart('reactions') !== null
  }

  /**
   * The reactions' accessible name, as assistive technology reads it: their `aria-label`
   * (`role="img"` reads the row once, by it), else their text. `''` without reactions.
   */
  get reactionsLabel(): string {
    const reactions = this.queryPart('reactions')
    if (!reactions) return ''
    return reactions.getAttribute('aria-label')?.trim() || text(reactions)
  }

  /** The edge the reactions overlap (`top` or `bottom`), or `null` without reactions. */
  get reactionsSide(): string | null {
    return this.queryPart('reactions')?.getAttribute('data-side') ?? null
  }

  /** The end of that edge they sit at (`start` or `end`), or `null` without reactions. */
  get reactionsAlign(): string | null {
    return this.queryPart('reactions')?.getAttribute('data-align') ?? null
  }

  /** Whether its content is a button or a link, which a user can press. */
  get isInteractive(): boolean {
    const content = this.queryPart('content')
    if (!content) return false
    return (
      content instanceof HTMLButtonElement ||
      (content instanceof HTMLAnchorElement && content.hasAttribute('href'))
    )
  }

  /** Whether its content has focus. */
  get isFocused(): boolean {
    return this.element.ownerDocument.activeElement === this.queryPart('content')
  }

  /** Clicks its content, as a user would: presses a button bubble, follows a link bubble. */
  async click(): Promise<void> {
    await click(this.content)
  }

  /** Moves focus to its content, as tabbing to a button or link bubble would. */
  async focus(): Promise<void> {
    await focus(this.content)
  }
}

/**
 * Drives a `<BubbleGroup>` from `@ember-joinery/ember`: consecutive bubbles from one sender.
 *
 *   const group = new BubbleGroupHarness()
 *   assert.deepEqual(group.bubbles.map(bubble => bubble.text), ['You tell me!', '…'])
 */
export class BubbleGroupHarness extends Harness {
  static override component = 'bubble-group'

  /** A harness for each bubble in the group, in order. */
  get bubbles(): BubbleHarness[] {
    return this.findAll(BubbleHarness)
  }
}
