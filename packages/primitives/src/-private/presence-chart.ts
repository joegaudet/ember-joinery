import { invoke, Machine, State, transition } from '@switchyard-ts/core'
import { machine } from '@switchyard-ts/ember'

export class PresenceState extends State {
  declare private readonly brand: never
  /** `@present` is true: the content renders. */
  static Present = PresenceState.of('present')
  /** `@present` turned false: the content stays while its exit animation runs. */
  static Exiting = PresenceState.of('exiting')
  /** The content is gone. */
  static Exited = PresenceState.of('exited')
}

/** What a presence chart waits on. */
export interface PresenceHost {
  /** Waits for the element's exit animations: resolves at once when there are none. */
  waitForExit(signal: AbortSignal): Promise<void>
}

/**
 * Radix's `Presence` as a chart: `exit()` keeps the content while its exit animation runs, and
 * `enter()` during the exit keeps it for good, aborting the wait.
 */
export class PresenceChart extends Machine<PresenceState> {
  readonly host: PresenceHost

  constructor(host: PresenceHost) {
    super()
    this.host = host
  }

  /** `@present` turned true. */
  @transition({ to: PresenceState.Present })
  enter() {}

  /** `@present` turned false, and the render that says so is over. */
  @transition({ from: PresenceState.Present, to: PresenceState.Exiting })
  exit() {}

  /** It starts with `@present` false: nothing to wait for. */
  @transition({ to: PresenceState.Exited })
  absent() {}

  @invoke(PresenceState.Exiting, { onDone: PresenceState.Exited, onError: PresenceState.Exited })
  waitForExit(signal: AbortSignal): Promise<void> {
    return this.host.waitForExit(signal)
  }
}

/** A started `PresenceChart`, stopped (its wait aborted) when `owner` is destroyed. */
export function presenceChart(owner: object, host: PresenceHost): PresenceChart {
  return machine(owner, new PresenceChart(host))
}
