import { after, Machine, onEntry, region, State, transition, type Clock } from '@switchyard-ts/core'
import { machine } from '@switchyard-ts/ember'

/** How long a toast takes to animate out before it is removed (sonner's `TIME_BEFORE_UNMOUNT`). */
export const TIME_BEFORE_UNMOUNT = 200

export class LifeState extends State {
  declare private readonly brand: never
  /** Rendered, not yet measured: `data-mounted="false"`. */
  static Measuring = LifeState.of('measuring')
  static Shown = LifeState.of('shown')
  /** Animating out, `TIME_BEFORE_UNMOUNT` long. */
  static Removing = LifeState.of('removing')
  /** Taken off its Toaster's list. */
  static Removed = LifeState.of('removed')
}

export class GestureState extends State {
  declare private readonly brand: never
  static Idle = GestureState.of('idle')
  /** A pointer is down on it: `data-swiping`. */
  static Pressed = GestureState.of('pressed')
  /** It follows the pointer: `data-swiped` as well. */
  static Swiping = GestureState.of('swiping')
  /** Swiped far or fast enough: it flies off (`data-swipe-out`). */
  static SwipedOut = GestureState.of('swiped-out')
}

/** What a toast's chart works on. */
export interface ToastLifeHost {
  /** It starts to animate out. */
  removing(): void
  /** It has animated out: its Toaster takes it off the list. */
  unmount(): void
}

/**
 * A toast's life, as two regions: measured, shown, animating out and gone; and a press that may
 * turn into a swipe and fly it off. A swipe out removes it, and nothing brings it back.
 */
export class ToastLife extends Machine<{ life: LifeState; gesture: GestureState }> {
  readonly host: ToastLifeHost

  @region(LifeState) declare life: LifeState
  @region(GestureState) declare gesture: GestureState

  constructor(host: ToastLifeHost) {
    super()
    this.host = host
  }

  /** Measured: `data-mounted` turns on, and its entrance starts. */
  @transition({ from: LifeState.Measuring, to: LifeState.Shown })
  @transition({ from: [LifeState.Shown, LifeState.Removing, LifeState.Removed] })
  measured() {}

  /** Closes it; once is enough. */
  @transition({ from: [LifeState.Measuring, LifeState.Shown], to: LifeState.Removing })
  @transition({ from: [LifeState.Removing, LifeState.Removed] })
  remove() {}

  @onEntry(LifeState.Removing)
  startRemoving() {
    this.host.removing()
  }

  @after(TIME_BEFORE_UNMOUNT, { from: LifeState.Removing, to: LifeState.Removed })
  unmounted() {
    this.host.unmount()
  }

  @transition({ from: GestureState.Idle, to: GestureState.Pressed })
  @transition({ from: [GestureState.Pressed, GestureState.Swiping, GestureState.SwipedOut] })
  press() {}

  /** The pointer moved it. */
  @transition({ from: GestureState.Pressed, to: GestureState.Swiping })
  @transition({ from: [GestureState.Idle, GestureState.Swiping, GestureState.SwipedOut] })
  drag() {}

  /** Let go short of a swipe out: it springs back. */
  @transition({ from: [GestureState.Pressed, GestureState.Swiping], to: GestureState.Idle })
  @transition({ from: [GestureState.Idle, GestureState.SwipedOut] })
  release() {}

  /** A drag (HTML drag and drop) took the pointer. */
  @transition({ from: [GestureState.Pressed, GestureState.Swiping], to: GestureState.Idle })
  @transition({ from: [GestureState.Idle, GestureState.SwipedOut] })
  dragEnd() {}

  @transition({ in: 'gesture', to: GestureState.SwipedOut })
  swipeOut() {
    this.remove()
  }
}

export class TimerState extends State {
  declare private readonly brand: never
  /** A loading toast, `duration: Infinity`, or one already closing: no timer. */
  static None = TimerState.of('none')
  /** Counting down what is left of its duration. */
  static Running = TimerState.of('running')
  /** The stack is expanded, pressed, or the page hidden. */
  static Paused = TimerState.of('paused')
}

/** What a toast's timer reads, and tells when its time is up. */
export interface ToastTimerHost {
  readonly duration: number
  /** Whether it has no timer now (loading, or closing). */
  readonly isUntimed: boolean
  readonly isPaused: boolean
  timedOut(): void
}

/** setTimeout without a test waiter, as sonner's timer has none: `settled()` would wait it out. */
const untracked: Clock = {
  setTimeout: (fn, ms) => setTimeout(fn, ms),
  clearTimeout: handle => clearTimeout(handle as ReturnType<typeof setTimeout>),
}

/**
 * sonner's auto-close timer, as a chart. `sync()` is sonner's timer effect, sent whenever the
 * toast, its duration or whether it is paused changes: a pause banks the time that ran since
 * the last start (once), a resume or a change to the toast starts what is left again.
 */
export class ToastTimer extends Machine<TimerState> {
  static override clock = untracked

  readonly host: ToastTimerHost
  #duration: number
  #remaining: number
  /** When it last started running, if it hasn't paused since (sonner's `last < start`). */
  #startedAt: number | undefined

  constructor(host: ToastTimerHost) {
    super()
    this.host = host
    this.#remaining = this.#duration = host.duration
  }

  get remainingTime(): number {
    return Math.max(0, this.#remaining)
  }

  get hasNoTimer(): boolean {
    return this.host.isUntimed || this.host.duration === Infinity
  }

  get isPaused(): boolean {
    return this.host.isPaused
  }

  @transition({ to: TimerState.None, guard: (m: ToastTimer) => m.hasNoTimer })
  @transition({
    from: [TimerState.None, TimerState.Running],
    to: TimerState.Paused,
    guard: (m: ToastTimer) => m.isPaused,
  })
  @transition({ from: TimerState.Paused, guard: (m: ToastTimer) => m.isPaused })
  @transition({ to: TimerState.Running, reenter: true })
  sync() {
    const { duration } = this.host
    if (duration !== this.#duration) this.#remaining = this.#duration = duration
  }

  @onEntry(TimerState.Running)
  started() {
    this.#startedAt = Date.now()
  }

  @onEntry(TimerState.Paused)
  paused() {
    if (this.#startedAt !== undefined) this.#remaining -= Date.now() - this.#startedAt
    this.#startedAt = undefined
  }

  @after('remainingTime', { from: TimerState.Running, to: TimerState.None })
  timedOut() {
    this.host.timedOut()
  }
}

/** A started `ToastLife`, stopped (its unmount timer with it) when `owner` is destroyed. */
export function toastLife(owner: object, host: ToastLifeHost): ToastLife {
  return machine(owner, new ToastLife(host))
}

/** A started `ToastTimer`, stopped when `owner` is destroyed. */
export function toastTimer(owner: object, host: ToastTimerHost): ToastTimer {
  return machine(owner, new ToastTimer(host))
}
