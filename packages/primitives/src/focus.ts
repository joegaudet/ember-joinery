import Modifier from 'ember-modifier'
import { registerDestructor } from '@ember/destroyable'

/*
 * Finding and moving focus: what ember-primitives' components get from tabster, without tabster
 * or any setup. ember-primitives asks an app to call `setupTabster()` before its keyboard support
 * works; Joinery's components work as soon as they render. What tabster did for them:
 *
 * - its Mover (arrow keys between items) is `@ember-joinery/primitives/roving-focus`;
 * - its Modalizer and focus trapping are `@ember-joinery/primitives/focus-scope`;
 * - its Deloser (focus that doesn't fall to `<body>` when the focused element goes) is
 *   `restoreFocus`, below;
 * - its `focusable.findFirst()` and friends are `focusable`, below.
 */

/** Where `focusable` looks, and what it counts. */
export interface FocusableQuery {
  /** The element to look in. The container itself is never one of the results. */
  container: Element
  /**
   * Also count elements only script can focus, with `tabindex="-1"` (menu items, listbox
   * options), as tabster's `includeProgrammaticallyFocusable`. Default: only those the Tab key
   * reaches.
   */
  includeProgrammaticallyFocusable?: boolean
  /** Count only the elements this accepts. */
  accept?: (element: HTMLElement) => boolean
}

/** A `FocusableQuery` that starts from an element, for `findNext` and `findPrev`. */
export interface FocusableQueryFrom extends FocusableQuery {
  /** The element to start from. It needn't be focusable itself. */
  currentElement: Element
}

/**
 * Whether nothing inside `element`, itself included, can take focus: it is inert, hidden, not
 * displayed, or inside a closed `<details>` (all but its summary).
 */
function hidesSubtree(element: Element, styles: CSSStyleDeclaration): boolean {
  if (element.hasAttribute('inert')) return true
  if (element instanceof HTMLElement && element.hidden) return true
  if (styles.display === 'none') return true
  const parent = element.parentElement
  if (parent instanceof HTMLDetailsElement && !parent.open) {
    return element !== parent.querySelector(':scope > summary')
  }
  return false
}

/** Whether `element` itself can take focus, given that nothing above it hides it. */
function isCandidate(
  element: Element,
  styles: CSSStyleDeclaration,
  programmatic: boolean,
): element is HTMLElement {
  if (!(element instanceof HTMLElement)) return false
  // :disabled also covers the controls in a disabled <fieldset>, whose own `disabled` is false.
  if (element.matches(':disabled')) return false
  if (element instanceof HTMLInputElement && element.type === 'hidden') return false
  if (styles.visibility === 'hidden') return false
  // A link without an href reports a tabIndex of 0, but takes no focus unless given a tabindex.
  const hasTabindex = element.hasAttribute('tabindex')
  if (element instanceof HTMLAnchorElement && !element.hasAttribute('href') && !hasTabindex) {
    return false
  }
  if (element.tabIndex >= 0) return true
  return programmatic && hasTabindex
}

/**
 * The focusable elements in `container`, in document order. An element counts when it is
 * enabled, displayed, visible and not inert, and either the Tab key reaches it (`tabIndex` of 0
 * or more) or, with `includeProgrammaticallyFocusable`, it has a `tabindex` of its own. Positive
 * tabindexes don't reorder the list, as in Radix and tabster.
 */
function findAll(query: FocusableQuery): HTMLElement[] {
  const { container, accept } = query
  const programmatic = query.includeProgrammaticallyFocusable ?? false
  const found: HTMLElement[] = []
  const walker = document.createTreeWalker(container, NodeFilter.SHOW_ELEMENT, {
    acceptNode(node) {
      const element = node as Element
      const styles = getComputedStyle(element)
      if (hidesSubtree(element, styles)) return NodeFilter.FILTER_REJECT
      if (!isCandidate(element, styles, programmatic)) return NodeFilter.FILTER_SKIP
      return accept && !accept(element) ? NodeFilter.FILTER_SKIP : NodeFilter.FILTER_ACCEPT
    },
  })
  while (walker.nextNode()) found.push(walker.currentNode as HTMLElement)
  return found
}

function precedes(a: Node, b: Node): boolean {
  return Boolean(a.compareDocumentPosition(b) & Node.DOCUMENT_POSITION_FOLLOWING)
}

/**
 * Finds focusable elements, as tabster's `focusable` API does for ember-primitives. Hidden,
 * disabled and inert elements are skipped, by the same rules everywhere Joinery moves focus.
 *
 *   focusable.findFirst({ container: this.element })
 *   focusable.findNext({ container: list, currentElement: option, includeProgrammaticallyFocusable: true })
 */
export const focusable = {
  /** Every focusable element in the container, in document order. */
  findAll,

  /** The first focusable element in the container. */
  findFirst(query: FocusableQuery): HTMLElement | undefined {
    return findAll(query)[0]
  },

  /** The last focusable element in the container. */
  findLast(query: FocusableQuery): HTMLElement | undefined {
    return findAll(query).at(-1)
  },

  /** The first focusable element after `currentElement`, in document order. It doesn't wrap. */
  findNext(query: FocusableQueryFrom): HTMLElement | undefined {
    const current = query.currentElement
    return findAll(query).find(
      element => element !== current && !element.contains(current) && precedes(current, element),
    )
  },

  /** The last focusable element before `currentElement`, in document order. It doesn't wrap. */
  findPrev(query: FocusableQueryFrom): HTMLElement | undefined {
    const current = query.currentElement
    return findAll(query)
      .reverse()
      .find(element => element !== current && precedes(element, current))
  },

  /**
   * Whether an element can take focus now, by the same rules: it is connected, and neither it
   * nor anything above it hides it. Elements with `tabindex="-1"` count unless
   * `includeProgrammaticallyFocusable` is `false`.
   */
  isFocusable(element: Element, options: { includeProgrammaticallyFocusable?: boolean } = {}) {
    if (!element.isConnected) return false
    const styles = getComputedStyle(element)
    if (!isCandidate(element, styles, options.includeProgrammaticallyFocusable ?? true)) {
      return false
    }
    for (let node: Element | null = element; node; node = node.parentElement) {
      if (hidesSubtree(node, node === element ? styles : getComputedStyle(node))) return false
    }
    return true
  },
}

/** How `focusElement` and `focusFirst` focus. */
export interface FocusOptions {
  /** Select the text of an input it focuses, as Radix does when a focus scope moves focus. */
  select?: boolean
  /** Don't scroll the element into view. */
  preventScroll?: boolean
}

/**
 * Focuses an element, if it's there and can take focus, selecting an input's text with
 * `select`. Returns whether focus is on it afterwards.
 */
export function focusElement(
  element: Element | null | undefined,
  { select = false, preventScroll = false }: FocusOptions = {},
): boolean {
  if (!(element instanceof HTMLElement || element instanceof SVGElement)) return false
  const previous = document.activeElement
  element.focus({ preventScroll })
  if (element !== previous && select && element instanceof HTMLInputElement) element.select()
  return document.activeElement === element
}

/**
 * Focuses the first of `candidates` that takes focus, as Radix's `focusFirst` does: each is
 * tried in turn until focus moves. It stops at the element that already has focus, so a list of
 * "the items after this one" never moves focus past where it started. Returns whether focus
 * moved.
 */
export function focusFirst(
  candidates: Iterable<Element | null | undefined>,
  options: FocusOptions = {},
): boolean {
  const previous = document.activeElement
  for (const candidate of candidates) {
    if (!candidate) continue
    if (candidate === previous) return false
    focusElement(candidate, options)
    if (document.activeElement !== previous) return true
  }
  return false
}

// ----- restoreFocus: tabster's Deloser -----------------------------------------------------------

const HISTORY_LENGTH = 10

/** The elements focused most recently anywhere on the page, newest first, while anyone asks. */
let history: WeakRef<HTMLElement>[] = []
let listening = 0

function unshift(list: WeakRef<HTMLElement>[], element: HTMLElement): WeakRef<HTMLElement>[] {
  return [new WeakRef(element), ...list.filter(ref => ref.deref() !== element)].slice(
    0,
    HISTORY_LENGTH,
  )
}

function remember(event: FocusEvent): void {
  if (event.target instanceof HTMLElement) history = unshift(history, event.target)
}

function listen(): () => void {
  if (listening++ === 0) document.addEventListener('focusin', remember, true)
  return () => {
    if (--listening > 0) return
    document.removeEventListener('focusin', remember, true)
    history = []
  }
}

/** Whether focus has fallen to `<body>`: nothing is focused. */
function focusIsLost(): boolean {
  const active = document.activeElement
  return !active || active === document.body || active === document.documentElement
}

interface RestoreFocusSignature {
  Element: HTMLElement
  Args: {
    Named: {
      /**
       * The element to move focus to first, when it is inside and can take focus: the selected
       * tab, say. tabster calls it the default.
       */
      preferred?: HTMLElement | null
      /**
       * Called with the element focus is about to move to. Return `false` to leave focus where
       * it fell and handle it yourself, as with tabster's `DeloserFocusLostEvent`.
       */
      onRestore?: (next: HTMLElement) => boolean | void
    }
  }
}

/**
 * Keeps focus from falling to `<body>` when the focused element inside this one is removed, as
 * tabster's Deloser does for ember-primitives' Tabs and Menu. Focus moves to, in order:
 *
 * 1. `preferred`, when it is inside and can take focus (tabster's default element);
 * 2. the element focused most recently inside it that is still there and can take focus;
 * 3. its first focusable element (or itself, if it can take focus);
 * 4. and when this element itself is removed with focus inside, the element focused most
 *    recently outside it, such as the trigger that opened a menu.
 *
 *   <ul {{restoreFocus}}>
 *     {{#each this.items as |item|}}
 *       <li><button type="button" {{on "click" (fn this.remove item)}}>Remove {{item}}</button></li>
 *     {{/each}}
 *   </ul>
 *
 * It acts only when the focused element was removed, so focus a user moves elsewhere (to
 * `<body>`, by clicking the page) stays there.
 */
export class restoreFocus extends Modifier<RestoreFocusSignature> {
  #onRestore: ((next: HTMLElement) => boolean | void) | undefined
  #preferred: HTMLElement | null | undefined
  #installed = false
  /** What was focused inside, newest first. */
  #inside: WeakRef<HTMLElement>[] = []
  /** The element inside that has focus, as last seen, or `undefined` once focus moved out. */
  #focused: HTMLElement | undefined
  /** What had focus outside when this element appeared. */
  #before: HTMLElement | undefined

  override modify(element: HTMLElement, _: [], named: RestoreFocusSignature['Args']['Named']) {
    this.#onRestore = named.onRestore
    this.#preferred = named.preferred
    if (this.#installed) return
    this.#installed = true

    const active = document.activeElement
    if (active instanceof HTMLElement) {
      if (element.contains(active)) this.#focused = active
      else if (!focusIsLost()) this.#before = active
    }

    const unlisten = listen()
    const onFocusIn = (event: FocusEvent) => {
      if (!(event.target instanceof HTMLElement)) return
      this.#focused = event.target
      this.#inside = unshift(this.#inside, event.target)
    }
    const onFocusOut = (event: FocusEvent) => {
      const next = event.relatedTarget
      const target = event.target
      if (next instanceof Node && element.contains(next)) return
      if (next !== null) {
        this.#focused = undefined
        return
      }
      // Focus went nowhere: blurred, or its element removed. If it's still there, it was blurred.
      queueMicrotask(() => {
        if (this.#focused === target && target instanceof Node && target.isConnected) {
          this.#focused = undefined
        }
      })
    }
    element.addEventListener('focusin', onFocusIn)
    element.addEventListener('focusout', onFocusOut)

    const observer = new MutationObserver(() => {
      if (!this.#lostInside(element)) return
      this.#focused = undefined
      this.#restore(this.#findInside(element))
    })
    observer.observe(element, { childList: true, subtree: true })

    registerDestructor(this, () => {
      observer.disconnect()
      element.removeEventListener('focusin', onFocusIn)
      element.removeEventListener('focusout', onFocusOut)
      const focused = this.#focused
      const outside = [...history.map(ref => ref.deref()), this.#before].filter(
        (candidate): candidate is HTMLElement => !!candidate && !element.contains(candidate),
      )
      unlisten()
      // The element is on its way out. Once it's gone, if focus went with it, find focus a place.
      queueMicrotask(() => {
        if (!focused || element.isConnected || focused.isConnected || !focusIsLost()) return
        this.#restore(outside.find(candidate => focusable.isFocusable(candidate)))
      })
    })
  }

  /** Whether the element that had focus inside has been removed, and focus fell to `<body>`. */
  #lostInside(element: HTMLElement): boolean {
    const focused = this.#focused
    if (!focused || !focusIsLost()) return false
    return !focused.isConnected || !element.contains(focused)
  }

  /** Where focus goes when the focused element inside is removed. */
  #findInside(element: HTMLElement): HTMLElement | undefined {
    const preferred = this.#preferred
    if (preferred && element.contains(preferred) && focusable.isFocusable(preferred)) {
      return preferred
    }
    for (const ref of this.#inside) {
      const candidate = ref.deref()
      if (candidate && element.contains(candidate) && focusable.isFocusable(candidate)) {
        return candidate
      }
    }
    return (
      focusable.findFirst({ container: element }) ??
      (focusable.isFocusable(element) ? element : undefined)
    )
  }

  #restore(next: HTMLElement | undefined): void {
    if (!next) return
    if (this.#onRestore?.(next) === false) return
    focusElement(next, { preventScroll: true })
  }
}
