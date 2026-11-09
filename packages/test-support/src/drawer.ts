import { click, settled } from '@ember/test-helpers'
import { DialogHarness } from './dialog.ts'

/** How a drag goes: how long it takes, in how many moves, and with what. */
export interface DragOptions {
  /**
   * Milliseconds from press to release. Default `600`: slow enough (under vaul's 0.4px a
   * millisecond, for a drag under 240px) that the distance decides, not the speed.
   */
  duration?: number
  /** How many `pointermove`s it takes. Default `6`. */
  steps?: number
  /** Where it starts: an element in the drawer. Default the drawer itself. */
  from?: Element
  /** `mouse` (the default), `pen` or `touch`. */
  pointerType?: 'mouse' | 'pen' | 'touch'
}

const wait = (ms: number) => new Promise<void>(resolve => setTimeout(resolve, ms))

/** Sends one pointer event at a point on the page, as a pointer does. */
function pointer(
  target: Element,
  type: string,
  x: number,
  y: number,
  pointerType: string,
): PointerEvent {
  const event = new PointerEvent(type, {
    bubbles: true,
    cancelable: true,
    composed: true,
    clientX: x,
    clientY: y,
    pointerId: 1,
    pointerType,
    isPrimary: true,
    button: 0,
    buttons: type === 'pointerup' ? 0 : 1,
  })
  target.dispatchEvent(event)
  return event
}

/**
 * Drives a `<Drawer>` from `@ember-joinery/ember` (or the headless one from
 * `@ember-joinery/primitives/drawer`). It is a `DialogHarness`, so it opens, closes and reads
 * the drawer's ARIA as one, and it drags the drawer as a finger or mouse does: a press, moves
 * along its axis, and a release.
 *
 *   const drawer = new DrawerHarness('goal')
 *   await drawer.open()
 *   await drawer.afterOpening()
 *   await drawer.drag(200) // toward closed: down, for a drawer from the bottom
 *   assert.false(drawer.isOpen)
 */
export class DrawerHarness extends DialogHarness {
  static override component = 'drawer'

  /** The edge it comes in from: `top`, `right`, `bottom` or `left` (`data-vaul-drawer-direction`). */
  get direction(): string | null {
    return this.content?.getAttribute('data-vaul-drawer-direction') ?? null
  }

  /**
   * The physical edge it is on: its direction, but right to left a `left` drawer is on the
   * right (left and right are the inline start and end).
   */
  get side(): string | null {
    const direction = this.direction
    const content = this.content
    if (!content || (direction !== 'left' && direction !== 'right')) return direction
    if (getComputedStyle(content).direction !== 'rtl') return direction
    return direction === 'left' ? 'right' : 'left'
  }

  /** The handle, or `null`. */
  get handle(): HTMLElement | null {
    return this.queryPart('handle')
  }

  /** Whether it is being dragged now (vaul's `vaul-dragging` class). */
  get isDragging(): boolean {
    return Boolean(this.content?.classList.contains('vaul-dragging'))
  }

  /** The snap point it rests at, as its `data-snap-point` says (`"0.5"`, `"148px"`), or `null`. */
  get activeSnapPoint(): string | null {
    return this.content?.getAttribute('data-snap-point') ?? null
  }

  /** How far it is moved along its axis now, in pixels, from its computed transform. */
  get offset(): number {
    const content = this.content
    if (!content) return 0
    const transform = getComputedStyle(content).transform
    if (!transform || transform === 'none') return 0
    const matrix = new DOMMatrixReadOnly(transform)
    const side = this.side
    return side === 'top' || side === 'bottom' ? matrix.m42 : matrix.m41
  }

  /** Ends its animations and transitions now, so it is measured where it rests. */
  finishAnimations(): void {
    for (const element of [this.content, this.overlay]) {
      for (const animation of element?.getAnimations() ?? []) animation.finish()
    }
  }

  /**
   * Waits out a drawer's opening: its slide in, and the half second after it opens in which a
   * drawer from the top or bottom lets its content scroll rather than drag, as vaul's does.
   */
  async afterOpening(): Promise<void> {
    this.finishAnimations()
    await wait(510)
    await settled()
  }

  /**
   * Drags it along its axis by `distance` pixels toward closed (down, for a drawer from the
   * bottom; left, for one from the left), or toward open with a negative distance, and lets
   * go. Fast drags (a short `duration`) close it as a flick does.
   */
  async drag(distance: number, options: DragOptions = {}): Promise<void> {
    const content = this.content
    if (!content) throw new Error(`${this} is closed: there is nothing to drag`)
    const { duration = 600, steps = 6, pointerType = 'mouse' } = options
    const from = options.from ?? content
    const rect = from.getBoundingClientRect()
    const x = rect.left + rect.width / 2
    const y = rect.top + Math.min(rect.height / 2, 24)
    const side = this.side
    const vertical = side === 'top' || side === 'bottom'
    const sign = side === 'bottom' || side === 'right' ? 1 : -1
    const at = (fraction: number): [number, number] => {
      const moved = distance * fraction * sign
      return vertical ? [x, y + moved] : [x + moved, y]
    }

    // The pointer is captured where it went down, so every event goes there.
    pointer(from, 'pointerdown', x, y, pointerType)
    for (let step = 1; step <= steps; step++) {
      await wait(duration / (steps + 1))
      const [px, py] = at(step / steps)
      pointer(from, 'pointermove', px, py, pointerType)
    }
    await wait(duration / (steps + 1))
    const [ex, ey] = at(1)
    pointer(from, 'pointerup', ex, ey, pointerType)
    await settled()
  }

  /** A quick flick toward closed: `distance` pixels in 40ms. */
  async swipe(distance = 80, options: Omit<DragOptions, 'duration'> = {}): Promise<void> {
    await this.drag(distance, { ...options, duration: 40, steps: 3 })
  }

  /** Taps its handle (vaul's Handle): the next snap point, or closed after the last. */
  async tapHandle(): Promise<void> {
    const handle = this.handle
    if (!handle) throw new Error(`${this} has no handle`)
    await click(handle)
  }
}
