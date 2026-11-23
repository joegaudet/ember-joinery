import { after, Machine, State, transition, type Clock } from '@switchyard-ts/core'
import { machine } from '@switchyard-ts/ember'

/**
 * Plain timers, which `settled()` doesn't wait for: a window that is open for a while (the
 * skip delay, a grace area) isn't work in progress, and waiting it out would close it.
 */
export const windowClock: Clock = {
  setTimeout: (fn, ms) => setTimeout(fn, ms),
  clearTimeout: handle => clearTimeout(handle as ReturnType<typeof setTimeout>),
}

export class DelayState extends State {
  declare private readonly brand: never
  /** The next to open waits for its delay. */
  static Delayed = DelayState.of('delayed')
  /** One is open: the next opens at once. */
  static Instant = DelayState.of('instant')
  /** One just closed: the next opens at once, for `skipDelayDuration`. */
  static Cooling = DelayState.of('cooling')
}

/** What a delay group reads its skip delay from. */
export interface DelayGroupHost {
  readonly skipDelayDuration: number
}

/**
 * Radix's skip delay, shared by a tooltip provider's tooltips and a navigation menu's items:
 * while one is open, and for `skipDelayDuration` after it closes, the next opens at once. Call
 * `opened()` and `closed()` when the owner's value has changed, not when it is asked to: a
 * controlled parent may refuse.
 */
export class DelayGroup extends Machine<DelayState> {
  static override clock = windowClock

  readonly host: DelayGroupHost

  constructor(host: DelayGroupHost) {
    super()
    this.host = host
  }

  get skipDelayDuration(): number {
    return this.host.skipDelayDuration
  }

  /** Whether the next to open waits for its delay. */
  get isOpenDelayed(): boolean {
    return this.matches(DelayState.Delayed)
  }

  /** One opened. */
  @transition({ to: DelayState.Instant })
  opened() {}

  /** One closed: the skip delay starts (again). Nothing was open: nothing changes. */
  @transition({ from: DelayState.Delayed })
  @transition({ to: DelayState.Cooling, reenter: true })
  closed() {}

  @after('skipDelayDuration', { from: DelayState.Cooling, to: DelayState.Delayed })
  cooled() {}
}

/** A started `DelayGroup`, stopped (its timer with it) when `owner` is destroyed. */
export function delayGroup(owner: object, host: DelayGroupHost): DelayGroup {
  return machine(owner, new DelayGroup(host))
}
