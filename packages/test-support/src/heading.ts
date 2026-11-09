import { Harness } from './harness.ts'

/**
 * Drives a `<Heading>` from `@ember-joinery/primitives/heading`: the level it chose and its
 * text. A Heading wraps its text, so a part inside it still belongs to the component around it.
 *
 *   const title = new HeadingHarness('title')   // <Heading @name="title">
 *   assert.strictEqual(title.level, 2)
 */
export class HeadingHarness extends Harness {
  static override component = 'heading'

  /** Its level, 1 to 6, from its tag (`<h2>` is 2). */
  get level(): number {
    return Number(this.element.tagName.slice(1))
  }

  /** The text it shows, whitespace collapsed. */
  get text(): string {
    return (this.element.textContent ?? '').replace(/\s+/g, ' ').trim()
  }
}
