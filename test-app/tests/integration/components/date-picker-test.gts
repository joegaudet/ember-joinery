import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { click, focus, render, rerender, settled } from '@ember/test-helpers'
import { tracked } from '@glimmer/tracking'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import { Field, FieldDescription, FieldLabel } from '@ember-joinery/ember'
import { isInTopLayer, pressEscape, pressOutside } from '@ember-joinery/test-support'
import {
  DatePicker,
  DateRangePicker,
  toIsoDate,
  type DateRange,
} from '@ember-joinery/power-calendar'
import { DatePickerHarness } from '@ember-joinery/power-calendar/test-support'

class State {
  @tracked date: Date | undefined = undefined
  @tracked range: DateRange | undefined = undefined
  @tracked open = false
  sent: unknown[] = []
  record = (value: unknown) => {
    this.sent.push(value)
  }
  keep = (date: Date | undefined) => {
    this.sent.push(date)
    this.date = date
  }
  keepRange = (range: DateRange | undefined) => {
    this.sent.push(range)
    this.range = range
  }
  setOpen = (open: boolean) => {
    this.sent.push(open)
    this.open = open
  }
}

const iso = (value: unknown) => (value instanceof Date ? toIsoDate(value) : value)
const isoRange = (range: unknown) => {
  if (!range) return range
  const { from, to } = range as DateRange
  return { from: iso(from), to: iso(to) }
}

const MARCH_4 = new Date(2026, 2, 4)

module('Integration | components | date-picker', function (hooks) {
  setupRenderingTest(hooks)

  test('it renders an outlined Button showing the date, or the placeholder', async function (assert) {
    await render(
      <template>
        <DatePicker @name="empty" class="custom" style="width: 212px" />
        <DatePicker @name="chosen" @defaultValue={{MARCH_4}} @locale="en-US" />
      </template>,
    )
    const empty = new DatePickerHarness('empty')
    assert
      .dom(empty.element)
      .hasTagName('button')
      .hasAttribute('type', 'button')
      .hasClass('jn-button')
      .hasClass('jn-button-variant-outline')
      .hasClass('jn-date-picker-trigger')
      .hasClass('custom', '...attributes adds a class')
      .hasAttribute('data-slot', 'date-picker')
      .hasAttribute('data-test-jn', 'date-picker')
      .hasAttribute('data-test-jn-name', 'empty')
      .hasAttribute('data-empty', 'true')
      .hasAttribute('aria-haspopup', 'dialog')
      .hasAttribute('aria-expanded', 'false')
    assert.strictEqual(empty.text, 'Pick a date')
    assert.true(empty.isEmpty)
    assert.strictEqual(empty.placeholder, 'Pick a date')
    assert.false(empty.isRange)
    assert.dom('svg', empty.element).hasAttribute('data-icon', 'inline-end')
    assert.strictEqual(empty.element.offsetWidth, 212, "a caller's class sizes it")

    const chosen = new DatePickerHarness('chosen')
    assert.strictEqual(chosen.text, 'March 4, 2026')
    assert.false(chosen.isEmpty)
    assert.dom(chosen.element).hasAttribute('data-empty', 'false')
    assert.notEqual(
      getComputedStyle(empty.element).color,
      getComputedStyle(chosen.element).color,
      'the placeholder is muted (data-[empty=true]:text-muted-foreground)',
    )
    await a11yAudit()
  })

  test('it opens the calendar in a Popover, focused on the chosen day, and a choice closes it', async function (assert) {
    const state = new State()
    await render(
      <template>
        <DatePicker
          @name="due"
          @defaultValue={{MARCH_4}}
          @onValueChange={{state.record}}
          @locale="en-US"
        />
      </template>,
    )
    const due = new DatePickerHarness('due')
    await due.open()
    assert.true(due.isOpen)
    const content = due.content!
    assert.true(isInTopLayer(content), 'the calendar is in the top layer')
    assert.dom(content).hasClass('jn-popover-content').hasClass('jn-date-picker-content')
    assert.dom(content).hasAttribute('role', 'dialog')
    assert.strictEqual(getComputedStyle(content).paddingTop, '0px', "upstream's p-0")
    assert.strictEqual(due.calendar.month, 'March 2026')
    assert.strictEqual(due.calendar.focusedDay, '2026-03-04', 'focus is on the chosen day')
    assert.dom(content.querySelector('.jn-power-calendar')).exists()
    assert.strictEqual(
      getComputedStyle(content.querySelector('.jn-power-calendar')!).backgroundColor,
      'rgba(0, 0, 0, 0)',
      "in a popover, the calendar's background is transparent",
    )

    await due.calendar.select('2026-03-18')
    assert.false(due.isOpen, 'a choice closes it')
    assert.strictEqual(due.text, 'March 18, 2026')
    assert.deepEqual(state.sent.map(iso), ['2026-03-18'])
    assert.dom(due.trigger).isFocused('focus goes back to the trigger')
    await a11yAudit()
  })

  test('with no date, focus goes to today; Escape and a press outside close it unchanged', async function (assert) {
    const state = new State()
    await render(
      <template>
        <button type="button">Elsewhere</button>
        <DatePicker @name="due" @onValueChange={{state.record}} />
      </template>,
    )
    const due = new DatePickerHarness('due')
    await due.open()
    assert.strictEqual(due.calendar.focusedDay, toIsoDate(new Date()))
    await due.calendar.nextMonth()
    await pressEscape()
    assert.false(due.isOpen)
    assert.dom(due.trigger).isFocused()

    await due.open()
    assert.strictEqual(
      due.calendar.shownMonth,
      toIsoDate(new Date()).slice(0, 7),
      'it opens on the month again, not the one paged to',
    )
    await pressOutside()
    assert.false(due.isOpen)
    assert.deepEqual(state.sent, [], 'nothing was chosen')
    await a11yAudit()
  })

  test('controlled: @value and @open', async function (assert) {
    const state = new State()
    state.date = MARCH_4
    await render(
      <template>
        <DatePicker
          @name="due"
          @value={{state.date}}
          @onValueChange={{state.record}}
          @open={{state.open}}
          @onOpenChange={{state.setOpen}}
          @locale="en-US"
        />
      </template>,
    )
    const due = new DatePickerHarness('due')
    await due.open()
    assert.true(due.isOpen)
    await due.calendar.select('2026-03-09')
    assert.deepEqual(state.sent.map(iso), [true, '2026-03-09', false])
    assert.strictEqual(due.text, 'March 4, 2026', 'it waits for @value')
    state.date = new Date(2026, 2, 9)
    await rerender()
    assert.strictEqual(due.text, 'March 9, 2026')
    await a11yAudit()
  })

  test('in a Field, the label names the button, then the value it shows', async function (assert) {
    await render(
      <template>
        <Field>
          <FieldLabel for="check-in">Check-in</FieldLabel>
          <DatePicker
            @name="check-in"
            @id="check-in"
            @defaultValue={{MARCH_4}}
            @describedBy="check-in-hint"
            @locale="en-US"
          />
          <FieldDescription id="check-in-hint">The first night</FieldDescription>
        </Field>
      </template>,
    )
    const checkIn = new DatePickerHarness('check-in')
    assert.dom(checkIn.trigger).hasAttribute('id', 'check-in')
    assert.strictEqual(checkIn.label, 'Check-in March 4, 2026')
    assert.dom(checkIn.trigger).hasAttribute('aria-describedby', 'check-in-hint')
    await click('label')
    assert.true(checkIn.isOpen, 'a press on the label presses the button')
    await a11yAudit()
  })

  test('@format, @locale, @placeholder, @icon and @iconPosition', async function (assert) {
    const full: Intl.DateTimeFormatOptions = { dateStyle: 'full' }
    await render(
      <template>
        <DatePicker
          @name="full"
          @defaultValue={{MARCH_4}}
          @format={{full}}
          @locale="en-US"
          @iconPosition="inline-start"
        />
        <DatePicker @name="fr" @defaultValue={{MARCH_4}} @locale="fr-FR" />
        <DatePicker @name="plain" @placeholder="Choisir une date" @icon={{null}} />
      </template>,
    )
    const fullDate = new DatePickerHarness('full')
    assert.strictEqual(fullDate.text, 'Wednesday, March 4, 2026')
    assert.dom('svg', fullDate.element).hasAttribute('data-icon', 'inline-start')
    assert.strictEqual(new DatePickerHarness('fr').text, '4 mars 2026')
    const plain = new DatePickerHarness('plain')
    assert.strictEqual(plain.text, 'Choisir une date')
    assert.dom('svg', plain.element).doesNotExist()
    await new DatePickerHarness('fr').open()
    assert.strictEqual(new DatePickerHarness('fr').calendar.month, 'mars 2026')
    await a11yAudit()
  })

  test('@disabled, @invalid and the calendar options', async function (assert) {
    const weekend = ['Sat', 'Sun']
    await render(
      <template>
        <DatePicker @name="off" @disabled={{true}} />
        <DatePicker
          @name="limited"
          @invalid={{true}}
          @defaultValue={{MARCH_4}}
          @minDate="2026-03-02"
          @maxDate="2026-03-27"
          @disabledDates={{weekend}}
          @label="Ship date"
        />
      </template>,
    )
    const off = new DatePickerHarness('off')
    assert.true(off.isDisabled)
    await click(off.trigger).catch(() => {})
    assert.false(off.isOpen)

    const limited = new DatePickerHarness('limited')
    assert.true(limited.isInvalid)
    await limited.open()
    assert.strictEqual(limited.calendar.label, 'Ship date')
    assert.true(limited.calendar.isDayDisabled('2026-03-01'))
    assert.true(limited.calendar.isDayDisabled('2026-03-07'))
    assert.true(limited.calendar.isDayDisabled('2026-03-30'))
    assert.false(limited.calendar.isDayDisabled('2026-03-27'))
    assert.true(limited.calendar.isPreviousDisabled)
    assert.true(limited.calendar.isNextDisabled)
    await a11yAudit()
  })

  module('with an input', function () {
    test('it renders an Input Group: the input, then a calendar button at its end', async function (assert) {
      const date = new Date(2025, 5, 1)
      const format: Intl.DateTimeFormatOptions = { day: '2-digit', month: 'long', year: 'numeric' }
      await render(
        <template>
          <Field class="mx-auto w-48">
            <FieldLabel for="date-required">Subscription Date</FieldLabel>
            <DatePicker
              @name="subscription"
              @trigger="input"
              @id="date-required"
              @defaultValue={{date}}
              @format={{format}}
              @locale="en-US"
              @placeholder="June 01, 2025"
            />
          </Field>
        </template>,
      )
      const subscription = new DatePickerHarness('subscription')
      assert
        .dom(subscription.element)
        .hasClass('jn-input-group')
        .hasAttribute('role', 'group')
        .hasAttribute('data-test-jn', 'date-picker')
      const input = subscription.input!
      assert.dom(input).hasAttribute('id', 'date-required').hasClass('jn-input-group-input')
      assert.strictEqual(subscription.text, 'June 01, 2025')
      assert.strictEqual(subscription.label, 'Subscription Date')
      assert.strictEqual(subscription.placeholder, 'June 01, 2025')
      assert.strictEqual(subscription.triggerLabel, 'Select date')
      assert.dom(subscription.trigger).hasClass('jn-input-group-button')
      assert.true(
        subscription.trigger.getBoundingClientRect().left > input.getBoundingClientRect().left,
        'the button is at the inline end',
      )
      await a11yAudit()
    })

    test('typing a date chooses it; ArrowDown opens the calendar; a choice fills the input', async function (assert) {
      const state = new State()
      await render(
        <template>
          <DatePicker
            @name="due"
            @trigger="input"
            @value={{state.date}}
            @onValueChange={{state.keep}}
            @locale="en-US"
          />
        </template>,
      )
      const due = new DatePickerHarness('due')
      await due.typeDate('June 1, 2025')
      assert.strictEqual(iso(state.date), '2025-06-01')
      assert.strictEqual(due.text, 'June 1, 2025', 'left, the input shows the date as written')

      await due.typeDate('next week')
      assert.strictEqual(iso(state.date), '2025-06-01', "text that names no day doesn't change it")
      assert.strictEqual(due.text, 'next week', 'and stays as typed')

      assert.true(await due.pressKeyInInput('ArrowDown'), 'ArrowDown is taken')
      assert.true(due.isOpen)
      assert.strictEqual(due.calendar.month, 'June 2025')
      await due.calendar.select('2025-06-12')
      assert.false(due.isOpen)
      assert.strictEqual(due.text, 'June 12, 2025')
      assert.dom(due.input).isFocused('focus goes back to the input')

      await due.typeDate('')
      assert.strictEqual(state.date, undefined, 'emptied, it is cleared')
      await a11yAudit()
    })

    test('the calendar button opens it; Escape sends focus back to the input', async function (assert) {
      await render(
        <template><DatePicker @name="due" @trigger="input" @defaultValue={{MARCH_4}} /></template>,
      )
      const due = new DatePickerHarness('due')
      await due.open()
      assert.true(due.isOpen)
      assert.strictEqual(due.calendar.focusedDay, '2026-03-04')
      await pressEscape()
      assert.false(due.isOpen)
      assert.dom(due.input).isFocused()
      await a11yAudit()
    })
  })

  test('right to left, it lays out and moves as the calendar does', async function (assert) {
    await render(
      <template>
        <DirectionProvider @dir="rtl">
          <DatePicker @name="due" @defaultValue={{MARCH_4}} @locale="ar" style="width: 212px" />
        </DirectionProvider>
      </template>,
    )
    const due = new DatePickerHarness('due')
    const button = due.trigger.getBoundingClientRect()
    const icon = due.trigger.querySelector('svg')!.getBoundingClientRect()
    assert.true(
      icon.left < button.left + button.width / 2,
      'the chevron is at the inline end, the left',
    )
    await due.open()
    await focus(due.calendar.day('2026-03-04')!)
    await due.calendar.pressKey('ArrowLeft')
    assert.strictEqual(due.calendar.focusedDay, '2026-03-05')
    await settled()
    await a11yAudit()
  })

  module('DateRangePicker', function () {
    test('two presses choose the range; only then does it change and close', async function (assert) {
      const state = new State()
      state.range = { from: new Date(2026, 0, 20), to: new Date(2026, 1, 9) }
      await render(
        <template>
          <DateRangePicker
            @name="stay"
            @value={{state.range}}
            @onValueChange={{state.keepRange}}
            @locale="en-US"
          />
        </template>,
      )
      const stay = new DatePickerHarness('stay')
      assert.true(stay.isRange)
      assert.dom(stay.element).hasAttribute('data-test-jn', 'date-range-picker')
      assert.strictEqual(stay.text, 'Jan 20 – Feb 9, 2026')
      assert.dom('svg', stay.element).hasAttribute('data-icon', 'inline-start')

      await stay.open()
      assert.strictEqual(stay.calendar.kind, 'range')
      assert.strictEqual(stay.calendar.month, 'January 2026')
      await stay.calendar.select('2026-01-05')
      assert.true(stay.isOpen, 'one end: still open')
      assert.deepEqual(state.sent, [], 'and nothing sent')
      assert.deepEqual(stay.calendar.selected, ['2026-01-05'])
      await stay.calendar.select('2026-01-08')
      assert.false(stay.isOpen)
      assert.deepEqual(state.sent.map(isoRange), [{ from: '2026-01-05', to: '2026-01-08' }])
      assert.strictEqual(stay.text, 'Jan 5 – 8, 2026')
      assert.dom(stay.trigger).isFocused()
      await a11yAudit()
    })

    test('closing it halfway keeps the range there was', async function (assert) {
      const range = { from: new Date(2026, 2, 4), to: new Date(2026, 2, 9) }
      await render(
        <template>
          <DateRangePicker @name="stay" @defaultValue={{range}} @locale="en-US" />
        </template>,
      )
      const stay = new DatePickerHarness('stay')
      await stay.open()
      await stay.calendar.select('2026-03-20')
      await stay.close()
      assert.strictEqual(stay.text, 'Mar 4 – 9, 2026')
      await stay.open()
      assert.deepEqual(stay.calendar.selected.length, 6, 'it opens on the range there is')
      await stay.close()

      await stay.selectRange('2026-03-12', '2026-03-10')
      assert.strictEqual(stay.text, 'Mar 10 – 12, 2026', 'the ends are put in order')
      await a11yAudit()
    })

    test('with an input, both dates can be typed', async function (assert) {
      const state = new State()
      await render(
        <template>
          <DateRangePicker
            @name="stay"
            @trigger="input"
            @value={{state.range}}
            @onValueChange={{state.keepRange}}
            @locale="en-US"
          />
        </template>,
      )
      const stay = new DatePickerHarness('stay')
      assert.strictEqual(stay.triggerLabel, 'Select dates')
      assert.strictEqual(stay.placeholder, 'Pick a date')
      await stay.typeDate('Mar 9, 2026 - Mar 4, 2026')
      assert.deepEqual(isoRange(state.range), { from: '2026-03-04', to: '2026-03-09' })
      assert.strictEqual(stay.text, 'Mar 4, 2026 – Mar 9, 2026', 'written back in full')

      await stay.selectRange('2026-03-15', '2026-03-17')
      assert.strictEqual(stay.text, 'Mar 15, 2026 – Mar 17, 2026')
      assert.dom(stay.input).isFocused()
      await stay.typeDate('')
      assert.strictEqual(state.range, undefined)
      await a11yAudit()
    })
  })
})
