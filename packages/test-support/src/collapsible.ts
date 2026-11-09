import { click, focus } from '@ember/test-helpers'
import { Harness } from './harness.ts'
import { isShowing } from './-private/showing.ts'

function text(element: Element): string {
  return (element.textContent ?? '').replace(/\s+/g, ' ').trim()
}

/**
 * Drives a `<Collapsible>`, from `@ember-joinery/ember` or, headless, from
 * `@ember-joinery/primitives/collapsible`. Its state is read from the trigger's
 * `aria-expanded`, so every test also checks what assistive technology hears.
 *
 *   const details = new CollapsibleHarness('order') // <Collapsible @name="order">
 *   await details.open()
 *   assert.true(details.isOpen)
 *   assert.strictEqual(details.text, '100 Market St, San Francisco')
 */
export class CollapsibleHarness extends Harness {
  static override component = 'collapsible'

  /** The trigger: `c.Trigger`, or your own element with `{{c.trigger}}`. */
  get trigger(): HTMLElement {
    return this.part('trigger')
  }

  /** The content's element, which is there (`hidden`) while closed. `null` before it renders. */
  get content(): HTMLElement | null {
    return this.queryPart('content')
  }

  /** Whether it is open, from the trigger's `aria-expanded`. */
  get isOpen(): boolean {
    return this.trigger.getAttribute('aria-expanded') === 'true'
  }

  /** Whether its content shows: open, or still animating out. */
  get isShown(): boolean {
    return isShowing(this.content)
  }

  /** Whether the trigger can't open or close it. */
  get isDisabled(): boolean {
    const trigger = this.trigger
    return trigger.hasAttribute('disabled') || trigger.hasAttribute('data-disabled')
  }

  /** The trigger's text, whitespace collapsed. */
  get label(): string {
    const trigger = this.trigger
    return trigger.getAttribute('aria-label')?.trim() || text(trigger)
  }

  /** The content's text, whitespace collapsed: `''` while it is closed. */
  get text(): string {
    const content = this.content
    return content && !content.hidden ? text(content) : ''
  }

  /** Whether the trigger names the content in `aria-controls`, as the ARIA pattern asks. */
  get controlsContent(): boolean {
    const content = this.content
    return Boolean(content?.id) && this.trigger.getAttribute('aria-controls') === content!.id
  }

  /** Clicks the trigger, as a user does. */
  async toggle(): Promise<void> {
    await click(this.trigger)
  }

  /** Opens it with the trigger, unless it is open. */
  async open(): Promise<void> {
    if (!this.isOpen) await this.toggle()
  }

  /** Closes it with the trigger, unless it is closed. */
  async close(): Promise<void> {
    if (this.isOpen) await this.toggle()
  }

  /** Moves focus to the trigger. */
  async focus(): Promise<void> {
    await focus(this.trigger)
  }
}
