import { after, Machine, State, transition } from '@switchyard-ts/core'
import { machine } from '@switchyard-ts/ember'

/** What a scroll area's charts read their hide delay from. */
export interface HideDelayHost {
  readonly scrollHideDelay: number
}

export class ScrollbarVisibility extends State {
  declare private readonly brand: never
  static Hidden = ScrollbarVisibility.of('hidden')
  /** It scrolls: idle 100ms after the last scroll. */
  static Scrolling = ScrollbarVisibility.of('scrolling')
  /** The pointer is over the scrollbar. */
  static Interacting = ScrollbarVisibility.of('interacting')
  /** Hidden after `scrollHideDelay`. */
  static Idle = ScrollbarVisibility.of('idle')
}

/**
 * The `scroll` type's chart for one scrollbar, as Radix's machine: it shows while the viewport
 * scrolls or the pointer is over it, and hides `scrollHideDelay` after both stop. An event a
 * state doesn't take does nothing, as in Radix.
 */
export class ScrollbarMachine extends Machine<ScrollbarVisibility> {
  readonly host: HideDelayHost

  constructor(host: HideDelayHost) {
    super()
    this.host = host
  }

  get scrollHideDelay(): number {
    return this.host.scrollHideDelay
  }

  /** The viewport scrolled this way (restarting the wait for the end of it). */
  @transition({
    from: ScrollbarVisibility.Scrolling,
    to: ScrollbarVisibility.Scrolling,
    reenter: true,
  })
  @transition({
    from: [ScrollbarVisibility.Hidden, ScrollbarVisibility.Idle],
    to: ScrollbarVisibility.Scrolling,
  })
  @transition({})
  scroll() {}

  @transition({ from: ScrollbarVisibility.Scrolling, to: ScrollbarVisibility.Idle })
  @transition({})
  scrollEnd() {}

  @transition({
    from: [ScrollbarVisibility.Scrolling, ScrollbarVisibility.Idle],
    to: ScrollbarVisibility.Interacting,
  })
  @transition({})
  pointerEnter() {}

  @transition({ from: ScrollbarVisibility.Interacting, to: ScrollbarVisibility.Idle })
  @transition({})
  pointerLeave() {}

  @transition({ from: ScrollbarVisibility.Idle, to: ScrollbarVisibility.Hidden })
  @transition({})
  hide() {}

  @after(100, { from: ScrollbarVisibility.Scrolling, to: ScrollbarVisibility.Idle })
  scrollEnded() {}

  @after('scrollHideDelay', { from: ScrollbarVisibility.Idle, to: ScrollbarVisibility.Hidden })
  hidden() {}
}

export class HoverState extends State {
  declare private readonly brand: never
  static Out = HoverState.of('out')
  static In = HoverState.of('in')
  /** The pointer left: out after `scrollHideDelay`. */
  static Leaving = HoverState.of('leaving')
}

/** The `hover` type's chart: whether the pointer is over the area, until the hide delay is up. */
export class AreaHover extends Machine<HoverState> {
  readonly host: HideDelayHost

  constructor(host: HideDelayHost) {
    super()
    this.host = host
  }

  get scrollHideDelay(): number {
    return this.host.scrollHideDelay
  }

  get isHovered(): boolean {
    return !this.matches(HoverState.Out)
  }

  @transition({ to: HoverState.In })
  enter() {}

  /** Restarts the wait when it is already leaving. */
  @transition({ from: [HoverState.In, HoverState.Leaving], to: HoverState.Leaving, reenter: true })
  @transition({})
  leave() {}

  @after('scrollHideDelay', { from: HoverState.Leaving, to: HoverState.Out })
  left() {}
}

/** A started `AreaHover`, stopped (its timer with it) when `owner` is destroyed. */
export function areaHover(owner: object, host: HideDelayHost): AreaHover {
  return machine(owner, new AreaHover(host))
}
