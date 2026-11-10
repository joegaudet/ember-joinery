import { click, focus } from '@ember/test-helpers'
import { Harness } from './harness.ts'

function text(element: Element | null): string {
  return (element?.textContent ?? '').replace(/\s+/g, ' ').trim()
}

/**
 * Drives a `<Marker>` from `@ember-joinery/ember`, or an element made a marker with its
 * `asMarker` modifier. It reads the marker's text, look and role, and clicks or focuses one
 * that is a link or a button:
 *
 *   const thinking = new MarkerHarness('thinking') // <Marker @name="thinking" role="status">
 *   assert.true(thinking.isStatus)
 *   assert.strictEqual(thinking.text, 'Thinking...')
 */
export class MarkerHarness extends Harness {
  static override component = 'marker'

  /** All the text it shows, whitespace collapsed. */
  get text(): string {
    return text(this.element)
  }

  /** Its accessible name: its `aria-label`, else its text (the icon is hidden). */
  get label(): string {
    return this.element.getAttribute('aria-label')?.trim() || this.text
  }

  /** Its `@variant`: `default`, `separator` or `border`. */
  get variant(): string | null {
    return this.element.getAttribute('data-variant')
  }

  /** The role it was given, such as `status`, or `null`. */
  get role(): string | null {
    return this.element.getAttribute('role')
  }

  /** Whether assistive technology announces it as it changes: `role="status"`. */
  get isStatus(): boolean {
    return this.role === 'status'
  }

  /** The icon's slot. Throws when it has none. */
  get icon(): HTMLElement {
    return this.part('icon')
  }

  /** Whether it has an icon. */
  get hasIcon(): boolean {
    return this.queryPart('icon') !== null
  }

  /** Its content. Throws when it has none. */
  get content(): HTMLElement {
    return this.part('content')
  }

  /** Whether it is a link: an `<a href>`. */
  get isLink(): boolean {
    return this.element instanceof HTMLAnchorElement && this.element.hasAttribute('href')
  }

  /** Where it links to, or `null` when it isn't a link. */
  get href(): string | null {
    return this.isLink ? this.element.getAttribute('href') : null
  }

  /** Whether it is a button. */
  get isButton(): boolean {
    return this.element instanceof HTMLButtonElement
  }

  /** Whether it has focus. */
  get isFocused(): boolean {
    return this.element.ownerDocument.activeElement === this.element
  }

  /** Clicks it, as a user would: follows a link marker, presses a button one. */
  async click(): Promise<void> {
    await click(this.element)
  }

  /** Moves focus to it, as tabbing to a link or button marker would. */
  async focus(): Promise<void> {
    await focus(this.element)
  }
}
