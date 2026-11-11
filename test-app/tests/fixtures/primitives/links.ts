import { click, triggerEvent } from '@ember/test-helpers'
import { Harness } from '@ember-joinery/test-support'

/**
 * Plain `<a href>` links, as the routing tests render them: a `data-test-jn="links"` root
 * (a `<nav>`, say) with a `link` part for each, named by its `data-test-jn-value`.
 *
 *   <nav aria-label="Pages" data-test-jn="links">
 *     <a href="/foo" data-test-jn-part="link" data-test-jn-value="foo">Foo</a>
 *   </nav>
 */
export class LinksHarness extends Harness {
  static override component = 'links'

  link(name: string): HTMLAnchorElement {
    return this.part<HTMLAnchorElement>('link', name)
  }

  /** Every link's name, in document order. */
  get names(): string[] {
    return this.values('link')
  }

  /** The links marked as the current page (`aria-current="page"`), by name. */
  get current(): string[] {
    return this.parts('link')
      .filter(link => link.getAttribute('aria-current') === 'page')
      .map(link => link.getAttribute('data-test-jn-value')!)
  }

  /** The text of each link marked as the current page. */
  get currentLabels(): string[] {
    return this.parts('link')
      .filter(link => link.getAttribute('aria-current') === 'page')
      .map(link => link.textContent!.trim())
  }

  /** Clicks the link, as a user does. */
  async follow(name: string): Promise<void> {
    await click(this.link(name))
  }

  /** Clicks what is inside the link (an icon, a span), as a user does. */
  async followFrom(name: string): Promise<void> {
    await click(this.link(name).firstElementChild!)
  }

  /** A click with a modifier key or another button: `{ metaKey: true }`, `{ button: 1 }`. */
  async clickWith(name: string, init: { button?: number; metaKey?: boolean }): Promise<void> {
    await triggerEvent(this.link(name), 'click', { button: 0, ...init })
  }
}
