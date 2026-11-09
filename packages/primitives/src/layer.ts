import Modifier from 'ember-modifier'
import { registerDestructor } from '@ember/destroyable'
import { buildWaiter } from '@ember/test-waiters'
import { registerDismissable, type DismissableLayer } from './dismiss.ts'

/**
 * How a layer behaves in the top layer, as the Popover API's `popover` attribute:
 *
 * - `manual` stays until it is removed. Joinery's components use it, with the dismiss stack
 *   (`dismissable`) deciding when Escape or a pointer outside closes it.
 * - `auto` is the browser's own: Escape and a pointer outside close it (light dismiss), and
 *   opening one closes any other that isn't its ancestor. `onHide` tells you it closed.
 */
export type PopoverMode = 'auto' | 'manual'

export interface TopLayerOptions {
  /** `manual` (the default) or `auto`. See `PopoverMode`. */
  popover?: PopoverMode
  /**
   * The element that opened the layer, such as its trigger. An `auto` popover opened from
   * inside another one stays open with it when the trigger is that popover's.
   */
  source?: Element | null
  /**
   * Called when the browser hides the layer by itself: light dismiss of an `auto` popover, or
   * someone calling `hidePopover()`. Close the layer here, as its component's state.
   */
  onHide?: () => void
}

type PopoverElement = HTMLElement & {
  showPopover(options?: { source?: HTMLElement }): void
  hidePopover(): void
}

const waiter = buildWaiter('@ember-joinery/primitives:layer')

/** Whether the browser has the Popover API. Every supported browser does. */
export function supportsPopover(): boolean {
  return typeof HTMLElement !== 'undefined' && 'showPopover' in HTMLElement.prototype
}

/** Whether an element is in the top layer now: an open popover or a modal `<dialog>`. */
export function isInTopLayer(element: Element): boolean {
  try {
    return element.matches(':popover-open') || element.matches(':modal')
  } catch {
    return false
  }
}

class Entry {
  readonly element: PopoverElement
  options: TopLayerOptions
  readonly #original: string | null
  #showing = false
  #removed = false
  #layer: DismissableLayer | undefined

  constructor(element: HTMLElement, options: TopLayerOptions) {
    this.element = element as PopoverElement
    this.options = options
    this.#original = element.getAttribute('popover')
    // Set now, so the browser hides the element until it joins the top layer.
    element.setAttribute('popover', options.popover ?? 'manual')
    element.addEventListener('toggle', this.#onToggle)
  }

  show(): void {
    if (this.#removed || this.#showing || !this.element.isConnected) return
    const source = this.options.source
    try {
      this.element.showPopover(source instanceof HTMLElement ? { source } : undefined)
    } catch {
      return // not connected, or already shown by someone else
    }
    this.#showing = true
    // An auto popover is the browser's to dismiss; the stack only needs to know it's there,
    // so Escape and pointers go to it before the layers underneath.
    if (this.element.getAttribute('popover') === 'auto') {
      this.#layer = registerDismissable(this.element, {}, { native: true })
    }
  }

  update(options: TopLayerOptions): void {
    const mode = options.popover ?? 'manual'
    this.options = options
    if (this.element.getAttribute('popover') === mode) return
    // The browser only takes a new mode on a hidden popover.
    this.#hide()
    this.element.setAttribute('popover', mode)
    schedule(this)
  }

  remove(): void {
    this.#removed = true
    this.element.removeEventListener('toggle', this.#onToggle)
    this.#hide()
    if (this.#original === null) this.element.removeAttribute('popover')
    else this.element.setAttribute('popover', this.#original)
  }

  #hide(): void {
    this.#layer?.remove()
    this.#layer = undefined
    if (!this.#showing) return
    this.#showing = false
    try {
      this.element.hidePopover()
    } catch {
      // already hidden, or gone
    }
  }

  #onToggle = (event: Event): void => {
    if ((event as ToggleEvent).newState !== 'closed' || !this.#showing) return
    if (isInTopLayer(this.element)) return
    this.#showing = false
    this.#layer?.remove()
    this.#layer = undefined
    this.options.onHide?.()
  }
}

/** Layers waiting to be shown, once the render that added them is over. */
let pending: Set<Entry> | undefined

/**
 * Shows layers after the render, parents first. A modifier on a nested element is installed
 * before its parent's, and the top layer stacks in the order layers are shown, so showing them
 * in document order is what puts a nested layer above the one it is in.
 */
function schedule(entry: Entry): void {
  if (!pending) {
    const entries = (pending = new Set())
    const token = waiter.beginAsync()
    queueMicrotask(() => {
      pending = undefined
      const ordered = [...entries].sort((a, b) =>
        a.element.compareDocumentPosition(b.element) & Node.DOCUMENT_POSITION_FOLLOWING ? -1 : 1,
      )
      for (const each of ordered) each.show()
      waiter.endAsync(token)
    })
  }
  pending.add(entry)
}

interface TopLayerSignature {
  Element: HTMLElement
  Args: { Named: TopLayerOptions }
}

class TopLayerModifier extends Modifier<TopLayerSignature> {
  #entry: Entry | undefined

  override modify(element: HTMLElement, _: [], options: TopLayerOptions): void {
    if (this.#entry) return this.#entry.update({ ...options })
    const entry = (this.#entry = new Entry(element, { ...options }))
    registerDestructor(this, () => {
      pending?.delete(entry)
      entry.remove()
    })
    schedule(entry)
  }
}

/**
 * Puts the element in the browser's top layer while it is rendered, with the Popover API: above
 * everything else on the page, whatever its ancestors' `overflow`, `z-index` or `transform`, and
 * with no portal. It is how Joinery's popovers, menus and tooltips escape their containers.
 *
 *   {{#if this.open}}
 *     <div {{topLayer}} {{dismissable onDismiss=this.close}}>…</div>
 *   {{/if}}
 *
 * It sets `popover` (`manual` unless you pass `popover="auto"`) and calls `showPopover()` once
 * the render is over; when the element goes, it leaves the top layer. Layers stack in the order
 * they open, and a layer inside another always goes above it. The browser's own popover styles
 * apply (a border, padding, `Canvas` colours, `overflow: auto`, centred with `inset: 0` and
 * `margin: auto`): style the element over them, and anchor it with `anchorTo`.
 */
export const topLayer = TopLayerModifier
