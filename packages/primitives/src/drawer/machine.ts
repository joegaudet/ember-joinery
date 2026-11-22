// A drawer's modes and timers, as a Switchyard chart. Whether it is open stays with the
// DialogController's ControllableState; this only follows what was committed. Bundled into
// @ember-joinery/primitives/drawer; it isn't a subpath of its own.
import { after, Machine, region, State, transition } from '@switchyard-ts/core'
import { machine } from '@switchyard-ts/ember'

/** vaul's animation, in ms. */
const DURATION = 500
const LONG_HANDLE_PRESS_TIMEOUT = 250
const DOUBLE_TAP_TIMEOUT = 120

export class Lifecycle extends State {
  declare private readonly brand: never
  static Closed = Lifecycle.of('closed')
  /** It opened: its slide in is running. */
  static Opening = Lifecycle.of('opening')
  static Open = Lifecycle.of('open')
  /** It closed: its slide out is running. */
  static Closing = Lifecycle.of('closing')
}

export class Gesture extends State {
  declare private readonly brand: never
  static Idle = Gesture.of('idle')
  /** A pointer went down on it: maybe a drag. */
  static Pressed = Gesture.of('pressed')
  /** It moves with the pointer until let go. */
  static Dragging = Gesture.of('dragging')
}

export class HandlePress extends State {
  declare private readonly brand: never
  static Idle = HandlePress.of('idle')
  /** A pointer is down on the handle: a tap, unless it stays down long. */
  static Down = HandlePress.of('down')
  /** Down long enough that it isn't a tap. */
  static LongPress = HandlePress.of('long-press')
}

export class HandleTap extends State {
  declare private readonly brand: never
  static Idle = HandleTap.of('idle')
  /** The handle was clicked: it cycles once the double-tap wait is out. */
  static Pending = HandleTap.of('pending')
}

/** A timer whose effect lands once the animation is over. */
export class Settle extends State {
  declare private readonly brand: never
  static Idle = Settle.of('idle')
  static Waiting = Settle.of('waiting')
}

/** What the chart's timers act on. */
export interface DrawerHost {
  /** It has finished opening or closing. */
  animationEnded(open: boolean): void
  /** A tap on the handle has outlasted the double-tap wait. */
  cycleSnapPoints(): void
  /** A drawer nested in it has finished closing. */
  pinNested(): void
  /** The background has finished scaling back up. */
  restoreBackground(): void
}

/**
 * vaul's flags and timeouts as parallel regions: the open lifecycle (each half `DURATION`
 * long), the drag, the handle's long press and tap, and the waits after a nested drawer closes
 * and after the background is put back. Leaving a state drops its timer, so a close cancels
 * the open's animation end and `stop()` cancels everything.
 */
export class DrawerMachine extends Machine<{
  lifecycle: Lifecycle
  gesture: Gesture
  handlePress: HandlePress
  handleTap: HandleTap
  nested: Settle
  background: Settle
}> {
  @region(Lifecycle) declare lifecycle: Lifecycle
  @region(Gesture) declare gesture: Gesture
  @region(HandlePress) declare handlePress: HandlePress
  @region(HandleTap) declare handleTap: HandleTap
  @region(Settle) declare nested: Settle
  @region(Settle) declare background: Settle

  readonly host: DrawerHost

  constructor(host: DrawerHost) {
    super()
    this.host = host
  }

  /** Whether it is pressed or dragged (vaul's `isDragging`). */
  get isDragging(): boolean {
    return this.gesture !== Gesture.Idle
  }

  /** Whether the drag has begun moving it (vaul's `isAllowedToDrag`). */
  get isMoving(): boolean {
    return this.gesture === Gesture.Dragging
  }

  /** Whether the handle is held long enough that a click isn't a tap. */
  get isLongPress(): boolean {
    return this.handlePress === HandlePress.LongPress
  }

  // ----- Opening and closing ---------------------------------------------------------------

  @transition({ from: [Lifecycle.Closed, Lifecycle.Closing], to: Lifecycle.Opening })
  opened() {}

  /** It was open from the start: nothing slides in. */
  @transition({ from: Lifecycle.Closed, to: Lifecycle.Open })
  startedOpen() {}

  @transition({ from: [Lifecycle.Opening, Lifecycle.Open], to: Lifecycle.Closing })
  closed() {}

  @after(DURATION, { from: Lifecycle.Opening, to: Lifecycle.Open })
  finishedOpening() {
    this.host.animationEnded(true)
  }

  @after(DURATION, { from: Lifecycle.Closing, to: Lifecycle.Closed })
  finishedClosing() {
    this.host.animationEnded(false)
  }

  // ----- Dragging --------------------------------------------------------------------------

  @transition({ from: [Gesture.Idle, Gesture.Pressed, Gesture.Dragging], to: Gesture.Pressed })
  press() {}

  @transition({ from: Gesture.Pressed, to: Gesture.Dragging })
  @transition({ from: Gesture.Dragging })
  move() {}

  /** Let go, or stopped: either way the drag is over. */
  @transition({ from: [Gesture.Pressed, Gesture.Dragging], to: Gesture.Idle })
  release() {}

  // ----- The handle ------------------------------------------------------------------------

  @transition({
    from: [HandlePress.Idle, HandlePress.Down, HandlePress.LongPress],
    to: HandlePress.Down,
    reenter: true,
  })
  handleDown() {}

  /** vaul's handleCancelInteraction: the long press is forgotten. */
  @transition({ from: [HandlePress.Down, HandlePress.LongPress], to: HandlePress.Idle })
  @transition({ from: HandlePress.Idle })
  handleCancel() {}

  @after(LONG_HANDLE_PRESS_TIMEOUT, { from: HandlePress.Down, to: HandlePress.LongPress })
  heldLong() {}

  /** A click on the handle: it cycles after the double-tap wait (a second click adds nothing). */
  @transition({ from: HandleTap.Idle, to: HandleTap.Pending })
  @transition({ from: HandleTap.Pending })
  tap() {}

  @after(DOUBLE_TAP_TIMEOUT, { from: HandleTap.Pending, to: HandleTap.Idle })
  tapped() {
    this.host.cycleSnapPoints()
  }

  // ----- Waits for the animation ----------------------------------------------------------

  /** A nested drawer closed: pin this one in place once it has come forward. */
  @transition({
    from: [Settle.Idle, Settle.Waiting],
    to: Settle.Waiting,
    in: 'nested',
    reenter: true,
  })
  nestedClosed() {}

  @transition({ from: [Settle.Idle, Settle.Waiting], to: Settle.Idle, in: 'nested' })
  nestedOpened() {}

  @after(DURATION, { from: Settle.Waiting, to: Settle.Idle, in: 'nested' })
  nestedSettled() {
    this.host.pinNested()
  }

  /** The background was put back: restore the body's colour once it has scaled up. */
  @transition({
    from: [Settle.Idle, Settle.Waiting],
    to: Settle.Waiting,
    in: 'background',
    reenter: true,
  })
  backgroundReleased() {}

  @transition({ from: [Settle.Idle, Settle.Waiting], to: Settle.Idle, in: 'background' })
  backgroundScaled() {}

  @after(DURATION, { from: Settle.Waiting, to: Settle.Idle, in: 'background' })
  backgroundSettled() {
    this.host.restoreBackground()
  }
}

/** A started `DrawerMachine`, stopped (its timers with it) when `owner` is destroyed. */
export function drawerMachine(owner: object, host: DrawerHost): DrawerMachine {
  return machine(owner, new DrawerMachine(host))
}
