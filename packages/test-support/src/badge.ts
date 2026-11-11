import { blur, click, focus } from '@ember/test-helpers'
import { Harness } from './harness.ts'

function text(element: Element): string {
  return (element.textContent ?? '').replace(/\s+/g, ' ').trim()
}

/**
 * Drives a `<Badge>` from `@ember-joinery/ember`, or an element made a badge with its `asBadge`
 * modifier (`<LinkTo {{asBadge}}>`).
 *
 *   const status = new BadgeHarness('status') // <Badge @name="status">
 *   assert.strictEqual(status.text, 'Verified')
 *   assert.strictEqual(status.variant, 'secondary')
 */
export class BadgeHarness extends Harness {
  static override component = 'badge'

  /** The text it shows, whitespace collapsed. */
  get text(): string {
    return text(this.element)
  }

  /** Its `@variant`: `default`, `secondary`, `destructive`, `outline`, `ghost` or `link`. */
  get variant(): string | null {
    return this.element.getAttribute('data-variant')
  }

  /** Whether it is a link: an `<a href>` (`@as="a"`, or the modifier on a link). */
  get isLink(): boolean {
    const element = this.element
    return element.localName === 'a' && element.hasAttribute('href')
  }

  /** Where it links to, for a link badge; otherwise `null`. */
  get href(): string | null {
    return this.isLink ? this.element.getAttribute('href') : null
  }

  /** Whether it has focus. */
  get isFocused(): boolean {
    return this.element.ownerDocument.activeElement === this.element
  }

  /** Clicks it, as a user would: a link badge follows its link. */
  async click(): Promise<void> {
    await click(this.element)
  }

  /** Moves focus to it, as tabbing to a link badge would. Fails if it can't take focus. */
  async focus(): Promise<void> {
    await focus(this.element)
  }

  /** Moves focus away from it. */
  async blur(): Promise<void> {
    await blur(this.element)
  }
}
