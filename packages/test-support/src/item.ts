import { click, focus } from '@ember/test-helpers'
import { Harness } from './harness.ts'

function text(element: Element | null): string {
  return (element?.textContent ?? '').replace(/\s+/g, ' ').trim()
}

/**
 * Drives an `<Item>` from `@ember-joinery/ember`, or an element made an item with `asItem`. It
 * reads the title and description, reaches each part, and finds what is inside, such as its
 * actions' buttons, with `find()`:
 *
 *   const item = new ItemHarness('security') // <Item @name="security">
 *   assert.strictEqual(item.title, 'Security Alert')
 *   await item.find(ButtonHarness).click()
 *
 * An item that is a link (`@as="a"`) can be clicked and focused.
 */
export class ItemHarness extends Harness {
  static override component = 'item'

  /** All the text it shows, whitespace collapsed. */
  get text(): string {
    return text(this.element)
  }

  /** Its first title's text, or `''` without one. */
  get title(): string {
    return text(this.queryPart('title'))
  }

  /** Its first description's text, or `''` without one. */
  get description(): string {
    return text(this.queryPart('description'))
  }

  /** The text of every description, in order: a second content may hold one too. */
  get descriptions(): string[] {
    return this.parts('description').map(text)
  }

  /** Its `@variant`: `default`, `outline` or `muted`. */
  get variant(): string | null {
    return this.element.getAttribute('data-variant')
  }

  /** Its `@size`: `default`, `sm` or `xs`. */
  get size(): string | null {
    return this.element.getAttribute('data-size')
  }

  /** The media's `@variant` (`default`, `icon` or `image`), or `null` without media. */
  get mediaVariant(): string | null {
    return this.queryPart('media')?.getAttribute('data-variant') ?? null
  }

  /** The media. Throws when it has none. */
  get media(): HTMLElement {
    return this.part('media')
  }

  /** The first content. Throws when it has none. */
  get content(): HTMLElement {
    return this.part('content')
  }

  /** The actions. Throws when it has none. */
  get actions(): HTMLElement {
    return this.part('actions')
  }

  /** The header. Throws when it has none. */
  get header(): HTMLElement {
    return this.part('header')
  }

  /** The footer. Throws when it has none. */
  get footer(): HTMLElement {
    return this.part('footer')
  }

  /** Whether it is a link: an `<a href>`. */
  get isLink(): boolean {
    return this.element instanceof HTMLAnchorElement && this.element.hasAttribute('href')
  }

  /** Where it links to, or `null` when it isn't a link. */
  get href(): string | null {
    return this.isLink ? this.element.getAttribute('href') : null
  }

  /** Whether it has focus. */
  get isFocused(): boolean {
    return this.element.ownerDocument.activeElement === this.element
  }

  /** Clicks it, as a user would: follows a link item. */
  async click(): Promise<void> {
    await click(this.element)
  }

  /** Moves focus to it, as tabbing to a link item would. Fails if it can't take focus. */
  async focus(): Promise<void> {
    await focus(this.element)
  }
}

/**
 * Drives an `<ItemGroup>` from `@ember-joinery/ember`: a list of items, with separators.
 *
 *   const people = new ItemGroupHarness('people')
 *   assert.deepEqual(people.items.map(item => item.title), ['shadcn', 'maxleiter'])
 */
export class ItemGroupHarness extends Harness {
  static override component = 'item-group'

  /** A harness for each item in the group, in order. */
  get items(): ItemHarness[] {
    return this.findAll(ItemHarness)
  }

  /** Its separators, in order. */
  get separators(): HTMLElement[] {
    return this.parts('separator')
  }
}
