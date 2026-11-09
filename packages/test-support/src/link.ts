import { click } from '@ember/test-helpers'
import { Harness } from './harness.ts'

/**
 * Drives a `<Link>` from `@ember-joinery/primitives/link`, internal or external: where it goes,
 * whether it is the current page (read from `aria-current`), whether it leaves the app, and
 * following it.
 *
 *   const forum = new LinkHarness('forum')   // <Link @name="forum">
 *   await forum.follow()
 *   assert.true(forum.isCurrent)
 */
export class LinkHarness extends Harness {
  static override component: string | readonly string[] = ['link', 'external-link']

  /** Its `href`, as written. */
  get href(): string | null {
    return this.element.getAttribute('href')
  }

  /** The text it shows, whitespace collapsed. */
  get text(): string {
    return (this.element.textContent ?? '').replace(/\s+/g, ' ').trim()
  }

  /**
   * Its `aria-current`: `page` on the current route, `true` on a link active on the routes
   * below its own (`@activeOnSubPaths`), and `null` when it isn't current.
   */
  get current(): string | null {
    return this.element.getAttribute('aria-current')
  }

  /** Whether it is the current page, or a section the current page is in (`aria-current`). */
  get isCurrent(): boolean {
    const current = this.current
    return current !== null && current !== 'false'
  }

  /** Whether it opens in a new tab (`target="_blank"`), as a link that leaves the app does. */
  get opensInNewTab(): boolean {
    return this.element.getAttribute('target') === '_blank'
  }

  /**
   * Whether the page it opens is told nothing about this one: `rel` has `noopener` and
   * `noreferrer`.
   */
  get isIsolated(): boolean {
    const rel = (this.element.getAttribute('rel') ?? '').split(/\s+/)
    return rel.includes('noopener') && rel.includes('noreferrer')
  }

  /** Clicks it, as a user would: a link to one of the app's routes transitions. */
  async follow(): Promise<void> {
    await click(this.element)
  }
}

/**
 * Drives an `<ExternalLink>` from `@ember-joinery/primitives/external-link`: a `LinkHarness`
 * that drives only those.
 *
 *   const mdn = new ExternalLinkHarness()
 *   assert.true(mdn.opensInNewTab && mdn.isIsolated)
 */
export class ExternalLinkHarness extends LinkHarness {
  static override component = 'external-link'
}
