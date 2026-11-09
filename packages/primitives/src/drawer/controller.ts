// A drawer's state and behaviour: vaul's Root, Content, Overlay and Handle (vaul 1.1.2, which
// shadcn/ui's Drawer is built on), as a DialogController with gestures. This file is bundled
// into @ember-joinery/primitives/drawer; it isn't a subpath of its own.
import { tracked } from '@glimmer/tracking'
import { buildWaiter } from '@ember/test-waiters'
import { ControllableState, type ControllableArgs } from '../controllable-state.ts'
import { isRTL } from '../direction.gts'
import type { FocusOutsideEvent, PointerDownOutsideEvent } from '../dismiss.ts'
import { part, type PartModifier } from '../part.ts'
import { DialogController, type DialogArgs } from '../-private/dialog.gts'

/** The edge of the screen a drawer comes in from. */
export type DrawerDirection = 'top' | 'bottom' | 'left' | 'right'

/**
 * Where a drawer can rest: a fraction of the screen (`0.5`, half of it), or a size in pixels as
 * a string (`'148px'`), as vaul's snap points.
 */
export type SnapPoint = number | string

/** What a Drawer takes: a Dialog's arguments, and vaul's. */
export type DrawerArgs = Omit<DialogArgs, 'slot'> &
  ControllableArgs<'activeSnapPoint', SnapPoint | null> & {
    /**
     * The edge it comes in from: `top`, `right`, `bottom` (the default) or `left`. Left and
     * right are the inline start and end, as Joinery's styles place them: right to left, a
     * `left` drawer is on the right, and drags and slides as one.
     */
    direction?: DrawerDirection
    /**
     * Whether a drag, a press outside, Escape, its close parts and its trigger can close it.
     * Default `true`. With `false`, only you close it, with `@open` or `setOpen`.
     */
    dismissible?: boolean
    /** Where it can rest, smallest first: fractions of the screen, or `'<n>px'` strings. */
    snapPoints?: readonly SnapPoint[]
    /** The snap point from which the overlay fades in. Default the last. */
    fadeFromIndex?: number
    /** Never skip a snap point on a fast swipe. Default `false`. */
    snapToSequentialPoint?: boolean
    /** How much of it, from 0 to 1, a drag must hide to close it. Default `0.25`. */
    closeThreshold?: number
    /** How long after its content scrolls it can't be dragged, in ms. Default `100`. */
    scrollLockTimeout?: number
    /** Only its Handle drags it. Default `false`. */
    handleOnly?: boolean
    /**
     * Scale the element marked `data-vaul-drawer-wrapper` (your app's root, say) back while it
     * is open, as iOS sheets do. Default `false`.
     */
    shouldScaleBackground?: boolean
    /** While the background is scaled, make `<body>` black behind it. Default `true`. */
    setBackgroundColorOnScale?: boolean
    /** Leave `<body>`'s styles alone. Default `false`. */
    noBodyStyles?: boolean
    /**
     * Move focus to its first focusable element when it opens, as a Dialog does. By default
     * focus goes to the drawer itself, so a phone's keyboard doesn't pop up for an input in it.
     */
    autoFocus?: boolean
    /**
     * While an input in it has focus and a phone's keyboard opens, resize it to stay in view.
     * Default `true`.
     */
    repositionInputs?: boolean
    /** With `repositionInputs`, shrink it rather than move it up. Default `false`. */
    fixed?: boolean
    /** Called as it is dragged, with how far (0 to 1) toward closed. */
    onDrag?: (event: PointerEvent, percentageDragged: number) => void
    /** Called when a drag lets go, with whether it stays open. */
    onRelease?: (event: PointerEvent, open: boolean) => void
    /** Called once it has finished opening or closing (its animation takes 500ms). */
    onAnimationEnd?: (open: boolean) => void
    /** The drawer this one is nested in: bound by the outer drawer's `Nested`. */
    parent?: DrawerController
  }

// vaul's constants.
const DURATION = 0.5
const EASE = 'cubic-bezier(0.32,0.72,0,1)'
const VELOCITY_THRESHOLD = 0.4
const CLOSE_THRESHOLD = 0.25
const SCROLL_LOCK_TIMEOUT = 100
const BORDER_RADIUS = 8
const NESTED_DISPLACEMENT = 16
const WINDOW_TOP_OFFSET = 26
const LONG_HANDLE_PRESS_TIMEOUT = 250
const DOUBLE_TAP_TIMEOUT = 120

/** The class a drawer has while it is dragged. */
export const DRAG_CLASS = 'vaul-dragging'

/** The selectors vaul finds the background to scale by. */
const WRAPPER = '[data-vaul-drawer-wrapper], [vaul-drawer-wrapper]'

const waiter = buildWaiter('@ember-joinery/primitives:drawer')

const transformTransition = `transform ${DURATION}s ${EASE}`
const opacityTransition = `opacity ${DURATION}s ${EASE}`

/** HTML input types that don't open a phone's keyboard. */
const NON_TEXT_INPUTS = new Set([
  'checkbox',
  'radio',
  'range',
  'color',
  'file',
  'image',
  'button',
  'submit',
  'reset',
])

export function isVertical(direction: DrawerDirection): boolean {
  return direction === 'top' || direction === 'bottom'
}

/** Whether an element opens a phone's keyboard when it has focus. */
function isInput(target: Element | null): boolean {
  return (
    (target instanceof HTMLInputElement && !NON_TEXT_INPUTS.has(target.type)) ||
    target instanceof HTMLTextAreaElement ||
    (target instanceof HTMLElement && target.isContentEditable)
  )
}

function isMobileFirefox(): boolean {
  const userAgent = navigator.userAgent
  return (/Firefox/.test(userAgent) && /Mobile/.test(userAgent)) || /FxiOS/.test(userAgent)
}

type Styles = Record<string, string>

/** Sets styles through the CSSOM, which a strict Content Security Policy allows. */
export function setStyles(element: Element | null | undefined, styles: Styles): void {
  if (!(element instanceof HTMLElement)) return
  for (const [name, value] of Object.entries(styles)) element.style.setProperty(name, value)
}

/** Sets styles, and returns a function that puts the element's whole style back. */
function assignStyles(element: HTMLElement, styles: Styles): () => void {
  const previous = element.style.cssText
  setStyles(element, styles)
  return () => {
    element.style.cssText = previous
  }
}

/** How far an element is translated along a direction's axis, from its computed transform. */
export function getTranslate(element: Element | null, direction: DrawerDirection): number | null {
  if (!element) return null
  const transform = getComputedStyle(element).transform
  let matrix = /^matrix3d\((.+)\)$/.exec(transform)
  if (matrix) return parseFloat(matrix[1]!.split(', ')[isVertical(direction) ? 13 : 12]!)
  matrix = /^matrix\((.+)\)$/.exec(transform)
  return matrix ? parseFloat(matrix[1]!.split(', ')[isVertical(direction) ? 5 : 4]!) : null
}

/** vaul's rubber band, for a drag past fully open. */
function dampen(value: number): number {
  return 8 * (Math.log(value + 1) - 2)
}

function translate(direction: DrawerDirection, value: number | string): string {
  const amount = typeof value === 'number' ? `${value}px` : value
  return isVertical(direction) ? `translate3d(0, ${amount}, 0)` : `translate3d(${amount}, 0, 0)`
}

/**
 * One drawer's state and parts: a Dialog's (`DialogController`), with vaul's gestures. The
 * content follows a drag along its axis and closes when let go far or fast enough, rests at its
 * snap points, fades the overlay as it goes, scales the page behind it, and moves a drawer it is
 * nested in back a step.
 */
export class DrawerController extends DialogController {
  readonly activeSnapPointState: ControllableState<SnapPoint | null>

  /** Whether it is being dragged now. */
  @tracked isDragging = false
  /** The window's size, kept as it resizes (snap points are measured against it). */
  @tracked private viewportSize: { width: number; height: number } | null = null

  /** Untracked on purpose, as vaul's ref: its enter animation is skipped when it starts open. */
  #shouldAnimate: boolean
  #openTime: number | null = null
  #dragStartTime: number | null = null
  #lastTimeDragPrevented: number | null = null
  #isAllowedToDrag = false
  #pointerStart = 0
  #keyboardIsOpen = false
  #previousDiffFromInitial = 0
  #drawerHeight = 0
  #drawerWidth = 0
  #initialDrawerHeight = 0
  #nestedOpenChangeTimer: ReturnType<typeof setTimeout> | undefined
  #timers = new Set<ReturnType<typeof setTimeout>>()
  // The content's own pointer tracking (vaul's Content).
  #contentPointerStart: { x: number; y: number } | null = null
  #lastKnownPointerEvent: PointerEvent | null = null
  #wasBeyondThePoint = false
  // The handle's taps (vaul's Handle).
  #handleCloseTimeout: ReturnType<typeof setTimeout> | undefined
  #shouldCancelInteraction = false
  #previousScrollBehavior: string | null = null

  /** The Dialog's own `setOpen`, which this one wraps. */
  readonly #setDialogOpen = (this as DialogController).setOpen

  constructor(owner: { readonly args: DrawerArgs }) {
    super(owner)
    this.#shouldAnimate = !owner.args.defaultOpen
    this.activeSnapPointState = new ControllableState<SnapPoint | null>({
      value: () => this.args.activeSnapPoint,
      defaultValue: () => this.args.defaultActiveSnapPoint ?? this.args.snapPoints?.[0],
      onChange: () => this.args.onActiveSnapPointChange,
      fallback: null,
      name: 'activeSnapPoint',
    })
  }

  // ----- Arguments, with vaul's defaults ----------------------------------------------------

  override get args(): DrawerArgs {
    return super.args as DrawerArgs
  }

  override get slot(): string {
    return 'drawer'
  }

  get direction(): DrawerDirection {
    return this.args.direction ?? 'bottom'
  }

  /**
   * The physical edge it is on: its direction, but with left and right swapped right to left
   * (where `left`, the inline start, is on the right).
   */
  get side(): DrawerDirection {
    const direction = this.direction
    if (isVertical(direction)) return direction
    const element = this.contentElement ?? this.triggerElement
    if (!isRTL(element)) return direction
    return direction === 'left' ? 'right' : 'left'
  }

  get dismissible(): boolean {
    return this.args.dismissible ?? true
  }

  get snapPoints(): readonly SnapPoint[] | undefined {
    return this.args.snapPoints
  }

  get hasSnapPoints(): boolean {
    return (this.snapPoints?.length ?? 0) > 0
  }

  get fadeFromIndex(): number | undefined {
    const snapPoints = this.snapPoints
    return this.args.fadeFromIndex ?? (snapPoints ? snapPoints.length - 1 : undefined)
  }

  get closeThreshold(): number {
    return this.args.closeThreshold ?? CLOSE_THRESHOLD
  }

  get scrollLockTimeout(): number {
    return this.args.scrollLockTimeout ?? SCROLL_LOCK_TIMEOUT
  }

  get repositionInputs(): boolean {
    return this.args.repositionInputs ?? true
  }

  // ----- Snap points (vaul's useSnapPoints) -------------------------------------------------

  get activeSnapPoint(): SnapPoint | null {
    return this.activeSnapPointState.value
  }

  setActiveSnapPoint = (snapPoint: SnapPoint | null): void => {
    this.activeSnapPointState.set(snapPoint)
  }

  get activeSnapPointIndex(): number | null {
    return this.snapPoints?.findIndex(point => point === this.activeSnapPoint) ?? null
  }

  get isLastSnapPoint(): boolean {
    const snapPoints = this.snapPoints
    return Boolean(snapPoints && this.activeSnapPoint === snapPoints[snapPoints.length - 1])
  }

  /** Whether the overlay shows: always without snap points, else from `fadeFromIndex` on. */
  get shouldFade(): boolean {
    const snapPoints = this.snapPoints
    if (!snapPoints) return true
    const index = this.fadeFromIndex
    return (
      snapPoints.length > 0 &&
      index !== undefined &&
      !Number.isNaN(index) &&
      snapPoints[index] === this.activeSnapPoint
    )
  }

  get #viewport(): { width: number; height: number } {
    const window = this.contentElement?.ownerDocument.defaultView ?? globalThis.window
    return this.viewportSize ?? { width: window.innerWidth, height: window.innerHeight }
  }

  /** Called when the window resizes, so the snap points are measured again. */
  measure = (): void => {
    const window = this.contentElement?.ownerDocument.defaultView ?? globalThis.window
    this.viewportSize = { width: window.innerWidth, height: window.innerHeight }
  }

  /** Each snap point as the translation, in pixels along its axis, that rests the drawer there. */
  get snapPointsOffset(): number[] {
    const side = this.side
    const { width, height } = this.#viewport
    return (this.snapPoints ?? []).map(snapPoint => {
      const isPx = typeof snapPoint === 'string'
      const value = isPx ? parseInt(snapPoint, 10) : 0
      if (isVertical(side)) {
        const size = isPx ? value : snapPoint * height
        return side === 'bottom' ? height - size : -height + size
      }
      const size = isPx ? value : snapPoint * width
      return side === 'right' ? width - size : -width + size
    })
  }

  get activeSnapPointOffset(): number | null {
    const index = this.activeSnapPointIndex
    return index !== null ? (this.snapPointsOffset[index] ?? null) : null
  }

  /** Rests the drawer at the snap point with this offset, and makes it the active one. */
  snapToPoint(dimension: number | undefined): void {
    const offsets = this.snapPointsOffset
    const index = dimension === undefined ? -1 : offsets.indexOf(dimension)
    this.applySnapPoint(index)
    this.setActiveSnapPoint(this.snapPoints?.[Math.max(index, 0)] ?? null)
  }

  /** Moves the drawer to a snap point and fades the overlay to match, as vaul's snapToPoint. */
  applySnapPoint(index: number): void {
    const offsets = this.snapPointsOffset
    const dimension = offsets[index]
    // At the last snap point it may scroll, so it can't be dragged for a moment (vaul's
    // onSnapPointChange).
    if (this.snapPoints && index === offsets.length - 1) this.#openTime = Date.now()
    if (dimension === undefined) return
    setStyles(this.contentElement, {
      transition: transformTransition,
      transform: translate(this.side, dimension),
    })
    const fadeFrom = this.fadeFromIndex
    const transparent =
      index !== offsets.length - 1 &&
      fadeFrom !== undefined &&
      index !== fadeFrom &&
      index < fadeFrom
    setStyles(this.overlayElement, {
      transition: opacityTransition,
      opacity: transparent ? '0' : '1',
    })
  }

  #releaseSnapPoints(draggedDistance: number, velocity: number): void {
    const fadeFrom = this.fadeFromIndex
    const offsets = this.snapPointsOffset
    if (fadeFrom === undefined || offsets.length === 0) return
    const side = this.side
    const snapPoints = this.snapPoints ?? []
    const activeOffset = this.activeSnapPointOffset ?? 0
    const activeIndex = this.activeSnapPointIndex
    const currentPosition =
      side === 'bottom' || side === 'right'
        ? activeOffset - draggedDistance
        : activeOffset + draggedDistance
    const isOverlaySnapPoint = activeIndex === fadeFrom - 1
    const isFirst = activeIndex === 0
    const hasDraggedUp = draggedDistance > 0

    if (isOverlaySnapPoint) setStyles(this.overlayElement, { transition: opacityTransition })

    if (!this.args.snapToSequentialPoint && velocity > 2 && !hasDraggedUp) {
      if (this.dismissible) this.closeDrawer()
      else this.snapToPoint(offsets[0])
      return
    }
    if (!this.args.snapToSequentialPoint && velocity > 2 && hasDraggedUp) {
      this.snapToPoint(offsets[snapPoints.length - 1])
      return
    }

    // The snap point nearest to where it was let go.
    const closest = offsets.reduce((previous, current) =>
      Math.abs(current - currentPosition) < Math.abs(previous - currentPosition)
        ? current
        : previous,
    )
    const { width, height } = this.#viewport
    const dimension = isVertical(side) ? height : width
    if (velocity > VELOCITY_THRESHOLD && Math.abs(draggedDistance) < dimension * 0.4) {
      const dragDirection = hasDraggedUp ? 1 : -1
      // Swiped open at the last snap point: stay there.
      if (dragDirection > 0 && this.isLastSnapPoint) {
        this.snapToPoint(offsets[snapPoints.length - 1])
        return
      }
      if (isFirst && dragDirection < 0 && this.dismissible) this.closeDrawer()
      if (activeIndex === null) return
      this.snapToPoint(offsets[activeIndex + dragDirection])
      return
    }
    this.snapToPoint(closest)
  }

  #dragSnapPoints(draggedDistance: number): void {
    const activeOffset = this.activeSnapPointOffset
    if (activeOffset === null) return
    const side = this.side
    const offsets = this.snapPointsOffset
    const last = offsets[offsets.length - 1]!
    const value =
      side === 'bottom' || side === 'right'
        ? activeOffset - draggedDistance
        : activeOffset + draggedDistance
    // Not past the last (largest) snap point.
    if ((side === 'bottom' || side === 'right') && value < last) return
    if ((side === 'top' || side === 'left') && value > last) return
    setStyles(this.contentElement, { transform: translate(side, value) })
  }

  #snapPointsPercentageDragged(absDraggedDistance: number, isDraggingDown: boolean): number | null {
    const snapPoints = this.snapPoints
    const activeIndex = this.activeSnapPointIndex
    const fadeFrom = this.fadeFromIndex
    const offsets = this.snapPointsOffset
    if (!snapPoints || typeof activeIndex !== 'number' || fadeFrom === undefined) return null
    // Dragging to a snap point that is supposed to have an overlay.
    const isOverlaySnapPoint = activeIndex === fadeFrom - 1
    const isOverlaySnapPointOrHigher = activeIndex >= fadeFrom
    if (isOverlaySnapPointOrHigher && isDraggingDown) return 0
    // Don't animate, but still use this one when dragging away from the overlay snap point.
    if (isOverlaySnapPoint && !isDraggingDown) return 1
    if (!this.shouldFade && !isOverlaySnapPoint) return null
    const target = isOverlaySnapPoint ? activeIndex + 1 : activeIndex - 1
    const distance = isOverlaySnapPoint
      ? offsets[target]! - offsets[target - 1]!
      : offsets[target + 1]! - offsets[target]!
    const percentageDragged = absDraggedDistance / Math.abs(distance)
    return isOverlaySnapPoint ? 1 - percentageDragged : percentageDragged
  }

  // ----- Opening and closing -------------------------------------------------------------------

  /** Opens or closes it, whatever `@dismissible` says (your own code calling it decides). */
  override setOpen = (open: boolean): void => {
    if (this.isOpen && !open) {
      this.cancelDrag()
      const snapPoints = this.snapPoints
      if (snapPoints) this.#later(() => this.setActiveSnapPoint(snapPoints[0] ?? null), DURATION)
    }
    this.#setDialogOpen(open)
  }

  /** A close part, a `<form method="dialog">`: closes it, if it is dismissible. */
  override hide = (): void => {
    if (this.dismissible) this.setOpen(false)
  }

  /** The trigger: opens it, or closes it if it is dismissible. */
  override toggle = (): void => {
    if (this.isOpen) this.hide()
    else this.setOpen(true)
  }

  /** Escape or a press outside: closes it, if it is dismissible. */
  override dismiss = (): void => this.hide()

  /** Closes it after a drag (vaul's closeDrawer). */
  closeDrawer(): void {
    this.setOpen(false)
  }

  #later(callback: () => void, seconds: number): void {
    const timer = setTimeout(() => {
      this.#timers.delete(timer)
      callback()
    }, seconds * 1000)
    this.#timers.add(timer)
  }

  /** Called by the root when it has opened or closed, however that came about. */
  openChanged(open: boolean): void {
    const root = (this.contentElement ?? this.triggerElement)?.ownerDocument.documentElement
    if (open) {
      this.#openTime = Date.now()
      if (root) {
        this.#previousScrollBehavior = root.style.scrollBehavior
        root.style.scrollBehavior = 'auto'
      }
    } else if (root && this.#previousScrollBehavior !== null) {
      root.style.scrollBehavior = this.#previousScrollBehavior
      this.#previousScrollBehavior = null
    }
    this.args.parent?.onNestedOpenChange(open)
    this.#later(() => this.args.onAnimationEnd?.(open), DURATION)
  }

  /** Called by the root once it has rendered, a frame after which opening animates. */
  rendered(): void {
    requestAnimationFrame(() => (this.#shouldAnimate = true))
  }

  teardown(): void {
    for (const timer of this.#timers) clearTimeout(timer)
    this.#timers.clear()
    clearTimeout(this.#nestedOpenChangeTimer)
    clearTimeout(this.#handleCloseTimeout)
  }

  // ----- Focus and presses outside, as vaul's Content passes them to Radix's ------------------

  /** Focus goes to the drawer itself, unless `@autoFocus` asks for its first focusable element. */
  override onOpenAutoFocus(event: Event, handler?: (event: Event) => void): void {
    handler?.(event)
    if (event.defaultPrevented || this.args.autoFocus) return
    event.preventDefault()
    this.contentElement?.focus({ preventScroll: true })
  }

  override onPointerDownOutside(
    event: PointerDownOutsideEvent,
    handler?: (event: PointerDownOutsideEvent) => void,
  ): void {
    handler?.(event)
    // A press outside a non-modal drawer leaves it open.
    if (!this.isModal || event.defaultPrevented) {
      event.preventDefault()
      return
    }
    this.#keyboardIsOpen = false
    super.onPointerDownOutside(event)
  }

  /** Focus moving outside never closes a drawer. */
  override onFocusOutside(
    event: FocusOutsideEvent,
    handler?: (event: FocusOutsideEvent) => void,
  ): void {
    handler?.(event)
    event.preventDefault()
  }

  // ----- Dragging (vaul's Root) ------------------------------------------------------------

  /** A pointer went down on the drawer: it may be the start of a drag. */
  onPress(event: PointerEvent): void {
    const drawer = this.contentElement
    if (!this.dismissible && !this.snapPoints) return
    if (drawer && !(event.target instanceof Node && drawer.contains(event.target))) return
    const rect = drawer?.getBoundingClientRect()
    this.#drawerHeight = rect?.height ?? 0
    this.#drawerWidth = rect?.width ?? 0
    this.isDragging = true
    this.#dragStartTime = Date.now()
    // Keep the pointer while it leaves the drawer. A pointer that isn't active (an event a test
    // dispatches) can't be captured.
    try {
      if (event.target instanceof Element) event.target.setPointerCapture(event.pointerId)
    } catch {
      // Nothing to capture.
    }
    this.#pointerStart = isVertical(this.side) ? event.pageY : event.pageX
  }

  /** Whether a drag that started on `element` moves the drawer, rather than scrolling. */
  #shouldDrag(element: Element, isDraggingInDirection: boolean): boolean {
    const drawer = this.contentElement
    const side = this.side
    const highlightedText = element.ownerDocument.getSelection()?.toString()
    const swipeAmount = drawer ? getTranslate(drawer, side) : null
    const now = Date.now()

    if (element.tagName === 'SELECT') return false
    if (element.hasAttribute('data-vaul-no-drag') || element.closest('[data-vaul-no-drag]')) {
      return false
    }
    if (side === 'right' || side === 'left') return true
    // Still opening: let it scroll.
    if (this.#openTime && now - this.#openTime < 500) return false
    if (swipeAmount !== null && (side === 'bottom' ? swipeAmount > 0 : swipeAmount < 0)) {
      return true
    }
    // Text is selected.
    if (highlightedText && highlightedText.length > 0) return false
    // It scrolled a moment ago.
    if (
      this.#lastTimeDragPrevented &&
      now - this.#lastTimeDragPrevented < this.scrollLockTimeout &&
      swipeAmount === 0
    ) {
      this.#lastTimeDragPrevented = now
      return false
    }
    // Dragging it open: scroll instead.
    if (isDraggingInDirection) {
      this.#lastTimeDragPrevented = now
      return false
    }
    // Up through its ancestors: a scrolled one scrolls rather than drags. vaul climbs to the
    // document, past its portal; this drawer stays where it is rendered (in the top layer), so
    // the climb stops at the drawer, and a scrolled page or app container doesn't stop a drag.
    let current: Node | null = element
    while (current instanceof Element) {
      if (current.scrollHeight > current.clientHeight) {
        if (current.scrollTop !== 0) {
          this.#lastTimeDragPrevented = Date.now()
          return false
        }
        if (current.getAttribute('role') === 'dialog') return true
      }
      if (current === drawer) break
      current = current.parentNode
    }
    return true
  }

  /** The pointer moved while pressed: the drawer follows it. */
  onDrag(event: PointerEvent): void {
    const drawer = this.contentElement
    if (!drawer || !this.isDragging) return
    const side = this.side
    const multiplier = side === 'bottom' || side === 'right' ? 1 : -1
    const draggedDistance =
      (this.#pointerStart - (isVertical(side) ? event.pageY : event.pageX)) * multiplier
    const isDraggingInDirection = draggedDistance > 0
    const snapPoints = this.snapPoints
    const activeIndex = this.activeSnapPointIndex
    const fadeFrom = this.fadeFromIndex

    // A drawer that can't be dismissed can't be dragged closed past its first snap point.
    const noCloseSnapPoints = Boolean(snapPoints && !this.dismissible && !isDraggingInDirection)
    if (noCloseSnapPoints && activeIndex === 0) return

    const absDraggedDistance = Math.abs(draggedDistance)
    const wrapper = drawer.ownerDocument.querySelector(WRAPPER)
    const dimension = isVertical(side) ? this.#drawerHeight : this.#drawerWidth
    // How far toward closed, where 1 is closed.
    let percentageDragged = absDraggedDistance / dimension
    const snapPercentage = this.#snapPointsPercentageDragged(
      absDraggedDistance,
      isDraggingInDirection,
    )
    if (snapPercentage !== null) percentageDragged = snapPercentage
    if (noCloseSnapPoints && percentageDragged >= 1) return
    if (!this.#isAllowedToDrag && !this.#shouldDrag(event.target as Element, isDraggingInDirection))
      return

    drawer.classList.add(DRAG_CLASS)
    // Once it drags, it keeps dragging until let go.
    this.#isAllowedToDrag = true
    setStyles(drawer, { transition: 'none' })
    setStyles(this.overlayElement, { transition: 'none' })

    if (snapPoints) this.#dragSnapPoints(draggedDistance)

    // Past fully open, without snap points: a rubber band.
    if (isDraggingInDirection && !snapPoints) {
      const value = Math.min(dampen(draggedDistance) * -1, 0) * multiplier
      setStyles(drawer, { transform: translate(side, value) })
      return
    }

    const opacity = 1 - percentageDragged
    if (this.shouldFade || (fadeFrom && activeIndex === fadeFrom - 1)) {
      this.args.onDrag?.(event, percentageDragged)
      this.args.parent?.onNestedDrag(percentageDragged)
      setStyles(this.overlayElement, { opacity: `${opacity}`, transition: 'none' })
    }

    if (wrapper && this.overlayElement && this.args.shouldScaleBackground) {
      const scale = Math.min(this.#scale() + percentageDragged * (1 - this.#scale()), 1)
      const radius = 8 - percentageDragged * 8
      const offset = Math.max(0, 14 - percentageDragged * 14)
      setStyles(wrapper, {
        'border-radius': `${radius}px`,
        transform: isVertical(side)
          ? `scale(${scale}) translate3d(0, ${offset}px, 0)`
          : `scale(${scale}) translate3d(${offset}px, 0, 0)`,
        transition: 'none',
      })
    }

    if (!snapPoints) {
      setStyles(drawer, { transform: translate(side, absDraggedDistance * multiplier) })
    }
  }

  /** The scale of the page behind, while the drawer is open over it. */
  #scale(): number {
    const width = this.#viewport.width
    return (width - WINDOW_TOP_OFFSET) / width
  }

  /** Stops a drag without letting it go anywhere. */
  cancelDrag(): void {
    const drawer = this.contentElement
    if (!this.isDragging || !drawer) return
    drawer.classList.remove(DRAG_CLASS)
    this.#isAllowedToDrag = false
    this.isDragging = false
  }

  /** Puts it back where it rests, after a drag that didn't close it. */
  resetDrawer(): void {
    const drawer = this.contentElement
    if (!drawer) return
    const side = this.side
    const wrapper = drawer.ownerDocument.querySelector(WRAPPER)
    const swipeAmount = getTranslate(drawer, side)
    setStyles(drawer, { transform: 'translate3d(0, 0, 0)', transition: transformTransition })
    setStyles(this.overlayElement, { transition: opacityTransition, opacity: '1' })
    // Swiped open: the background stays as it is.
    if (this.args.shouldScaleBackground && swipeAmount && swipeAmount > 0 && this.isOpen) {
      setStyles(wrapper, {
        'border-radius': `${BORDER_RADIUS}px`,
        overflow: 'hidden',
        ...(isVertical(side)
          ? {
              transform: `scale(${this.#scale()}) translate3d(0, calc(env(safe-area-inset-top) + 14px), 0)`,
              'transform-origin': 'top',
            }
          : {
              transform: `scale(${this.#scale()}) translate3d(calc(env(safe-area-inset-top) + 14px), 0, 0)`,
              'transform-origin': 'left',
            }),
        'transition-property': 'transform, border-radius',
        'transition-duration': `${DURATION}s`,
        'transition-timing-function': EASE,
      })
    }
  }

  /** The pointer let go: close it, snap it, or put it back. */
  onRelease(event: PointerEvent | MouseEvent | null): void {
    const drawer = this.contentElement
    if (!this.isDragging || !drawer) return
    drawer.classList.remove(DRAG_CLASS)
    this.#isAllowedToDrag = false
    this.isDragging = false
    const dragEndTime = Date.now()
    const side = this.side
    const swipeAmount = getTranslate(drawer, side)
    if (
      !event ||
      !(event.target instanceof Element) ||
      !this.#shouldDrag(event.target, false) ||
      !swipeAmount ||
      Number.isNaN(swipeAmount)
    )
      return
    if (this.#dragStartTime === null) return

    const timeTaken = dragEndTime - this.#dragStartTime
    const distMoved = this.#pointerStart - (isVertical(side) ? event.pageY : event.pageX)
    const velocity = Math.abs(distMoved) / Math.max(timeTaken, 1)
    const pointerEvent = event as PointerEvent

    if (this.snapPoints) {
      const multiplier = side === 'bottom' || side === 'right' ? 1 : -1
      this.#releaseSnapPoints(distMoved * multiplier, velocity)
      this.#released(pointerEvent, true)
      return
    }

    // Moved toward open: nothing to do but put it back.
    if (side === 'bottom' || side === 'right' ? distMoved > 0 : distMoved < 0) {
      this.resetDrawer()
      this.#released(pointerEvent, true)
      return
    }
    if (velocity > VELOCITY_THRESHOLD) {
      this.closeDrawer()
      this.#released(pointerEvent, false)
      return
    }
    const window = drawer.ownerDocument.defaultView ?? globalThis.window
    const rect = drawer.getBoundingClientRect()
    const visibleHeight = Math.min(rect.height, window.innerHeight)
    const visibleWidth = Math.min(rect.width, window.innerWidth)
    const visible = side === 'left' || side === 'right' ? visibleWidth : visibleHeight
    if (Math.abs(swipeAmount) >= visible * this.closeThreshold) {
      this.closeDrawer()
      this.#released(pointerEvent, false)
      return
    }
    this.#released(pointerEvent, true)
    this.resetDrawer()
  }

  #released(event: PointerEvent, open: boolean): void {
    this.args.onRelease?.(event, open)
    this.args.parent?.onNestedRelease(open)
  }

  // ----- A drawer nested in this one (vaul's NestedRoot) -----------------------------------

  /** A drawer nested in this one opened or closed: step this one back, or forward again. */
  onNestedOpenChange(open: boolean): void {
    const drawer = this.contentElement
    const width = this.#viewport.width
    const scale = open ? (width - NESTED_DISPLACEMENT) / width : 1
    const initialTranslate = open ? -NESTED_DISPLACEMENT : 0
    clearTimeout(this.#nestedOpenChangeTimer)
    const side = this.side
    setStyles(drawer, {
      transition: transformTransition,
      transform: `scale(${scale}) ${translate(side, initialTranslate)}`,
    })
    if (!open && drawer) {
      this.#nestedOpenChangeTimer = setTimeout(() => {
        const value = getTranslate(drawer, side) ?? 0
        setStyles(drawer, { transition: 'none', transform: translate(side, value) })
      }, DURATION * 1000)
    }
  }

  /** A drawer nested in this one is dragged: this one comes forward as it goes. */
  onNestedDrag(percentageDragged: number): void {
    if (percentageDragged < 0) return
    const width = this.#viewport.width
    const initialScale = (width - NESTED_DISPLACEMENT) / width
    const scale = initialScale + percentageDragged * (1 - initialScale)
    const offset = -NESTED_DISPLACEMENT + percentageDragged * NESTED_DISPLACEMENT
    setStyles(this.contentElement, {
      transform: `scale(${scale}) ${translate(this.side, offset)}`,
      transition: 'none',
    })
  }

  /** A drawer nested in this one was let go: if it stays open, this one steps back again. */
  onNestedRelease(open: boolean): void {
    if (!open) return
    const side = this.side
    const { width, height } = this.#viewport
    const dimension = isVertical(side) ? height : width
    const scale = (dimension - NESTED_DISPLACEMENT) / dimension
    setStyles(this.contentElement, {
      transition: transformTransition,
      transform: `scale(${scale}) ${translate(side, -NESTED_DISPLACEMENT)}`,
    })
  }

  // ----- The scaled background (vaul's useScaleBackground) ----------------------------------

  #backgroundTimer: ReturnType<typeof setTimeout> | undefined

  /** Scales the background back, while it is open; returns the function that undoes it. */
  scaleBackground(element: HTMLElement): (() => void) | undefined {
    const document = element.ownerDocument
    const wrapper = document.querySelector(WRAPPER)
    if (!(wrapper instanceof HTMLElement)) return undefined
    clearTimeout(this.#backgroundTimer)
    const body = document.body
    const initialBackground = body.style.backgroundColor
    const vertical = isVertical(this.side)
    if (this.args.setBackgroundColorOnScale !== false && !this.args.noBodyStyles) {
      assignStyles(body, { background: 'black' })
    }
    assignStyles(wrapper, {
      'transform-origin': vertical ? 'top' : 'left',
      'transition-property': 'transform, border-radius',
      'transition-duration': `${DURATION}s`,
      'transition-timing-function': EASE,
    })
    const restoreWrapper = assignStyles(wrapper, {
      'border-radius': `${BORDER_RADIUS}px`,
      overflow: 'hidden',
      transform: vertical
        ? `scale(${this.#scale()}) translate3d(0, calc(env(safe-area-inset-top) + 14px), 0)`
        : `scale(${this.#scale()}) translate3d(calc(env(safe-area-inset-top) + 14px), 0, 0)`,
    })
    return () => {
      restoreWrapper()
      this.#backgroundTimer = setTimeout(() => {
        if (initialBackground) body.style.background = initialBackground
        else body.style.removeProperty('background')
      }, DURATION * 1000)
    }
  }

  // ----- A phone's keyboard (vaul's repositionInputs) ----------------------------------------

  /** The visual viewport resized: if a phone's keyboard opened over an input, keep it in view. */
  onVisualViewportChange = (): void => {
    const drawer = this.contentElement
    if (!drawer || !this.repositionInputs) return
    const window = drawer.ownerDocument.defaultView ?? globalThis.window
    if (!isInput(drawer.ownerDocument.activeElement) && !this.#keyboardIsOpen) return
    const visualViewportHeight = window.visualViewport?.height || 0
    const totalHeight = window.innerHeight
    // The keyboard's height.
    let diffFromInitial = totalHeight - visualViewportHeight
    const drawerHeight = drawer.getBoundingClientRect().height || 0
    const isTallEnough = drawerHeight > totalHeight * 0.8
    if (!this.#initialDrawerHeight) this.#initialDrawerHeight = drawerHeight
    const offsetFromTop = drawer.getBoundingClientRect().top
    // A change of 60px or more means the keyboard really opened or closed.
    if (Math.abs(this.#previousDiffFromInitial - diffFromInitial) > 60) {
      this.#keyboardIsOpen = !this.#keyboardIsOpen
    }
    const snapPoints = this.snapPoints
    const activeIndex = this.activeSnapPointIndex
    if (snapPoints && snapPoints.length > 0 && activeIndex) {
      diffFromInitial += this.snapPointsOffset[activeIndex] || 0
    }
    this.#previousDiffFromInitial = diffFromInitial
    if (drawerHeight > visualViewportHeight || this.#keyboardIsOpen) {
      const height = drawer.getBoundingClientRect().height
      let newDrawerHeight = height
      if (height > visualViewportHeight) {
        newDrawerHeight = visualViewportHeight - (isTallEnough ? offsetFromTop : WINDOW_TOP_OFFSET)
      }
      if (this.args.fixed) {
        drawer.style.height = `${height - Math.max(diffFromInitial, 0)}px`
      } else {
        drawer.style.height = `${Math.max(newDrawerHeight, visualViewportHeight - offsetFromTop)}px`
      }
    } else if (!isMobileFirefox()) {
      drawer.style.height = `${this.#initialDrawerHeight}px`
    }
    if (snapPoints && snapPoints.length > 0 && !this.#keyboardIsOpen) {
      drawer.style.bottom = '0px'
    } else {
      drawer.style.bottom = `${Math.max(diffFromInitial, 0)}px`
    }
  }

  // ----- The content's pointer (vaul's Content) ----------------------------------------------

  /** Whether a pointer that has moved by `delta` is dragging along the drawer's axis. */
  #isDeltaInDirection(delta: { x: number; y: number }, threshold: number): boolean {
    if (this.#wasBeyondThePoint) return true
    const side = this.side
    const deltaY = Math.abs(delta.y)
    const deltaX = Math.abs(delta.x)
    const isDeltaX = deltaX > deltaY
    const factor = side === 'bottom' || side === 'right' ? 1 : -1
    if (side === 'left' || side === 'right') {
      const isReverseDirection = delta.x * factor < 0
      if (!isReverseDirection && deltaX >= 0 && deltaX <= threshold) return isDeltaX
    } else {
      const isReverseDirection = delta.y * factor < 0
      if (!isReverseDirection && deltaY >= 0 && deltaY <= threshold) return !isDeltaX
    }
    this.#wasBeyondThePoint = true
    return true
  }

  #contentPointerDown = (event: PointerEvent): void => {
    if (this.args.handleOnly) return
    this.#contentPointerStart = { x: event.pageX, y: event.pageY }
    this.onPress(event)
  }

  #contentPointerMove = (event: PointerEvent): void => {
    this.#lastKnownPointerEvent = event
    if (this.args.handleOnly || !this.#contentPointerStart) return
    const y = event.pageY - this.#contentPointerStart.y
    const x = event.pageX - this.#contentPointerStart.x
    const threshold = event.pointerType === 'touch' ? 10 : 2
    if (this.#isDeltaInDirection({ x, y }, threshold)) this.onDrag(event)
    else if (Math.abs(x) > threshold || Math.abs(y) > threshold) this.#contentPointerStart = null
  }

  #contentPointerUp = (event: PointerEvent | null): void => {
    this.#contentPointerStart = null
    this.#wasBeyondThePoint = false
    this.onRelease(event)
  }

  #contentPointerOut = (): void => this.#contentPointerUp(this.#lastKnownPointerEvent)

  #contentContextMenu = (): void => {
    if (this.#lastKnownPointerEvent) this.#contentPointerUp(this.#lastKnownPointerEvent)
  }

  // ----- The parts' attributes and listeners, beside a Dialog's ------------------------------

  /** vaul's attributes and pointer listeners on the content, beside the Dialog's content part. */
  drawerContent: PartModifier = part<HTMLElement>(() => ({
    attributes: {
      'data-vaul-drawer': '',
      'data-vaul-drawer-direction': this.direction,
      'data-vaul-snap-points': this.isOpen && this.hasSnapPoints ? 'true' : 'false',
      'data-vaul-custom-container': 'false',
      'data-vaul-animate': this.#shouldAnimate ? 'true' : 'false',
      'data-snap-point': this.hasSnapPoints ? String(this.activeSnapPoint) : undefined,
    },
    // The Dialog's content part keeps the element too, but it is installed after this one, and
    // the drawer's own modifiers need it from the start.
    element: element => {
      this.contentElement = element
      return () => {
        if (this.contentElement === element) this.contentElement = null
      }
    },
    on: {
      pointerdown: this.#contentPointerDown,
      pointermove: this.#contentPointerMove,
      pointerup: this.#contentPointerUp,
      pointerout: this.#contentPointerOut,
      contextmenu: this.#contentContextMenu,
    },
  }))

  /** vaul's attributes on the overlay, beside the Dialog's overlay part. */
  drawerOverlay: PartModifier = part<HTMLElement>(() => ({
    attributes: {
      'data-vaul-overlay': '',
      'data-vaul-snap-points': this.isOpen && this.hasSnapPoints ? 'true' : 'false',
      'data-vaul-snap-points-overlay': this.isOpen && this.shouldFade ? 'true' : 'false',
      'data-vaul-animate': this.#shouldAnimate ? 'true' : 'false',
    },
    on: { mouseup: (event: MouseEvent) => this.onRelease(event) },
  }))

  // ----- The handle (vaul's Handle) ----------------------------------------------------------

  #cancelHandleInteraction = (): void => {
    clearTimeout(this.#handleCloseTimeout)
    this.#shouldCancelInteraction = false
  }

  /** A tap on the handle: the next snap point, or closed after the last. */
  #cycleSnapPoints(preventCycle: boolean): void {
    // A tap while dragging, or a long press, isn't a tap.
    if (this.isDragging || preventCycle || this.#shouldCancelInteraction) {
      this.#cancelHandleInteraction()
      return
    }
    this.#cancelHandleInteraction()
    const snapPoints = this.snapPoints
    // Without snap points there is nothing to cycle. (vaul 1.1.2 closes a drawer that isn't
    // dismissible here, which its own `dismissible` contradicts; Joinery doesn't.)
    if (!snapPoints || snapPoints.length === 0) return
    if (this.isLastSnapPoint && this.dismissible) {
      this.closeDrawer()
      return
    }
    const index = snapPoints.findIndex(point => point === this.activeSnapPoint)
    if (index === -1) return
    this.setActiveSnapPoint(snapPoints[index + 1] ?? null)
  }

  /** Makes your own element the handle: `<div {{d.handle}}>`. */
  handle: PartModifier<HTMLElement, { preventCycle?: boolean }> = part<
    HTMLElement,
    { preventCycle?: boolean }
  >(named => ({
    attributes: {
      'data-vaul-drawer-visible': this.isOpen ? 'true' : 'false',
      'data-vaul-handle': '',
      'aria-hidden': 'true',
      'data-slot': `${this.slot}-handle`,
      'data-test-jn-part': 'handle',
    },
    on: {
      click: () => {
        // The second tap of a double tap cancels the first.
        if (this.#shouldCancelInteraction) {
          this.#cancelHandleInteraction()
          return
        }
        const token = waiter.beginAsync()
        setTimeout(() => {
          waiter.endAsync(token)
          this.#cycleSnapPoints(Boolean(named.preventCycle))
        }, DOUBLE_TAP_TIMEOUT)
      },
      pointercancel: this.#cancelHandleInteraction,
      pointerdown: (event: PointerEvent) => {
        if (this.args.handleOnly) this.onPress(event)
        this.#handleCloseTimeout = setTimeout(() => {
          // A long press isn't a tap.
          this.#shouldCancelInteraction = true
        }, LONG_HANDLE_PRESS_TIMEOUT)
      },
      pointermove: (event: PointerEvent) => {
        if (this.args.handleOnly) this.onDrag(event)
      },
    },
  }))
}
