import { click } from '@ember/test-helpers'
import { Harness } from './harness.ts'
import { pressEscape, pressOutside } from './layers.ts'
import { accessibleDescription, accessibleName, shownInTopLayer, text } from './-private/overlay.ts'

/**
 * Drives a `<Popover>` from `@ember-joinery/ember` or `@ember-joinery/primitives/popover`. It
 * reads the state from the trigger's ARIA (`aria-expanded`) and the content's, and acts as a
 * user does: a click on the trigger, Escape, a press outside.
 *
 *   const popover = new PopoverHarness('dimensions') // <Popover @name="dimensions">
 *   await popover.open()
 *   assert.strictEqual(popover.label, 'Dimensions')
 *   await popover.pressEscape()
 *   assert.false(popover.isOpen)
 */
export class PopoverHarness extends Harness {
  static override component = 'popover'

  /** The trigger: the `Trigger` part, or your own element with the `trigger` modifier. */
  get trigger(): HTMLElement {
    return this.part('trigger')
  }

  /** The content, or `null` while it isn't rendered. */
  get content(): HTMLElement | null {
    return this.queryPart('content')
  }

  /** Whether it is open, from the trigger's `aria-expanded`. */
  get isOpen(): boolean {
    return this.trigger.getAttribute('aria-expanded') === 'true'
  }

  /** Whether the content is showing in the browser's top layer. */
  get isShown(): boolean {
    return shownInTopLayer(this.content)
  }

  /** The content's accessible name: its Title, or else its trigger, or your `aria-label`. */
  get label(): string {
    const content = this.content
    return content ? accessibleName(content) : ''
  }

  /** The content's accessible description: its Description's text, or `''`. */
  get description(): string {
    const content = this.content
    return content ? accessibleDescription(content) : ''
  }

  /** The Title's text, or `''`. */
  get title(): string {
    return text(this.queryPart('title'))
  }

  /** The content's text, whitespace collapsed. */
  get text(): string {
    return text(this.content)
  }

  /** The side the content was placed on, after any flip (`data-side`). */
  get side(): string | null {
    return this.content?.getAttribute('data-side') ?? null
  }

  /** The content's alignment along that side (`data-align`). */
  get align(): string | null {
    return this.content?.getAttribute('data-align') ?? null
  }

  /** The arrow's element (Radix's arrow is a `<span>` around an `<svg>`), or `null`. */
  get arrow(): HTMLElement | null {
    return this.queryPart('arrow')
  }

  /** Clicks the trigger. */
  async toggle(): Promise<void> {
    await click(this.trigger)
  }

  /** Opens it with a click on the trigger, unless it is open. */
  async open(): Promise<void> {
    if (!this.isOpen) await this.toggle()
  }

  /** Closes it with a click on the trigger, unless it is closed. */
  async close(): Promise<void> {
    if (this.isOpen) await this.toggle()
  }

  /** Clicks its Close part (the first, if there are several). */
  async clickClose(): Promise<void> {
    await click(this.part('close'))
  }

  /** Presses Escape where focus is. */
  async pressEscape(): Promise<void> {
    await pressEscape()
  }

  /** A press outside the popover, as a user dismissing it makes. */
  async pressOutside(): Promise<void> {
    await pressOutside()
  }
}
