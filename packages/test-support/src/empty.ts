import { Harness } from './harness.ts'

function text(element: Element | null): string {
  return (element?.textContent ?? '').replace(/\s+/g, ' ').trim()
}

/**
 * Drives an `<Empty>` from `@ember-joinery/ember`: an empty state. It reads the title and
 * descriptions, reaches the media and content, and finds what is inside with `find()`:
 *
 *   const empty = new EmptyHarness('projects') // <Empty @name="projects">
 *   assert.strictEqual(empty.title, 'No Projects Yet')
 *   await empty.find(ButtonHarness).click()
 */
export class EmptyHarness extends Harness {
  static override component = 'empty'

  /** All the text it shows, whitespace collapsed. */
  get text(): string {
    return text(this.element)
  }

  /** Its title's text, or `''` without one. */
  get title(): string {
    return text(this.queryPart('title'))
  }

  /** Its first description's text, or `''` without one. */
  get description(): string {
    return text(this.queryPart('description'))
  }

  /** The text of every description, in order: one may sit in the header, another in the content. */
  get descriptions(): string[] {
    return this.parts('description').map(text)
  }

  /** The media's `@variant` (`default` or `icon`), or `null` without media. */
  get mediaVariant(): string | null {
    return this.queryPart('media')?.getAttribute('data-variant') ?? null
  }

  /** The header. Throws when it has none. */
  get header(): HTMLElement {
    return this.part('header')
  }

  /** The media: an icon, an image or an avatar. Throws when it has none. */
  get media(): HTMLElement {
    return this.part('media')
  }

  /** The content, under the header. Throws when it has none. */
  get content(): HTMLElement {
    return this.part('content')
  }
}
