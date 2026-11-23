import { tracked } from '@glimmer/tracking'
import { Machine, onEntry, onExit, region, State, transition } from '@switchyard-ts/core'
import { machine } from '@switchyard-ts/ember'
import type { DateRange } from '../dates.ts'

/** Which month the open calendar shows. */
export class Month extends State {
  declare private readonly brand: never
  /** The value's (or today's). */
  static AtValue = Month.of('at-value')
  /** One the user paged to: `center`. */
  static Paged = Month.of('paged')
}

/** Where a range stands while it's chosen. */
export class Ends extends State {
  declare private readonly brand: never
  static SelectingStart = Ends.of('selecting-start')
  /** The start is chosen (`pending`); the next day ends the range. */
  static SelectingEnd = Ends.of('selecting-end')
}

export class Popup extends State<Month | Ends> {
  declare private readonly brand: never
  static Closed = Popup.of('closed')
  static Open = Popup.of('open', { regions: { month: Month, ends: Ends } })
}

/** Whether the input holds text typed since the value was last written there. */
export class Input extends State {
  declare private readonly brand: never
  static Clean = Input.of('clean')
  static Dirty = Input.of('dirty')
}

/** What closed the calendar, which decides where focus goes. */
export type CloseReason = 'choice' | 'escape' | 'outside'

/** What the chart reads and writes on its picker. Parsing and formatting stay there. */
export interface ChartHost {
  readonly inputMode: boolean
  /** Whether typed text names a value. */
  parses(text: string): boolean
  /** Takes the value typed text names; returns whether it named one. */
  readTyped(text: string): boolean
  clear(): void
}

/**
 * A picker's modes: whether the calendar is open (and on which month, and halfway through a
 * range), and whether its input is dirty. Open and Closed follow the picker's `ControllableState`
 * once it has committed, never the request, so a close a controlled `@open` refuses forgets nothing.
 */
export class PickerChart extends Machine<{ popup: Popup; input: Input }> {
  @region(Popup) declare popup: Popup
  @region(Input) declare input: Input

  readonly host: ChartHost
  /** The month shown, while `Paged`. */
  @tracked center: Date | undefined
  /** The start chosen, while `SelectingEnd`. */
  @tracked pending: DateRange | undefined
  /** What was typed, while `Dirty`. */
  @tracked typed: string | null = null
  /** Set just before a close is asked for; read as the calendar closes. */
  closeReason: CloseReason = 'outside'
  /** Whether focus goes back to the input once the calendar has closed. */
  focusInput = false

  constructor(host: ChartHost) {
    super()
    this.host = host
  }

  get isBlank(): boolean {
    return !this.typed?.trim()
  }

  get parses(): boolean {
    return this.host.parses(this.typed ?? '')
  }

  @transition({ from: Popup.Closed, to: Popup.Open })
  opened() {}

  @transition({ from: Popup.Open, to: Popup.Closed })
  closed() {}

  @onExit(Popup.Open)
  forget() {
    this.center = undefined
    this.pending = undefined
    // A choice and Escape send focus back to the input it was typed into.
    this.focusInput = this.host.inputMode && this.closeReason !== 'outside'
    this.closeReason = 'outside'
  }

  @transition({ from: Month.AtValue, to: Month.Paged })
  @transition({ from: Month.Paged, to: Month.Paged })
  page(center: Date) {
    this.center = center
  }

  @transition({ from: Month.Paged, to: Month.AtValue })
  toValue() {
    this.center = undefined
  }

  @transition({ from: Ends.SelectingStart, to: Ends.SelectingEnd })
  @transition({ from: Ends.SelectingEnd, to: Ends.SelectingEnd })
  startRange(range: DateRange) {
    this.pending = range
  }

  @transition({ from: Ends.SelectingEnd, to: Ends.SelectingStart })
  @transition({ from: Ends.SelectingStart })
  endRange() {
    this.pending = undefined
  }

  @transition({ from: Input.Clean, to: Input.Dirty })
  @transition({ from: Input.Dirty, to: Input.Dirty })
  type(text: string) {
    this.typed = text
    if (this.host.readTyped(text) && this.matches(Month.Paged)) this.toValue()
  }

  /** Blank text clears the value, text that names one takes it; other text stays to be fixed. */
  @transition({ from: Input.Dirty, to: Input.Clean, guard: (m: PickerChart) => m.isBlank })
  @transition({ from: Input.Dirty, to: Input.Clean, guard: (m: PickerChart) => m.parses })
  @transition({ from: Input.Dirty })
  @transition({ from: Input.Clean })
  blur() {
    if (this.typed === null) return
    if (this.isBlank) this.host.clear()
    else this.host.readTyped(this.typed)
  }

  /** The value was written into the input (a day was chosen). */
  @transition({ from: Input.Dirty, to: Input.Clean })
  @transition({ from: Input.Clean })
  written() {}

  @onEntry(Input.Clean)
  cleaned() {
    this.typed = null
  }
}

/** A started `PickerChart`, stopped when `owner` is destroyed. */
export function pickerChart(owner: object, host: ChartHost): PickerChart {
  return machine(owner, new PickerChart(host))
}
