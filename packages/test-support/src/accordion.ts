import { click, focus } from '@ember/test-helpers'
import { pressKey, type KeyModifiers } from './focus.ts'
import { Harness } from './harness.ts'
import { attributes } from './selectors.ts'
import { isShowing } from './-private/showing.ts'

function text(element: Element): string {
  return (element.textContent ?? '').replace(/\s+/g, ' ').trim()
}

/**
 * Drives an `<Accordion>`, from `@ember-joinery/ember` or, headless, from
 * `@ember-joinery/primitives/accordion`. Items are found by their `@value`, and their state is
 * read from each trigger's `aria-expanded`, so every test also checks what assistive technology
 * hears.
 *
 *   const faq = new AccordionHarness('faq') // <Accordion @name="faq">
 *   await faq.toggle('returns')
 *   assert.deepEqual(faq.openValues, ['returns'])
 *   await faq.focus('returns')
 *   await faq.press('ArrowDown')
 *   assert.strictEqual(faq.focused, 'support')
 */
export class AccordionHarness extends Harness {
  static override component = 'accordion'

  /** Each item's value, in order. */
  get itemValues(): string[] {
    return this.values('item')
  }

  /** The values of the open items, in order. */
  get openValues(): string[] {
    return this.itemValues.filter(value => this.isOpen(value))
  }

  /** The item with this value. Throws when there is none. */
  item(value: string): HTMLElement {
    return this.part('item', value)
  }

  /** The item's header: an `<h3>`, unless given another tag. */
  header(value: string): HTMLElement {
    return this.part('header', value)
  }

  /** The item's trigger. */
  trigger(value: string): HTMLElement {
    return this.part('trigger', value)
  }

  /** The item's content, which is there (`hidden`) while the item is closed. */
  content(value: string): HTMLElement {
    return this.part('content', value)
  }

  /** Each trigger's text, in order: the accordion's headings. */
  get titles(): string[] {
    return this.parts('trigger').map(text)
  }

  /** The item's trigger text. */
  title(value: string): string {
    return text(this.trigger(value))
  }

  /** The item's content text: `''` while it is closed. */
  text(value: string): string {
    const content = this.content(value)
    return content.hidden ? '' : text(content)
  }

  /** Whether the item is open, from its trigger's `aria-expanded`. */
  isOpen(value: string): boolean {
    return this.trigger(value).getAttribute('aria-expanded') === 'true'
  }

  /** Whether the item's content shows: open, or still animating out. */
  isShown(value: string): boolean {
    return isShowing(this.content(value))
  }

  /** Whether the item can't be opened or closed: its trigger is `disabled`. */
  isDisabled(value: string): boolean {
    return this.trigger(value).hasAttribute('disabled')
  }

  /**
   * Whether the item's trigger can't close it, because it is the open item of a `single`
   * accordion that isn't `@collapsible` (`aria-disabled="true"`).
   */
  isLocked(value: string): boolean {
    return this.trigger(value).getAttribute('aria-disabled') === 'true'
  }

  /** `vertical` or `horizontal`, the way the arrow keys move. */
  get orientation(): string | null {
    return this.element.getAttribute('data-orientation')
  }

  /** The value of the item whose trigger has focus, or `null` when focus is elsewhere. */
  get focused(): string | null {
    const active = document.activeElement
    const trigger = this.parts('trigger').find(element => element === active)
    return trigger?.getAttribute(attributes.value) ?? null
  }

  /** Clicks the item's trigger, as a user does. */
  async toggle(value: string): Promise<void> {
    await click(this.trigger(value))
  }

  /** Opens the item with its trigger, unless it is open. */
  async open(value: string): Promise<void> {
    if (!this.isOpen(value)) await this.toggle(value)
  }

  /** Closes the item with its trigger, unless it is closed. */
  async close(value: string): Promise<void> {
    if (this.isOpen(value)) await this.toggle(value)
  }

  /** Moves focus to the item's trigger. */
  async focus(value: string): Promise<void> {
    await focus(this.trigger(value))
  }

  /** Presses a key on the focused trigger: `'ArrowDown'`, `'Home'`, `'End'`. */
  async press(key: string, modifiers?: KeyModifiers): Promise<boolean> {
    return pressKey(key, modifiers)
  }
}
