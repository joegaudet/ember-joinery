import { Harness } from './harness.ts'

function text(element: Element | null): string {
  return (element?.textContent ?? '').replace(/\s+/g, ' ').trim()
}

/**
 * Drives a `<Card>` from `@ember-joinery/ember`. It reads the title and description, reaches
 * each part, and finds what is inside, such as a footer's buttons, with `find()`:
 *
 *   const card = new CardHarness('login') // <Card @name="login">
 *   assert.strictEqual(card.title, 'Login to your account')
 *   await card.find(ButtonHarness, 'submit').click()
 *
 * A page object can extend it and declare the card's own components with `@child`.
 */
export class CardHarness extends Harness {
  static override component = 'card'

  /** All the text it shows, whitespace collapsed. */
  get text(): string {
    return text(this.element)
  }

  /** Its title's text, or `''` without one. */
  get title(): string {
    return text(this.queryPart('title'))
  }

  /** Its description's text, or `''` without one. */
  get description(): string {
    return text(this.queryPart('description'))
  }

  /** Its `@size`: `default` or `sm`. */
  get size(): string | null {
    return this.element.getAttribute('data-size')
  }

  /** The header. Throws when it has none. */
  get header(): HTMLElement {
    return this.part('header')
  }

  /** The action's container, in the header. Throws when it has none. */
  get action(): HTMLElement {
    return this.part('action')
  }

  /** The content. Throws when it has none. */
  get content(): HTMLElement {
    return this.part('content')
  }

  /** The footer. Throws when it has none. */
  get footer(): HTMLElement {
    return this.part('footer')
  }
}
