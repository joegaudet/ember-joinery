import { blur, focus } from '@ember/test-helpers'
import { Harness } from './harness.ts'
import { pressEscape, pressOutside } from './layers.ts'
import { hover, unhover, type HoverOptions } from './pointer.ts'
import { shownInTopLayer, text } from './-private/overlay.ts'

/**
 * Drives a `<HoverCard>` from `@ember-joinery/ember` or `@ember-joinery/primitives/hover-card`.
 * It reads the state from the trigger's `data-state`, and acts as a user does: resting the
 * pointer on the trigger, moving it away, focus.
 *
 *   const card = new HoverCardHarness()
 *   await card.hover() // waits out the open delay
 *   assert.true(card.isOpen)
 *   await card.unhover() // and the close delay
 */
export class HoverCardHarness extends Harness {
  static override component = 'hover-card'

  /** The trigger: the `Trigger` part, or your own element with the `trigger` modifier. */
  get trigger(): HTMLElement {
    return this.part('trigger')
  }

  /** The card, or `null` while it isn't rendered. */
  get content(): HTMLElement | null {
    return this.queryPart('content')
  }

  /** Whether it is open, from the trigger's `data-state`. */
  get isOpen(): boolean {
    return this.trigger.getAttribute('data-state') === 'open'
  }

  /** Whether the card is showing in the browser's top layer. */
  get isShown(): boolean {
    return shownInTopLayer(this.content)
  }

  /** The card's text, whitespace collapsed. */
  get text(): string {
    return text(this.content)
  }

  /** The side it was placed on, after any flip (`data-side`). */
  get side(): string | null {
    return this.content?.getAttribute('data-side') ?? null
  }

  /** Its alignment along that side (`data-align`). */
  get align(): string | null {
    return this.content?.getAttribute('data-align') ?? null
  }

  /** Rests the pointer on the trigger, and waits out the open delay. */
  async hover(options?: HoverOptions): Promise<void> {
    await hover(this.trigger, options)
  }

  /** Moves the pointer off the trigger, away from the card, and waits out the close delay. */
  async unhover(options?: HoverOptions): Promise<void> {
    await unhover(this.trigger, { ...options, away: this.content })
  }

  /** Moves the pointer from the trigger onto the card, which keeps it open. */
  async hoverContent(): Promise<void> {
    const content = this.content
    if (!content) throw new Error(`Joinery harness: ${this} isn't open`)
    // Without a settle in between: the card's own pointerenter cancels the close delay.
    await Promise.all([unhover(this.trigger, { away: null, distance: 1 }), hover(content)])
  }

  /** Moves the pointer off the card. */
  async unhoverContent(): Promise<void> {
    const content = this.content
    if (!content) throw new Error(`Joinery harness: ${this} isn't open`)
    await unhover(content, { away: this.trigger })
  }

  /** Focuses the trigger, as tabbing to it does: it opens after the open delay. */
  async focus(): Promise<void> {
    await focus(this.trigger)
  }

  /** Moves focus away from the trigger: it closes after the close delay. */
  async blur(): Promise<void> {
    await blur(this.trigger)
  }

  /** Presses Escape where focus is. */
  async pressEscape(): Promise<void> {
    await pressEscape()
  }

  /** A press outside the card, as a user dismissing it makes. */
  async pressOutside(): Promise<void> {
    await pressOutside()
  }
}
