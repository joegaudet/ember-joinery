import { blur, focus } from '@ember/test-helpers'
import { Harness } from './harness.ts'
import { pressEscape } from './layers.ts'
import { hover, unhover, type HoverOptions } from './pointer.ts'
import { accessibleDescription, shownInTopLayer, text } from './-private/overlay.ts'

/**
 * Drives a `<Tooltip>` from `@ember-joinery/ember` or `@ember-joinery/primitives/tooltip`. It
 * reads the state from the trigger's `data-state` and what the trigger's `aria-describedby`
 * names, and acts as a user does: resting the pointer on the trigger, moving it away, focus.
 *
 *   const tooltip = new TooltipHarness()
 *   await tooltip.hover() // waits out the open delay
 *   assert.strictEqual(tooltip.description, 'Add to library')
 *   await tooltip.unhover()
 */
export class TooltipHarness extends Harness {
  static override component = 'tooltip'

  /** The trigger: the `Trigger` part, or your own element with the `trigger` modifier. */
  get trigger(): HTMLElement {
    return this.part('trigger')
  }

  /** The tooltip, or `null` while it isn't rendered. */
  get content(): HTMLElement | null {
    return this.queryPart('content')
  }

  /** How it is open, from the trigger's `data-state`: `delayed-open`, `instant-open` or `closed`. */
  get state(): string | null {
    return this.trigger.getAttribute('data-state')
  }

  /** Whether it is open. */
  get isOpen(): boolean {
    const state = this.state
    return state === 'delayed-open' || state === 'instant-open'
  }

  /** Whether the tooltip is showing in the browser's top layer. */
  get isShown(): boolean {
    return shownInTopLayer(this.content)
  }

  /** The trigger's accessible description while it is open: what a screen reader announces. */
  get description(): string {
    return accessibleDescription(this.trigger)
  }

  /** The tooltip's text, whitespace collapsed. */
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

  /** The arrow's element (a `<span>` around an `<svg>`), or `null`. */
  get arrow(): HTMLElement | null {
    return this.queryPart('arrow')
  }

  /** Rests the pointer on the trigger, and waits out the delay. */
  async hover(options?: HoverOptions): Promise<void> {
    await hover(this.trigger, options)
  }

  /** Moves the pointer off the trigger, away from the tooltip. */
  async unhover(options?: HoverOptions): Promise<void> {
    await unhover(this.trigger, { ...options, away: this.content })
  }

  /** Moves the pointer from the trigger onto the tooltip, as a user reading it does. */
  async hoverContent(): Promise<void> {
    const content = this.content
    if (!content) throw new Error(`Joinery harness: ${this} isn't open`)
    await unhover(this.trigger, {
      away: null,
      side: this.side === 'bottom' ? 'bottom' : 'top',
      distance: 1,
    })
    await hover(content)
  }

  /** Focuses the trigger, as tabbing to it does: it opens at once. */
  async focus(): Promise<void> {
    await focus(this.trigger)
  }

  /** Moves focus away from the trigger: it closes. */
  async blur(): Promise<void> {
    await blur(this.trigger)
  }

  /** Presses Escape where focus is. */
  async pressEscape(): Promise<void> {
    await pressEscape()
  }
}
