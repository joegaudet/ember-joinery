import { click } from '@ember/test-helpers'
import { Harness } from './harness.ts'
import { NotFoundError } from './-private/tree.ts'

function text(element: Element): string {
  return (element.textContent ?? '').replace(/\s+/g, ' ').trim()
}

function isHidden(element: Element): boolean {
  const role = element.getAttribute('role')
  return (
    element.getAttribute('aria-hidden') === 'true' || role === 'presentation' || role === 'none'
  )
}

/**
 * Drives a `<Breadcrumb>`, from `@ember-joinery/ember` or `@ember-joinery/primitives/breadcrumb`:
 * a `nav` around a list of crumbs, with separators that assistive technology skips. It reads the
 * crumbs as a screen reader does, through the list's items and `aria-current`.
 *
 *   const path = new BreadcrumbHarness()
 *   assert.deepEqual(path.items, ['Home', 'Components', 'Breadcrumb'])
 *   assert.strictEqual(path.current, 'Breadcrumb')
 *   await path.clickLink('Components')
 */
export class BreadcrumbHarness extends Harness {
  static override component = 'breadcrumb'

  /** Its accessible name, the `nav`'s `aria-label`. */
  get label(): string {
    return this.element.getAttribute('aria-label') ?? ''
  }

  /** Its list (`ol`). */
  get list(): HTMLOListElement | HTMLUListElement {
    const list = this.element.querySelector('ol, ul')
    if (!list) throw new NotFoundError(`no list found in ${this}`)
    return list as HTMLOListElement
  }

  /** Each crumb's `li`, in order: the list's items, but the separators. */
  get itemElements(): HTMLLIElement[] {
    return [...this.list.children].filter(
      (element): element is HTMLLIElement => element.localName === 'li' && !isHidden(element),
    )
  }

  /** The text of each crumb, in order, whitespace collapsed. A collapsed crumb reads as ''. */
  get items(): string[] {
    return this.itemElements.map(element => {
      const visible = [...element.childNodes].filter(
        node => !(node instanceof Element && isHidden(node)),
      )
      return visible
        .map(node => node.textContent ?? '')
        .join('')
        .replace(/\s+/g, ' ')
        .trim()
    })
  }

  /** The separators between the crumbs: the list's items assistive technology skips. */
  get separators(): HTMLElement[] {
    return [...this.list.children].filter(
      (element): element is HTMLElement => element.localName === 'li' && isHidden(element),
    )
  }

  /** The text of each crumb that is a link (`a[href]`), in order. */
  get links(): string[] {
    return this.#links().map(text)
  }

  /** The current page (`aria-current="page"`), or `null` when no crumb is marked. */
  get current(): string | null {
    const current = this.list.querySelector('[aria-current="page"]')
    return current ? text(current) : null
  }

  /** Whether some crumbs are collapsed into an ellipsis (the styled Breadcrumb's `Ellipsis`). */
  get isCollapsed(): boolean {
    return this.queryPart('ellipsis') !== null
  }

  /** The link whose text is `name`. Throws when there is none. */
  link(name: string): HTMLAnchorElement {
    const found = this.#links().find(link => text(link) === name)
    if (!found) throw new NotFoundError(`no link "${name}" in ${this}`)
    return found
  }

  /** Clicks the link whose text is `name`, as a user would. */
  async clickLink(name: string): Promise<void> {
    await click(this.link(name))
  }

  #links(): HTMLAnchorElement[] {
    return [...this.list.querySelectorAll<HTMLAnchorElement>('a[href]')]
  }
}
