import { FieldHarness } from '@ember-formwright/test-support'
import { DatePickerHarness, type CalendarDayInput } from '@ember-joinery/test-support'

/**
 * A `date-picker` field, a Popover with a Calendar: `text` (what its button shows), `pick(day)`.
 *
 *   await form.dob.pick('2026-11-10')
 *   assert.strictEqual(form.dob.text, 'November 10, 2026')
 */
export class DatePickerFieldHarness extends FieldHarness {
  static override controls = ['date-picker']

  /** Joinery's `DatePickerHarness` for the field's Popover and its Calendar. */
  get datePicker(): DatePickerHarness {
    return new DatePickerHarness({ within: this.element })
  }

  /** What the button shows: the date, or the placeholder while there is none. */
  get text(): string {
    return this.datePicker.text
  }

  /** Whether no date is picked (`data-empty`). */
  get isEmpty(): boolean {
    return this.control.getAttribute('data-empty') === 'true'
  }

  /** Opens the popover, goes to the day's month and picks the day. */
  async pick(day: CalendarDayInput): Promise<void> {
    await this.datePicker.pick(day)
  }
}
