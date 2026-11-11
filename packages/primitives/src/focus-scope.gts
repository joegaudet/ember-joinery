import Modifier from 'ember-modifier'
import { registerDestructor } from '@ember/destroyable'
import { buildWaiter } from '@ember/test-waiters'
import type { TOC } from '@ember/component/template-only'
import { As, type TagName } from './as.gts'
import { focusElement, focusFirst, focusable } from './focus.ts'

const waiter = buildWaiter('@ember-joinery/primitives:focus-scope')

/** The event a scope sends its own element before it moves focus in. */
export const AUTOFOCUS_ON_MOUNT = 'focusScope.autoFocusOnMount'
/** The event a scope sends its own element before it returns focus. */
export const AUTOFOCUS_ON_UNMOUNT = 'focusScope.autoFocusOnUnmount'

const EVENT_OPTIONS = { bubbles: false, cancelable: true }

/** What a focus scope does, as Radix's `FocusScope` props. */
export interface FocusScopeOptions {
  /**
   * Keep focus inside: Tab and Shift+Tab stop at the edges, and focus that leaves any other
   * way (a click, a script) is brought back. Default `false`.
   */
  trapped?: boolean
  /** Tab from the last element goes to the first, and Shift+Tab from the first to the last. */
  loop?: boolean
  /**
   * Called before the scope moves focus in, when it starts. Call `event.preventDefault()` to
   * move focus yourself (or leave it where it is).
   */
  onMountAutoFocus?: (event: Event) => void
  /**
   * Called before the scope returns focus to where it was, when it ends. Call
   * `event.preventDefault()` to send focus somewhere else.
   */
  onUnmountAutoFocus?: (event: Event) => void
}

/** A focus scope started with `createFocusScope`. */
export interface FocusScopeHandle {
  /** Whether a newer scope has paused this one; a paused scope traps nothing. */
  readonly paused: boolean
  /** Applies new options. */
  update(options: FocusScopeOptions): void
  /** Ends the scope. Unless prevented, focus returns to where it was when the scope started. */
  destroy(): void
}

// ----- Focus guards ------------------------------------------------------------------------

const GUARD = 'data-jn-focus-guard'
let guards = 0

function createGuard(): HTMLSpanElement {
  const guard = document.createElement('span')
  guard.setAttribute(GUARD, '')
  guard.tabIndex = 0
  // Through the CSSOM, which a strict Content Security Policy allows.
  for (const [property, value] of [
    ['outline', 'none'],
    ['opacity', '0'],
    ['position', 'fixed'],
    ['pointer-events', 'none'],
  ]) {
    guard.style.setProperty(property!, value!)
  }
  return guard
}

/**
 * Puts a focusable, invisible element at each end of `<body>`, as Radix's `FocusGuards` does,
 * so that tabbing out of the page's first or last element lands on something in the page,
 * which a focus trap or an outside-focus check can see, rather than in the browser's toolbar.
 * The guards are shared: they go when the last caller releases them. A trapped focus scope adds
 * them while it traps; overlays that aren't trapped can add them too.
 *
 *   const release = addFocusGuards()
 *   // …
 *   release()
 */
export function addFocusGuards(): () => void {
  const existing = document.querySelectorAll(`[${GUARD}]`)
  document.body.insertAdjacentElement('afterbegin', existing[0] ?? createGuard())
  document.body.insertAdjacentElement('beforeend', existing[1] ?? createGuard())
  guards += 1
  let released = false
  return () => {
    if (released) return
    released = true
    if (guards === 1) document.querySelectorAll(`[${GUARD}]`).forEach(guard => guard.remove())
    guards -= 1
  }
}

// ----- The scope stack -----------------------------------------------------------------------

/** Every live scope, newest first. Only the newest traps; starting one pauses the one before. */
let stack: Scope[] = []

function push(scope: Scope): void {
  const active = stack[0]
  if (scope !== active) active?.pause()
  stack = [scope, ...stack.filter(other => other !== scope)]
}

function pop(scope: Scope): void {
  stack = stack.filter(other => other !== scope)
  stack[0]?.resume()
}

function removeLinks(elements: HTMLElement[]): HTMLElement[] {
  return elements.filter(element => element.tagName !== 'A')
}

/** Focuses as a scope does: without scrolling, and selecting an input's text. */
function focusInScope(element: Element | null | undefined): void {
  focusElement(element, { select: true, preventScroll: true })
}

class Scope implements FocusScopeHandle {
  paused = false
  readonly #container: HTMLElement
  #options: FocusScopeOptions
  readonly #previouslyFocused: Element | null
  #lastFocused: HTMLElement | null = null
  #untrap: (() => void) | undefined
  #destroyed = false

  constructor(container: HTMLElement, options: FocusScopeOptions) {
    this.#container = container
    this.#options = options
    container.addEventListener('keydown', this.#onKeyDown)
    container.addEventListener(AUTOFOCUS_ON_MOUNT, this.#onMountAutoFocus)
    this.#updateTrap()

    push(this)
    this.#previouslyFocused = document.activeElement
    // Moving focus now would run focus handlers in the middle of a render, so it waits until the
    // render is over, as Radix's effect does.
    const token = waiter.beginAsync()
    queueMicrotask(() => {
      try {
        if (!this.#destroyed) this.#autoFocus()
      } finally {
        waiter.endAsync(token)
      }
    })
  }

  pause(): void {
    this.paused = true
  }

  resume(): void {
    this.paused = false
  }

  update(options: FocusScopeOptions): void {
    this.#options = options
    this.#updateTrap()
  }

  destroy(): void {
    if (this.#destroyed) return
    this.#destroyed = true
    const container = this.#container
    container.removeEventListener('keydown', this.#onKeyDown)
    container.removeEventListener(AUTOFOCUS_ON_MOUNT, this.#onMountAutoFocus)
    this.#untrap?.()
    this.#untrap = undefined

    // As in Radix, focus returns once the element has gone, after anything else that is closing.
    const token = waiter.beginAsync()
    setTimeout(() => {
      try {
        const event = new CustomEvent(AUTOFOCUS_ON_UNMOUNT, EVENT_OPTIONS)
        container.addEventListener(AUTOFOCUS_ON_UNMOUNT, this.#onUnmountAutoFocus)
        container.dispatchEvent(event)
        container.removeEventListener(AUTOFOCUS_ON_UNMOUNT, this.#onUnmountAutoFocus)
        if (!event.defaultPrevented) focusInScope(this.#previouslyFocused ?? document.body)
        pop(this)
      } finally {
        waiter.endAsync(token)
      }
    }, 0)
  }

  #onMountAutoFocus = (event: Event) => this.#options.onMountAutoFocus?.(event)
  #onUnmountAutoFocus = (event: Event) => this.#options.onUnmountAutoFocus?.(event)

  /** Moves focus in, unless it is already inside: to the first tabbable element, or the scope. */
  #autoFocus(): void {
    const container = this.#container
    const previouslyFocused = document.activeElement
    if (container.contains(previouslyFocused)) return
    const event = new CustomEvent(AUTOFOCUS_ON_MOUNT, EVENT_OPTIONS)
    container.dispatchEvent(event)
    if (event.defaultPrevented) return
    focusFirst(removeLinks(focusable.findAll({ container })), {
      select: true,
      preventScroll: true,
    })
    if (document.activeElement === previouslyFocused) focusInScope(container)
  }

  #updateTrap(): void {
    const trapped = Boolean(this.#options.trapped)
    if (trapped === Boolean(this.#untrap)) return
    if (trapped) this.#untrap = this.#trap()
    else {
      this.#untrap?.()
      this.#untrap = undefined
    }
  }

  /** Starts trapping focus; returns the function that stops it. */
  #trap(): () => void {
    const container = this.#container
    const onFocusIn = (event: FocusEvent) => {
      if (this.paused) return
      const target = event.target
      if (target instanceof HTMLElement && container.contains(target)) this.#lastFocused = target
      else focusInScope(this.#lastFocused)
    }
    const onFocusOut = (event: FocusEvent) => {
      if (this.paused) return
      const next = event.relatedTarget
      // Focus going nowhere (the window losing it, or the element being removed) is left alone.
      if (next === null) return
      if (!(next instanceof Node) || !container.contains(next)) focusInScope(this.#lastFocused)
    }
    // When the focused element is removed, focus falls to <body>; bring it back to the scope.
    const observer = new MutationObserver(records => {
      if (document.activeElement !== document.body) return
      if (records.some(record => record.removedNodes.length > 0)) focusInScope(container)
    })
    document.addEventListener('focusin', onFocusIn)
    document.addEventListener('focusout', onFocusOut)
    observer.observe(container, { childList: true, subtree: true })
    const releaseGuards = addFocusGuards()
    return () => {
      document.removeEventListener('focusin', onFocusIn)
      document.removeEventListener('focusout', onFocusOut)
      observer.disconnect()
      releaseGuards()
    }
  }

  /** Tab and Shift+Tab at the edges: stop there when trapped, and go round with `loop`. */
  #onKeyDown = (event: KeyboardEvent) => {
    const { loop, trapped } = this.#options
    if ((!loop && !trapped) || this.paused) return
    const isTab = event.key === 'Tab' && !event.altKey && !event.ctrlKey && !event.metaKey
    const focused = document.activeElement
    if (!isTab || !focused) return

    const tabbable = focusable.findAll({ container: this.#container })
    const first = tabbable[0]
    const last = tabbable.at(-1)
    if (!first || !last) {
      if (focused === this.#container) event.preventDefault()
    } else if (!event.shiftKey && focused === last) {
      event.preventDefault()
      if (loop) focusInScope(first)
    } else if (event.shiftKey && focused === first) {
      event.preventDefault()
      if (loop) focusInScope(last)
    }
  }
}

/**
 * Starts a focus scope on an element, as Radix's `FocusScope` does: focus moves in when it
 * starts (to the first tabbable element that isn't a link, or else the element itself), stays
 * in while `trapped`, wraps round with `loop`, and returns to where it was when the scope ends.
 * Scopes stack: starting one pauses the scope before it until it ends.
 *
 * The element should take focus itself, for when it has nothing else to focus: give it
 * `tabindex="-1"`. The `{{focusScope}}` modifier and `<FocusScope>` do this for you; use this
 * function from a component that manages the element itself.
 *
 *   const scope = createFocusScope(element, { trapped: true, loop: true })
 *   scope.update({ trapped: false })
 *   scope.destroy() // focus returns
 */
export function createFocusScope(
  container: HTMLElement,
  options: FocusScopeOptions = {},
): FocusScopeHandle {
  return new Scope(container, options)
}

interface FocusScopeModifierSignature {
  Element: HTMLElement
  Args: { Named: FocusScopeOptions }
}

/**
 * Makes any element a focus scope (see `createFocusScope`), for as long as it is rendered:
 *
 *   <div role="dialog" aria-label="Edit" {{focusScope trapped=true loop=true}}>…</div>
 *
 * It gives the element `tabindex="-1"` when it has no tabindex of its own.
 */
export class focusScope extends Modifier<FocusScopeModifierSignature> {
  #scope: FocusScopeHandle | undefined

  override modify(element: HTMLElement, _: [], named: FocusScopeOptions): void {
    const options: FocusScopeOptions = {
      trapped: named.trapped,
      loop: named.loop,
      onMountAutoFocus: named.onMountAutoFocus,
      onUnmountAutoFocus: named.onUnmountAutoFocus,
    }
    if (this.#scope) return this.#scope.update(options)

    const addedTabindex = !element.hasAttribute('tabindex')
    if (addedTabindex) element.setAttribute('tabindex', '-1')
    const scope = (this.#scope = createFocusScope(element, options))
    registerDestructor(this, () => {
      scope.destroy()
      if (addedTabindex) element.removeAttribute('tabindex')
    })
  }
}

export interface FocusScopeSignature {
  Args: FocusScopeOptions & {
    /** The tag to render. Default `div`. */
    as?: TagName
  }
  Blocks: { default: [] }
  Element: HTMLElement
}

/**
 * A focus scope as an element, as Radix's `FocusScope`: a `<div tabindex="-1">` (or `@as`)
 * whose focus moves in when it renders, stays in while `@trapped`, wraps round with `@loop`, and
 * returns to where it was when it goes.
 *
 *   {{#if this.open}}
 *     <FocusScope @trapped={{true}} @loop={{true}} role="dialog" aria-label="Edit">…</FocusScope>
 *   {{/if}}
 *
 * It wraps content, so, like `DirectionProvider`, it isn't a component root for the harnesses:
 * the parts inside still belong to the component around them.
 */
export const FocusScope: TOC<FocusScopeSignature> = <template>
  <As
    @as={{@as}}
    @tag="div"
    tabindex="-1"
    data-slot="focus-scope"
    ...attributes
    {{focusScope
      trapped=@trapped
      loop=@loop
      onMountAutoFocus=@onMountAutoFocus
      onUnmountAutoFocus=@onUnmountAutoFocus
    }}
  >
    {{yield}}
  </As>
</template>
