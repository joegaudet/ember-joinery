import Modifier from 'ember-modifier'
import { registerDestructor } from '@ember/destroyable'

/** A pointer that went down outside a layer: cancel it (`preventDefault()`) to keep the layer. */
export type PointerDownOutsideEvent = CustomEvent<{ originalEvent: PointerEvent }>

/** Focus that moved outside a layer: cancel it (`preventDefault()`) to keep the layer. */
export type FocusOutsideEvent = CustomEvent<{ originalEvent: FocusEvent }>

/** Why a layer was dismissed. */
export type DismissReason = 'escape-key' | 'pointer-outside' | 'focus-outside'

export interface DismissableOptions {
  /**
   * Called when the layer should close: Escape while it is the top layer, or a pointer or
   * focus outside it, unless a handler below cancelled the event. Close the layer here.
   */
  onDismiss?: (reason: DismissReason) => void
  /** Escape was pressed while this is the top layer. `preventDefault()` keeps it open. */
  onEscapeKeyDown?: (event: KeyboardEvent) => void
  /** A pointer went down outside the layer. `preventDefault()` keeps it open. */
  onPointerDownOutside?: (event: PointerDownOutsideEvent) => void
  /** Focus moved outside the layer. `preventDefault()` keeps it open. */
  onFocusOutside?: (event: FocusOutsideEvent) => void
  /** Either of the two above, after its own handler. `preventDefault()` keeps it open. */
  onInteractOutside?: (event: PointerDownOutsideEvent | FocusOutsideEvent) => void
  /**
   * Make everything outside this layer (and the layers above it) ignore the pointer, as a
   * modal menu does: `pointer-events: none` on `<body>`, and `auto` on the layers that still
   * take it. Layers below this one stop hearing pointers outside them, too.
   */
  disableOutsidePointerEvents?: boolean
  /**
   * Elements that count as part of the layer, though they are outside it: usually the trigger
   * that opened it, so pressing the trigger toggles the layer instead of dismissing it first.
   * A layer whose element or trigger is inside another layer is nested in that one.
   */
  inside?: ReadonlyArray<Element | null | undefined>
  /** Turn the layer's dismissal off for now, keeping its place in the stack. Default `true`. */
  enabled?: boolean
}

/** A layer in the dismiss stack, as `registerDismissable` returns it. */
export interface DismissableLayer {
  /** The layer's element. */
  readonly element: Element
  /** Whether this is the top layer now, the one Escape closes. */
  readonly isTop: boolean
  /** Replaces the layer's options (its place in the stack stays). */
  update(options: DismissableOptions): void
  /** Takes the layer off the stack. */
  remove(): void
}

interface Layer {
  element: Element
  options: DismissableOptions
  /** When it joined the stack: events from before then (the click that opened it) don't count. */
  since: number
  /** A layer the browser dismisses itself: a `popover="auto"` in the top layer. */
  native: boolean
  /** The element's own `pointer-events`, put back when the stack stops setting it. */
  pointerEvents: string | undefined
}

const POINTER_DOWN_OUTSIDE = 'joinery.pointerDownOutside'
const FOCUS_OUTSIDE = 'joinery.focusOutside'

/** The stack, bottom first: a layer comes after every layer it is nested in. */
const layers: Layer[] = []
/** Elements inside every layer, such as a toast region (`{{dismissableBranch}}`). */
const branches = new Set<Element>()

let listening: Document | undefined
let bodyPointerEvents: string | undefined
let pointerEventsDisabled = false

/** The layers an in-progress pointer went down inside, found before the target's handlers ran. */
const pointerInside = new WeakMap<Event, Set<Layer>>()
let pendingTouch: (() => void) | undefined

function enabled(layer: Layer): boolean {
  return layer.options.enabled !== false
}

/** Whether `target` is in the layer itself, the elements it counts as its own, or a branch. */
function ownsTarget(layer: Layer, target: Node): boolean {
  if (layer.element.contains(target)) return true
  for (const element of layer.options.inside ?? []) if (element?.contains(target)) return true
  for (const branch of branches) if (branch.contains(target)) return true
  return false
}

/** The layer `layer` is nested in: the nearest below it that holds its element or its trigger. */
function parentOf(layer: Layer): Layer | undefined {
  const index = layers.indexOf(layer)
  for (let below = index - 1; below >= 0; below--) {
    const candidate = layers[below]!
    if (candidate.element === layer.element) continue
    if (candidate.element.contains(layer.element)) return candidate
    for (const element of layer.options.inside ?? []) {
      if (element && candidate.element.contains(element)) return candidate
    }
  }
  return undefined
}

function isNestedIn(layer: Layer, ancestor: Layer): boolean {
  for (let parent = parentOf(layer); parent; parent = parentOf(parent)) {
    if (parent === ancestor) return true
  }
  return false
}

/** Whether `target` is inside `layer` or any layer nested in it, wherever that is rendered. */
function isInside(layer: Layer, target: Node): boolean {
  if (ownsTarget(layer, target)) return true
  const index = layers.indexOf(layer)
  return layers
    .slice(index + 1)
    .some(above => isNestedIn(above, layer) && ownsTarget(above, target))
}

/** The index of the highest layer that turns outside pointers off, or -1. */
function highestModal(): number {
  for (let index = layers.length - 1; index >= 0; index--) {
    if (layers[index]!.options.disableOutsidePointerEvents && enabled(layers[index]!)) return index
  }
  return -1
}

/** Layers below the highest modal one don't hear pointers outside them. */
function hearsPointers(layer: Layer): boolean {
  return layers.indexOf(layer) >= highestModal()
}

function happenedBefore(event: Event, layer: Layer): boolean {
  return event.timeStamp > 0 && event.timeStamp < layer.since
}

/**
 * Sends a cancelable, non-bubbling event to the original target with the layer's handler on it,
 * as Radix does, so the handler sees the real target. Returns whether it was cancelled.
 */
function dispatchOutside<E extends Event>(
  name: string,
  originalEvent: E,
  handlers: Array<((event: CustomEvent<{ originalEvent: E }>) => void) | undefined>,
): boolean {
  const target = originalEvent.target as EventTarget
  const event = new CustomEvent(name, {
    bubbles: false,
    cancelable: true,
    detail: { originalEvent },
  })
  const listener = (event: Event) => {
    for (const handler of handlers) handler?.(event as CustomEvent<{ originalEvent: E }>)
  }
  target.addEventListener(name, listener, { once: true })
  target.dispatchEvent(event)
  target.removeEventListener(name, listener)
  return event.defaultPrevented
}

function onKeyDown(event: KeyboardEvent): void {
  if (event.key !== 'Escape') return
  const top = layers.at(-1)
  // A popover="auto" on top is the browser's to close: its own close request does it.
  if (!top || top.native || !enabled(top)) return
  top.options.onEscapeKeyDown?.(event)
  if (event.defaultPrevented) return
  // Cancelling the keydown also stops the browser's close request, so a <dialog> or an auto
  // popover underneath stays open: only the top layer closes.
  event.preventDefault()
  top.options.onDismiss?.('escape-key')
}

/** Before any handler runs (one might remove the target), note which layers hold the target. */
function onPointerDownCapture(event: PointerEvent): void {
  const target = event.target
  if (!(target instanceof Node)) return
  pointerInside.set(event, new Set(layers.filter(layer => isInside(layer, target))))
}

function onPointerDown(event: PointerEvent): void {
  const inside = pointerInside.get(event)
  if (!inside || !(event.target instanceof Node)) return
  if (pendingTouch) {
    listening?.removeEventListener('click', pendingTouch)
    pendingTouch = undefined
  }
  // Top first, so a nested layer closes before the one it is in.
  const outside = [...layers]
    .reverse()
    .filter(
      layer =>
        !layer.native &&
        enabled(layer) &&
        !inside.has(layer) &&
        hearsPointers(layer) &&
        !happenedBefore(event, layer),
    )
  if (!outside.length) return

  const dismiss = () => {
    for (const layer of outside) {
      if (!layers.includes(layer)) continue
      const { onPointerDownOutside, onInteractOutside, onDismiss } = layer.options
      const cancelled = dispatchOutside(POINTER_DOWN_OUTSIDE, event, [
        onPointerDownOutside,
        onInteractOutside,
      ])
      if (!cancelled) onDismiss?.('pointer-outside')
    }
  }

  // On touch, wait for the click: a finger that goes down to scroll shouldn't close anything.
  if (event.pointerType === 'touch' && listening) {
    const document = listening
    pendingTouch = () => {
      pendingTouch = undefined
      dismiss()
    }
    document.addEventListener('click', pendingTouch, { once: true })
  } else {
    dismiss()
  }
}

function onFocusIn(event: FocusEvent): void {
  const target = event.target
  if (!(target instanceof Node)) return
  const outside = [...layers]
    .reverse()
    .filter(
      layer =>
        !layer.native &&
        enabled(layer) &&
        !isInside(layer, target) &&
        !happenedBefore(event, layer),
    )
  for (const layer of outside) {
    if (!layers.includes(layer)) continue
    const { onFocusOutside, onInteractOutside, onDismiss } = layer.options
    const cancelled = dispatchOutside(FOCUS_OUTSIDE, event, [onFocusOutside, onInteractOutside])
    if (!cancelled) onDismiss?.('focus-outside')
  }
}

function listen(document: Document): void {
  if (listening) return
  listening = document
  // Escape in the capture phase, as Radix does, so the top layer hears it before the target.
  document.addEventListener('keydown', onKeyDown, true)
  document.addEventListener('pointerdown', onPointerDownCapture, true)
  document.addEventListener('pointerdown', onPointerDown)
  document.addEventListener('focusin', onFocusIn)
}

function stopListening(): void {
  const document = listening
  if (!document) return
  document.removeEventListener('keydown', onKeyDown, true)
  document.removeEventListener('pointerdown', onPointerDownCapture, true)
  document.removeEventListener('pointerdown', onPointerDown)
  document.removeEventListener('focusin', onFocusIn)
  if (pendingTouch) document.removeEventListener('click', pendingTouch)
  pendingTouch = undefined
  listening = undefined
}

/** Sets `pointer-events` on `<body>` and each layer while any layer turns outside pointers off. */
function applyPointerEvents(): void {
  const modal = highestModal()
  const document = listening ?? globalThis.document
  const body = document.body
  if (modal >= 0 && !pointerEventsDisabled) {
    bodyPointerEvents = body.style.pointerEvents
    body.style.pointerEvents = 'none'
    pointerEventsDisabled = true
  } else if (modal < 0 && pointerEventsDisabled) {
    body.style.pointerEvents = bodyPointerEvents ?? ''
    pointerEventsDisabled = false
  }
  for (const [index, layer] of layers.entries()) {
    if (!(layer.element instanceof HTMLElement || layer.element instanceof SVGElement)) continue
    const style = layer.element.style
    if (modal >= 0) {
      layer.pointerEvents ??= style.pointerEvents
      style.pointerEvents = index >= modal ? 'auto' : 'none'
    } else if (layer.pointerEvents !== undefined) {
      style.pointerEvents = layer.pointerEvents
      layer.pointerEvents = undefined
    }
  }
}

/** Puts a new layer above every layer it is nested in, and below any already nested in it. */
function insert(layer: Layer): void {
  const nestedInIt = layers.findIndex(
    other =>
      (other.element !== layer.element && layer.element.contains(other.element)) ||
      (other.options.inside ?? []).some(element => element && layer.element.contains(element)),
  )
  if (nestedInIt === -1) layers.push(layer)
  else layers.splice(nestedInIt, 0, layer)
}

/**
 * Puts an element on the dismiss stack, the list of open layers (popovers, menus, dialogs) that
 * Escape and pointers outside them close, as Radix's `DismissableLayer` does:
 *
 * - **Escape** goes to the top layer only. Unless `onEscapeKeyDown` cancels it, `onDismiss` is
 *   called and the keydown is cancelled, so nothing underneath (a `<dialog>`, another layer)
 *   closes with it.
 * - **A pointer down outside** goes to every layer it is outside of, top first, unless a layer
 *   below the pointer turned outside pointers off (`disableOutsidePointerEvents`).
 * - **Focus moving outside** goes to every layer it left.
 *
 * A layer nested in another (its element or its trigger is inside that one) counts as inside
 * it, wherever it is rendered, so pressing in a submenu leaves its menu open. Events from
 * before the layer opened, such as the press that opened it, are ignored.
 *
 *   const layer = registerDismissable(element, { onDismiss: () => this.open.set(false) })
 *   layer.update({ …options })
 *   layer.remove()
 *
 * In a template, the `{{dismissable}}` modifier does the same for the element it is on.
 */
export function registerDismissable(
  element: Element,
  options: DismissableOptions = {},
  { native = false }: { native?: boolean } = {},
): DismissableLayer {
  const layer: Layer = {
    element,
    options,
    since: performance.now(),
    native,
    pointerEvents: undefined,
  }
  listen(element.ownerDocument)
  insert(layer)
  applyPointerEvents()

  return {
    element,
    get isTop() {
      return layers.at(-1) === layer
    },
    update(next: DismissableOptions) {
      layer.options = next
      applyPointerEvents()
    },
    remove() {
      const index = layers.indexOf(layer)
      if (index === -1) return
      layers.splice(index, 1)
      applyPointerEvents()
      if (layer.pointerEvents !== undefined && layer.element instanceof HTMLElement) {
        layer.element.style.pointerEvents = layer.pointerEvents
      }
      if (!layers.length) stopListening()
    },
  }
}

/** The elements on the dismiss stack, bottom first: the last one is the top layer. */
export function dismissableLayers(): Element[] {
  return layers.map(layer => layer.element)
}

interface DismissableSignature {
  Element: Element
  Args: { Named: DismissableOptions }
}

class DismissableModifier extends Modifier<DismissableSignature> {
  #layer: DismissableLayer | undefined

  override modify(element: Element, _: [], options: DismissableOptions): void {
    if (this.#layer) return this.#layer.update({ ...options })
    const layer = (this.#layer = registerDismissable(element, { ...options }))
    registerDestructor(this, () => layer.remove())
  }
}

/**
 * Puts the element on the dismiss stack while it is rendered: see `registerDismissable`.
 *
 *   <div {{dismissable onDismiss=this.close inside=(array this.trigger)}}>…</div>
 *
 * Its arguments can change; the layer keeps its place in the stack.
 */
export const dismissable = DismissableModifier

class DismissableBranchModifier extends Modifier<{ Element: Element }> {
  #element: Element | undefined

  override modify(element: Element): void {
    if (this.#element) return
    this.#element = element
    branches.add(element)
    registerDestructor(this, () => branches.delete(element))
  }
}

/**
 * Makes an element count as inside every layer, as Radix's `DismissableLayer.Branch` does: a
 * pointer or focus there dismisses nothing. For things that sit beside the layers, such as a
 * toast region.
 *
 *   <ol {{dismissableBranch}}>…toasts…</ol>
 */
export const dismissableBranch = DismissableBranchModifier
