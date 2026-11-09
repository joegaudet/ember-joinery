import { find, getRootElement } from '@ember/test-helpers'
import { Harness } from './harness.ts'

/** An element, or a selector for one in the test's root. */
type Findable = Element | string

function resolve(target: Findable): Element | null {
  return typeof target === 'string' ? find(target) : target
}

/**
 * The first element matching `query` in the shadow root of `root` (an element, or a selector),
 * or `null` when there is no such root or element. It is ember-primitives' `findInShadow`.
 *
 *   assert.dom(findInShadow('[data-preview]', 'h1')).hasText('Welcome')
 */
export function findInShadow(root: Findable, query: string): Element | null {
  return resolve(root)?.shadowRoot?.querySelector(query) ?? null
}

/** Whether an element has a shadow root (an open one). It is ember-primitives' `hasShadowRoot`. */
export function hasShadowRoot(element: Element): boolean {
  return Boolean(element.shadowRoot)
}

/**
 * The first element with a shadow root inside `root` (an element or a selector), or inside the
 * test's root without one. It is ember-primitives' `findShadow`.
 */
export function findShadow(root?: Findable): Element | null {
  const scope = root === undefined ? getRootElement() : resolve(root)
  if (!scope) return null
  for (const element of scope.querySelectorAll('*')) {
    if (element.shadowRoot) return element
  }
  return null
}

/**
 * The first element matching `query` in the first shadow root in the test. Use `findInShadow`
 * when there are several. It is ember-primitives' `findInFirstShadow`.
 */
export function findInFirstShadow(query: string): Element | null {
  const host = findShadow()
  if (!host) throw new Error('Joinery: findInFirstShadow found no element with a shadow root')
  return findInShadow(host, query)
}

/**
 * Drives a `<Shadowed>` from `@ember-joinery/primitives/shadowed`: its shadow root, and what is
 * rendered there. Harnesses don't look into shadow roots, so find what's inside through this.
 *
 *   const preview = new ShadowedHarness('preview')   // <Shadowed @name="preview">
 *   assert.dom(preview.query('h1')).hasText('Welcome')
 */
export class ShadowedHarness extends Harness {
  static override component = 'shadowed'

  /** The element the shadow root is attached to: the `<div>` inside the component's own. */
  get host(): HTMLElement {
    const host = [...this.element.children].find(child => child.shadowRoot)
    if (!host) throw new Error(`Joinery harness: ${this} has no shadow root`)
    return host as HTMLElement
  }

  /** The shadow root. */
  get shadowRoot(): ShadowRoot {
    return this.host.shadowRoot!
  }

  /** The element the content renders in, inside the shadow root. */
  get content(): HTMLElement {
    return this.shadowRoot.lastElementChild as HTMLElement
  }

  /** The first element in the shadow root matching `selector`, or `null`. */
  query<E extends Element = HTMLElement>(selector: string): E | null {
    return this.shadowRoot.querySelector<E>(selector)
  }

  /** Every element in the shadow root matching `selector`. */
  queryAll<E extends Element = HTMLElement>(selector: string): E[] {
    return [...this.shadowRoot.querySelectorAll<E>(selector)]
  }

  /** The text of what renders in the shadow root, whitespace collapsed. */
  get text(): string {
    return (this.content.textContent ?? '').replace(/\s+/g, ' ').trim()
  }

  /** The style sheets that apply in the shadow root: its own and the ones it adopted. */
  get styleSheetCount(): number {
    return this.shadowRoot.styleSheets.length + this.shadowRoot.adoptedStyleSheets.length
  }
}
