import { click } from '@ember/test-helpers'
import { Harness } from './harness.ts'
import { NotFoundError } from './-private/tree.ts'

function text(element: Element): string {
  return (element.textContent ?? '').replace(/\s+/g, ' ').trim()
}

/**
 * Drives a `<Pagination>` from `@ember-joinery/ember`: its page links, the previous and next
 * links, and the current page, read through `aria-current` as a screen reader reads it.
 *
 *   const pages = new PaginationHarness()
 *   assert.deepEqual(pages.pages, ['1', '2', '3'])
 *   assert.strictEqual(pages.current, '2')
 *   await pages.goTo('3')
 *   await pages.goToNext()
 */
export class PaginationHarness extends Harness {
  static override component = 'pagination'

  /** Its accessible name, the `nav`'s `aria-label`. */
  get label(): string {
    return this.element.getAttribute('aria-label') ?? ''
  }

  /** The page links, in order (not the previous and next links). */
  get pageElements(): HTMLElement[] {
    return this.parts('link')
  }

  /** The text of each page link, in order: the page numbers. */
  get pages(): string[] {
    return this.pageElements.map(text)
  }

  /** The current page's text (the link with `aria-current="page"`), or `null` with none. */
  get current(): string | null {
    const current = this.pageElements.find(link => link.getAttribute('aria-current') === 'page')
    return current ? text(current) : null
  }

  /** The previous page's link. Throws when there is none. */
  get previous(): HTMLElement {
    return this.part('previous')
  }

  /** The next page's link. Throws when there is none. */
  get next(): HTMLElement {
    return this.part('next')
  }

  /** Whether some pages are left out, shown as an ellipsis. */
  get hasEllipsis(): boolean {
    return this.queryPart('ellipsis') !== null
  }

  /** The link to the page whose text is `page`. Throws when there is none. */
  page(page: string): HTMLElement {
    const found = this.pageElements.find(link => text(link) === page)
    if (!found)
      throw new NotFoundError(`no page "${page}" in ${this} (it has ${this.pages.join(', ')})`)
    return found
  }

  /** Whether the page whose text is `page` is the current one. */
  isCurrent(page: string): boolean {
    return this.page(page).getAttribute('aria-current') === 'page'
  }

  /** Clicks the link to the page whose text is `page`, as a user would. */
  async goTo(page: string): Promise<void> {
    await click(this.page(page))
  }

  /** Clicks the previous page's link. */
  async goToPrevious(): Promise<void> {
    await click(this.previous)
  }

  /** Clicks the next page's link. */
  async goToNext(): Promise<void> {
    await click(this.next)
  }
}
