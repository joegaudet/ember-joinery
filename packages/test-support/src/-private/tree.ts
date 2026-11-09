import { attributes } from '../selectors.ts'

/** Where a lookup runs: an element (usually a component's root) or the whole document. */
export type Scope = Element | Document

/** Thrown when a lookup finds nothing, so `exists` can tell absence from a mistake. */
export class NotFoundError extends Error {
  constructor(message: string) {
    super(`Joinery harness: ${message}`)
    this.name = 'NotFoundError'
  }
}

/** Thrown when a lookup finds the wrong thing, such as a harness pointed at another component. */
export class HarnessError extends Error {
  constructor(message: string) {
    super(`Joinery harness: ${message}`)
    this.name = 'HarnessError'
  }
}

function isDocument(scope: Scope): scope is Document {
  return scope.nodeType === Node.DOCUMENT_NODE
}

/**
 * The element's parent in the component tree. A portalled or top-layer part names its root in
 * `data-test-jn-owner`, so it hangs under that root wherever it sits in the document; every
 * other element hangs under its DOM parent. An owner id that matches nothing falls back to the
 * DOM parent.
 */
export function logicalParent(element: Element): Element | null {
  const owner = element.getAttribute(attributes.owner)
  if (owner) {
    const root = element.ownerDocument.getElementById(owner)
    if (root && root !== element) return root
  }
  return element.parentElement
}

/** The element's ancestors in the component tree, nearest first. A cycle ends the walk. */
function* ancestors(element: Element): Generator<Element> {
  const seen = new Set<Element>([element])
  let current = logicalParent(element)
  while (current && !seen.has(current)) {
    seen.add(current)
    yield current
    current = logicalParent(current)
  }
}

/** Whether `element` is inside `scope` in the component tree. An element isn't inside itself. */
export function isWithin(element: Element, scope: Scope): boolean {
  if (isDocument(scope)) return element.ownerDocument === scope && element.isConnected
  for (const ancestor of ancestors(element)) {
    if (ancestor === scope) return true
  }
  return false
}

/** The root of the component instance an element belongs to: its nearest `data-test-jn` ancestor. */
export function componentOf(element: Element): Element | null {
  for (const ancestor of ancestors(element)) {
    if (ancestor.hasAttribute(attributes.component)) return ancestor
  }
  return null
}

/**
 * The elements matching `selector` inside `scope` in the component tree, in document order.
 * The search covers the whole document, because a portalled part can be anywhere in it.
 */
export function findWithin(scope: Scope, selector: string): Element[] {
  const document = isDocument(scope) ? scope : scope.ownerDocument
  return [...document.querySelectorAll(selector)].filter(element => isWithin(element, scope))
}

/** `<div id="x" class="a b">` as `div#x.a.b`, for error messages. */
export function describeElement(element: Element): string {
  const id = element.id ? `#${element.id}` : ''
  const classes = [...element.classList].map(name => `.${name}`).join('')
  return `${element.localName}${id}${classes}`
}
