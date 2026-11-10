import { blur, click, fillIn, focus } from '@ember/test-helpers'
import { Harness, pressEscape, pressKey } from '@ember-joinery/test-support'
import { PowerCalendarHarness } from './power-calendar.ts'

function textOf(element: Element | null | undefined): string {
  return (element?.textContent ?? '').replace(/\s+/g, ' ').trim()
}

/** The text of the elements an `aria-labelledby` or `aria-describedby` names, joined. */
function referenced(element: Element, attribute: string): string | undefined {
  const ids = element.getAttribute(attribute)
  if (!ids) return undefined
  return ids
    .split(/\s+/)
    .map(id => element.ownerDocument.getElementById(id))
    .filter((found): found is HTMLElement => Boolean(found))
    .map(textOf)
    .join(' ')
}

/** A control's accessible name: `aria-labelledby`, else `aria-label`, else its labels, else its text. */
function nameOf(control: HTMLButtonElement | HTMLInputElement): string {
  const labelledBy = referenced(control, 'aria-labelledby')
  if (labelledBy) return labelledBy
  const label = control.getAttribute('aria-label')?.trim()
  if (label) return label
  const labels = [...(control.labels ?? [])].map(textOf).filter(Boolean)
  if (labels.length) return labels.join(' ')
  return control instanceof HTMLInputElement
    ? (control.getAttribute('placeholder') ?? '')
    : textOf(control)
}

/**
 * Drives a `DatePicker` or `DateRangePicker` from `@ember-joinery/power-calendar`, with a button
 * or an input for its trigger: it opens the calendar, pages to the month and presses the day,
 * as a user does. Days are `YYYY-MM-DD` strings.
 *
 *   const checkIn = new DatePickerHarness('check-in') // <DatePicker @name="check-in">
 *   await checkIn.select('2026-03-04')
 *   assert.strictEqual(checkIn.text, 'March 4, 2026')
 *   await new DatePickerHarness('stay').selectRange('2026-03-04', '2026-03-09')
 *
 * The open calendar is `calendar`, a `PowerCalendarHarness`.
 */
export class DatePickerHarness extends Harness {
  static override component = ['date-picker', 'date-range-picker']

  /** Whether it picks a range. */
  get isRange(): boolean {
    return this.element.getAttribute('data-test-jn') === 'date-range-picker'
  }

  /** The input a date can be typed into, with `@trigger="input"`; else `null`. */
  get input(): HTMLInputElement | null {
    return this.element.querySelector<HTMLInputElement>('input[data-test-jn-part="input"]')
  }

  /** What opens the calendar: the button, or the calendar button beside the input. */
  get trigger(): HTMLButtonElement {
    if (!this.input) return this.element as HTMLButtonElement
    const trigger = this.element.querySelector<HTMLButtonElement>('[data-test-jn-part="trigger"]')
    if (!trigger) throw new Error(`Joinery harness: ${this} has no calendar button`)
    return trigger
  }

  /** What it shows: the date (or range) as written, or the placeholder while there is none. */
  get text(): string {
    const input = this.input
    if (input) return input.value
    return textOf(this.element.querySelector('[data-test-jn-part="value"]'))
  }

  /** Whether no date is chosen (the button's `data-empty`, or an empty input). */
  get isEmpty(): boolean {
    const input = this.input
    if (input) return input.value === ''
    return this.element.getAttribute('data-empty') === 'true'
  }

  /** What shows with no date. */
  get placeholder(): string {
    const input = this.input
    if (input) return input.placeholder
    return this.isEmpty ? this.text : ''
  }

  /**
   * The accessible name of what a `<label for>` names: the button (its label, then its value)
   * or the input.
   */
  get label(): string {
    return nameOf(this.input ?? this.trigger)
  }

  /** The calendar button's name, with an input trigger. */
  get triggerLabel(): string {
    return nameOf(this.trigger)
  }

  /** Whether it is disabled. */
  get isDisabled(): boolean {
    return this.trigger.disabled
  }

  /** Whether it is marked invalid (`aria-invalid`). */
  get isInvalid(): boolean {
    const invalid = (this.input ?? this.trigger).getAttribute('aria-invalid')
    return invalid !== null && invalid !== 'false'
  }

  /** Whether the calendar is open, from the trigger's `aria-expanded`. */
  get isOpen(): boolean {
    return this.trigger.getAttribute('aria-expanded') === 'true'
  }

  /** The popover the calendar is in, while it is open; else `null`. */
  get content(): HTMLElement | null {
    const id = this.trigger.getAttribute('aria-controls')
    return id ? document.getElementById(id) : null
  }

  /** The open calendar. Throws while it is closed. */
  get calendar(): PowerCalendarHarness {
    const content = this.content
    if (!content) throw new Error(`Joinery harness: the calendar of ${this} is not open`)
    return new PowerCalendarHarness({ within: content })
  }

  /** Opens the calendar with a press on the trigger, unless it is open. */
  async open(): Promise<void> {
    if (!this.isOpen) await click(this.trigger)
  }

  /** Closes the calendar with Escape, as a keyboard user does, unless it is closed. */
  async close(): Promise<void> {
    if (this.isOpen) await pressEscape()
  }

  /** Opens the calendar, pages to the day's month and presses it. */
  async select(date: string): Promise<void> {
    await this.open()
    await this.calendar.select(date)
  }

  /** Opens the calendar and presses a range's two ends. */
  async selectRange(from: string, to: string): Promise<void> {
    await this.open()
    await this.calendar.select(from)
    await this.calendar.select(to)
  }

  /** Types text into the input, as a user does (a change for each), then leaves it. */
  async typeDate(text: string): Promise<void> {
    const input = this.input
    if (!input) throw new Error(`Joinery harness: ${this} has no input to type into`)
    await focus(input)
    await fillIn(input, text)
    await blur(input)
  }

  /** Presses a key on the input (ArrowDown opens the calendar). */
  async pressKeyInInput(key: string): Promise<boolean> {
    const input = this.input
    if (!input) throw new Error(`Joinery harness: ${this} has no input`)
    await focus(input)
    return pressKey(key)
  }
}
