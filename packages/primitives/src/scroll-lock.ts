import Modifier from 'ember-modifier'
import { registerDestructor } from '@ember/destroyable'

/** Elements, or a function that returns them when they're needed (they may render later). */
export type ScrollLockShards =
  ReadonlyArray<Element | null | undefined> | (() => ReadonlyArray<Element | null | undefined>)

export interface ScrollLockOptions {
  /**
   * Elements that keep their own scrolling, such as a dialog's content, as react-remove-scroll's
   * `shards`: a wheel or a finger over them scrolls them (to their ends, and no further), and
   * everywhere else it does nothing. Give a function when they render after the lock starts.
   */
  inside?: ScrollLockShards
  /** Let a pinch (two fingers, or Ctrl and the wheel) zoom the page. Default `true`, as in Radix's Dialog. */
  allowPinchZoom?: boolean
}

/** A lock started with `lockScroll`. */
export interface ScrollLock {
  /** Replaces its options. */
  update(options: ScrollLockOptions): void
  /** Ends the lock. The page scrolls again once every lock has ended. */
  release(): void
}

/** The attribute on `<body>` while the page is locked: how many locks hold it. */
export const SCROLL_LOCKED = 'data-scroll-locked'

/** The custom property on `<body>` with the width of the scrollbar the lock took away. */
export const REMOVED_SCROLLBAR_SIZE = '--removed-body-scroll-bar-size'

type Axis = 'v' | 'h'

interface Lock {
  document: Document
  options: ScrollLockOptions
}

/** Every live lock, oldest first; only the newest one decides what scrolls. */
let locks: Lock[] = []

/** What the lock changed on `<body>`, to put back, by document. */
const saved = new WeakMap<Document, Array<[property: string, value: string, priority: string]>>()

function shardsOf(lock: Lock): Element[] {
  const inside = lock.options.inside
  const list = typeof inside === 'function' ? inside() : (inside ?? [])
  return list.filter((element): element is Element => element instanceof Element)
}

function count(document: Document): number {
  const value = Number.parseInt(document.body.getAttribute(SCROLL_LOCKED) ?? '0', 10)
  return Number.isFinite(value) ? value : 0
}

/**
 * Takes the page's scrollbar away, as react-remove-scroll-bar does, and keeps the page where it
 * was: `<body>` gets `overflow: hidden`, and a right margin as wide as the scrollbar was, so
 * nothing moves sideways. It goes through the CSSOM, which a strict Content Security Policy
 * allows, and everything comes back when the last lock ends.
 */
function lockBody(document: Document): void {
  const body = document.body
  const window = document.defaultView ?? globalThis.window
  const styles = window.getComputedStyle(body)
  const gap = Math.max(0, window.innerWidth - document.documentElement.clientWidth)
  const margin = Number.parseFloat(styles.marginRight) || 0
  const changes: Array<[string, string, string]> = [
    ['overflow', 'hidden', 'important'],
    ['overscroll-behavior', 'contain', ''],
    ['position', 'relative', 'important'],
    ['margin-right', `${margin + gap}px`, 'important'],
    [REMOVED_SCROLLBAR_SIZE, `${gap}px`, ''],
  ]
  saved.set(
    document,
    changes.map(([property]) => [
      property,
      body.style.getPropertyValue(property),
      body.style.getPropertyPriority(property),
    ]),
  )
  for (const [property, value, priority] of changes)
    body.style.setProperty(property, value, priority)
}

function unlockBody(document: Document): void {
  const body = document.body
  for (const [property, value, priority] of saved.get(document) ?? []) {
    if (value) body.style.setProperty(property, value, priority)
    else body.style.removeProperty(property)
  }
  saved.delete(document)
}

// ----- What may scroll, as react-remove-scroll decides it ------------------------------------

/** Whether an element scrolls on an axis: its overflow there isn't hidden, nor visible all round. */
function canScroll(element: Element, axis: Axis): boolean {
  const styles = getComputedStyle(element)
  const overflow = axis === 'v' ? styles.overflowY : styles.overflowX
  if (overflow === 'hidden') return false
  // A textarea always keeps its scrolling inside itself.
  const visible = styles.overflowY === styles.overflowX && overflow === 'visible'
  return !visible || element.tagName === 'TEXTAREA'
}

function measures(element: Element, axis: Axis): [position: number, size: number, client: number] {
  return axis === 'v'
    ? [element.scrollTop, element.scrollHeight, element.clientHeight]
    : [element.scrollLeft, element.scrollWidth, element.clientWidth]
}

/** Whether anything from `target` up to `<body>` could scroll on the axis at all. */
function couldScroll(axis: Axis, target: Element): boolean {
  const body = target.ownerDocument.body
  for (let node: Element | null = target; node && node !== body; node = node.parentElement) {
    if (!canScroll(node, axis)) continue
    const [, size, client] = measures(node, axis)
    if (size > client) return true
  }
  return false
}

/**
 * Whether a scroll of `delta` from `target`, inside `shard`, should be cancelled because there is
 * no room left to scroll that way in the shard: what react-remove-scroll's `handleScroll` does
 * with `noOverscroll`, so a scroll never runs past the content onto the page behind it.
 */
function runsOut(axis: Axis, shard: Element, target: Element, sourceDelta: number): boolean {
  const rtl = axis === 'h' && getComputedStyle(shard).direction === 'rtl'
  const factor = rtl ? -1 : 1
  const delta = factor * sourceDelta
  let room = 0
  let roomBack = 0
  for (let node: Element | null = target; node; node = node.parentElement) {
    const [position, size, client] = measures(node, axis)
    const ahead = size - client - factor * position
    if ((position || ahead) && canScroll(node, axis)) {
      room += ahead
      roomBack += position
    }
    if (node === shard) break
  }
  return delta > 0 ? Math.abs(room) < 1 : Math.abs(roomBack) < 1
}

interface Gesture {
  startX: number
  startY: number
  axis: Axis | undefined
}

const gestures = new WeakMap<Document, Gesture>()

function touchPoint(event: TouchEvent): [number, number] {
  const touch = event.changedTouches[0]
  return touch ? [touch.clientX, touch.clientY] : [0, 0]
}

/** Whether the newest lock cancels this wheel or touch move. */
function shouldCancel(lock: Lock, event: WheelEvent | TouchEvent): boolean {
  const pinch =
    ('touches' in event && event.touches.length === 2) || (event.type === 'wheel' && event.ctrlKey)
  if (pinch) return !(lock.options.allowPinchZoom ?? true)

  const target = event.target
  if (!(target instanceof Element)) return true
  const shard = shardsOf(lock).find(element => element.contains(target))
  // Outside every shard, nothing scrolls.
  if (!shard) return true

  const gesture = gestures.get(lock.document)
  let deltaX: number
  let deltaY: number
  if ('deltaY' in event) {
    deltaX = event.deltaX
    deltaY = event.deltaY
  } else {
    const [x, y] = touchPoint(event)
    deltaX = (gesture?.startX ?? x) - x
    deltaY = (gesture?.startY ?? y) - y
  }

  // A sideways drag on a range input moves its thumb, not the page.
  const direction: Axis = Math.abs(deltaX) > Math.abs(deltaY) ? 'h' : 'v'
  if ('touches' in event && direction === 'h' && (target as HTMLInputElement).type === 'range') {
    return false
  }
  // Dragging a text selection (on iOS) isn't a scroll. A caret left anywhere isn't one.
  const selection = target.ownerDocument.getSelection()
  const anchor = selection && !selection.isCollapsed ? selection.anchorNode : null
  if (anchor && (anchor === target || anchor.contains(target))) return false

  if (!couldScroll(direction, target)) return true
  let axis: Axis = direction
  if (gesture && 'changedTouches' in event && (deltaX || deltaY)) {
    gesture.axis ??= direction
    axis = gesture.axis
  }
  return runsOut(axis, shard, target, axis === 'h' ? deltaX : deltaY)
}

function onScrollGesture(event: Event): void {
  const lock = locks.at(-1)
  if (!lock || !event.cancelable) return
  if (shouldCancel(lock, event as WheelEvent | TouchEvent)) event.preventDefault()
}

function onTouchStart(event: TouchEvent): void {
  const [startX, startY] = touchPoint(event)
  const document = (event.currentTarget as Document | null) ?? globalThis.document
  gestures.set(document, { startX, startY, axis: undefined })
}

const ACTIVE: AddEventListenerOptions = { passive: false }

function listen(document: Document): void {
  document.addEventListener('wheel', onScrollGesture, ACTIVE)
  document.addEventListener('touchmove', onScrollGesture, ACTIVE)
  document.addEventListener('touchstart', onTouchStart, ACTIVE)
}

function stopListening(document: Document): void {
  document.removeEventListener('wheel', onScrollGesture)
  document.removeEventListener('touchmove', onScrollGesture)
  document.removeEventListener('touchstart', onTouchStart)
  gestures.delete(document)
}

/**
 * Stops the page scrolling behind an overlay, as Radix's Dialog does with react-remove-scroll:
 *
 * - **The scrollbar goes**, and `<body>` keeps its width (a right margin as wide as the
 *   scrollbar was), so nothing behind the overlay jumps. `<body>` has `data-scroll-locked` while
 *   any lock holds it, and `--removed-body-scroll-bar-size` says how wide the scrollbar was, for
 *   fixed elements of your own that should keep their place.
 * - **A wheel or a finger does nothing**, except over the elements given as `inside` (a
 *   dialog's content), which scroll as far as their ends and no further, so the page behind
 *   never takes the scroll over.
 *
 * Locks stack: the newest decides what may scroll, and the page scrolls again when the last one
 * ends. A pinch still zooms, unless `allowPinchZoom` is `false`.
 *
 *   const lock = lockScroll(document, { inside: [content] })
 *   lock.release()
 *
 * In a template, `{{scrollLock}}` locks the page while its element is rendered.
 */
export function lockScroll(
  document: Document = globalThis.document,
  options: ScrollLockOptions = {},
): ScrollLock {
  const lock: Lock = { document, options }
  const held = count(document)
  if (held === 0) lockBody(document)
  document.body.setAttribute(SCROLL_LOCKED, String(held + 1))
  if (!locks.some(other => other.document === document)) listen(document)
  locks.push(lock)

  let released = false
  return {
    update(next: ScrollLockOptions) {
      lock.options = next
    },
    release() {
      if (released) return
      released = true
      locks = locks.filter(other => other !== lock)
      const remaining = count(document) - 1
      if (remaining > 0) {
        document.body.setAttribute(SCROLL_LOCKED, String(remaining))
      } else {
        document.body.removeAttribute(SCROLL_LOCKED)
        unlockBody(document)
      }
      if (!locks.some(other => other.document === document)) stopListening(document)
    },
  }
}

/** Whether a lock holds the page now. */
export function isScrollLocked(document: Document = globalThis.document): boolean {
  return count(document) > 0
}

interface ScrollLockSignature {
  Element: Element
  Args: { Named: ScrollLockOptions & { enabled?: boolean } }
}

class ScrollLockModifier extends Modifier<ScrollLockSignature> {
  #lock: ScrollLock | undefined
  #element: Element | undefined

  override modify(element: Element, _: [], named: ScrollLockSignature['Args']['Named']): void {
    if (!this.#element) {
      this.#element = element
      registerDestructor(this, () => this.#release())
    }
    const { enabled = true, inside, allowPinchZoom } = named
    // The element is a shard too, as react-remove-scroll's own element is.
    const options: ScrollLockOptions = {
      inside: () => [element, ...(typeof inside === 'function' ? inside() : (inside ?? []))],
      allowPinchZoom,
    }
    if (!enabled) return this.#release()
    if (this.#lock) return this.#lock.update(options)
    this.#lock = lockScroll(element.ownerDocument, options)
  }

  #release(): void {
    this.#lock?.release()
    this.#lock = undefined
  }
}

/**
 * Locks the page's scrolling while the element is rendered: see `lockScroll`. The element
 * itself, and the elements given as `inside`, are where a wheel or a finger still scrolls.
 *
 *   <div class="overlay" {{scrollLock inside=(array this.panel)}}></div>
 *
 * `enabled=false` lifts the lock without removing the element.
 */
export const scrollLock = ScrollLockModifier
