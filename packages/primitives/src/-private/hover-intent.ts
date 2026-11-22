import { after, Machine, State, transition } from '@switchyard-ts/core'
import { machine } from '@switchyard-ts/ember'

export class IntentState extends State {
  declare private readonly brand: never
  /** No timer is waiting. */
  static Idle = IntentState.of('idle')
  /** Waiting `openDelay` before it opens. */
  static Opening = IntentState.of('opening')
  /** Waiting `closeDelay` before it closes. */
  static Closing = IntentState.of('closing')
}

/** What a hover intent opens and closes. */
export interface IntentHost {
  readonly openDelay: number
  readonly closeDelay: number
  /** Whether something (a press, a text selection) keeps it open: `leave()` then waits for nothing. */
  readonly isHeld?: boolean
  setOpen(open: boolean): void
}

/**
 * Radix's open and close timers, as a chart: `enter()` opens after `openDelay`, `leave()`
 * closes after `closeDelay`, and each cancels the other. It only times the requests: whether
 * the thing is open stays with its owner's `ControllableState`, so a controlled `@open` that
 * refuses a request can't leave the chart thinking otherwise.
 */
export class HoverIntent extends Machine<IntentState> {
  readonly host: IntentHost

  constructor(host: IntentHost) {
    super()
    this.host = host
  }

  get openDelay(): number {
    return this.host.openDelay
  }

  get closeDelay(): number {
    return this.host.closeDelay
  }

  get isHeld(): boolean {
    return this.host.isHeld ?? false
  }

  /** The pointer or focus arrived: open after `openDelay` (restarting a wait already running). */
  @transition({ to: IntentState.Opening, reenter: true })
  enter() {}

  /** The pointer or focus left: close after `closeDelay`, unless something holds it open. */
  @transition({ to: IntentState.Idle, guard: (m: HoverIntent) => m.isHeld })
  @transition({ to: IntentState.Closing, reenter: true })
  leave() {}

  /** Opened or closed some other way: drop whatever is waiting. */
  @transition({ to: IntentState.Idle })
  cancel() {}

  @after('openDelay', { from: IntentState.Opening, to: IntentState.Idle })
  opened() {
    this.host.setOpen(true)
  }

  @after('closeDelay', { from: IntentState.Closing, to: IntentState.Idle })
  closed() {
    this.host.setOpen(false)
  }
}

/** A started `HoverIntent`, stopped (its timers with it) when `owner` is destroyed. */
export function hoverIntent(owner: object, host: IntentHost): HoverIntent {
  return machine(owner, new HoverIntent(host))
}
