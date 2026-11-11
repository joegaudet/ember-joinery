import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { click, render, settled } from '@ember/test-helpers'
import { tracked } from '@glimmer/tracking'
import { on } from '@ember/modifier'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import { isoDate, parseIsoDate, type DateRange } from '@ember-joinery/primitives/calendar'
import { Button, Calendar, Field, FieldLabel, InputGroup, Popover } from '@ember-joinery/ember'
import {
  DatePickerHarness,
  InputGroupHarness,
  PopoverHarness,
  pressKey,
  tab,
} from '@ember-joinery/test-support'

const day = parseIsoDate
// Thursday 15 January 2026; the month's grid runs from Sunday 28 December to Saturday 31 January.
const TODAY = day('2026-01-15')

const LONG = new Intl.DateTimeFormat('en-US', { dateStyle: 'long' })
const SHORT = new Intl.DateTimeFormat('en-US', { month: 'short', day: '2-digit', year: 'numeric' })

/** `January 20, 2026`. */
const long = (date: Date) => LONG.format(date)
/** `Jan 20, 2026`, as date-fns' `LLL dd, y`. */
const short = (date: Date) => SHORT.format(date)

/** A picker's state: its date, its range, and whether it is open, as an example keeps them. */
class State {
  @tracked date: Date | undefined
  @tracked range: DateRange | undefined
  @tracked open = false
  @tracked text = ''

  setDate = (date: Date | undefined) => (this.date = date)
  setRange = (range: DateRange | undefined) => (this.range = range)
  setOpen = (open: boolean) => (this.open = open)
  setText = (text: string) => (this.text = text)
  /** As the date of birth example does: keep the day and close the popover. */
  pickAndClose = (date: Date | undefined) => {
    this.date = date
    this.open = false
  }
  /** As the input example does: keep the day, write it in the input, and close. */
  pickIntoInput = (date: Date | undefined) => {
    this.date = date
    this.text = date ? long(date) : ''
    this.open = false
  }
  openOnArrowDown = (event: KeyboardEvent) => {
    if (event.key === 'ArrowDown') {
      event.preventDefault()
      this.open = true
    }
  }
}

function focused(): Element | null {
  return document.activeElement
}

module('Integration | components | date picker', function (hooks) {
  setupRenderingTest(hooks)

  test('a Popover whose content holds a Calendar: the trigger shows the date, or a placeholder', async function (assert) {
    const state = new State()
    await render(
      <template>
        <Popover @name="due" as |p|>
          <Button
            @variant="outline"
            data-empty={{if state.date "false" "true"}}
            class="w-[212px] justify-between"
            {{p.trigger}}
          >
            {{#if state.date}}{{long state.date}}{{else}}<span>Pick a date</span>{{/if}}
          </Button>
          <p.Content class="w-auto p-0" @align="start">
            <Calendar
              @mode="single"
              @value={{state.date}}
              @onValueChange={{state.setDate}}
              @defaultMonth={{state.date}}
              @today={{TODAY}}
            />
          </p.Content>
        </Popover>
      </template>,
    )
    const picker = new DatePickerHarness('due')
    assert.strictEqual(picker.text, 'Pick a date')
    assert.dom(picker.trigger).hasAttribute('data-empty', 'true')
    assert.false(picker.isOpen)
    assert.false(picker.calendar.exists, 'the calendar renders only while it is open')
    await a11yAudit()

    await picker.open()
    assert.true(picker.isShown, 'the content is in the top layer')
    assert.true(picker.calendar.exists)
    assert.strictEqual(picker.calendar.caption, 'January 2026', "today's month, with no date")
    assert.strictEqual(picker.label, 'Pick a date', 'the trigger names the dialog')
    assert.strictEqual(picker.align, 'start')
    assert.dom(picker.content).hasAttribute('role', 'dialog')

    await picker.pick('2026-01-20')
    assert.strictEqual(picker.text, 'January 20, 2026')
    assert.dom(picker.trigger).hasAttribute('data-empty', 'false')
    assert.strictEqual(state.date && isoDate(state.date), '2026-01-20')
    assert.true(picker.isOpen, 'an uncontrolled popover stays open, as upstream’s demo does')
    assert.deepEqual(picker.calendar.selectedDays, ['2026-01-20'])
    await a11yAudit()

    await picker.pressEscape()
    assert.false(picker.isOpen)
    assert.dom(picker.trigger).isFocused('focus is back on the trigger')
    await picker.open()
    assert.strictEqual(picker.calendar.caption, 'January 2026')
    assert.true(picker.calendar.isSelected('2026-01-20'), 'it opens on the date picked')
    await a11yAudit()
  })

  test('closing on a pick: a controlled popover closes and gives focus back to the trigger', async function (assert) {
    const state = new State()
    state.date = day('1990-07-14')
    await render(
      <template>
        <Field class="w-44">
          <FieldLabel for="dob">Date of birth</FieldLabel>
          <Popover @open={{state.open}} @onOpenChange={{state.setOpen}} @name="dob" as |p|>
            <Button @variant="outline" id="dob" class="justify-start" {{p.trigger}}>
              {{if state.date (long state.date) "Select date"}}
            </Button>
            <p.Content class="w-auto overflow-hidden p-0" @align="start">
              <Calendar
                @mode="single"
                @value={{state.date}}
                @defaultMonth={{state.date}}
                @captionLayout="dropdown"
                @onValueChange={{state.pickAndClose}}
                @today={{TODAY}}
              />
            </p.Content>
          </Popover>
        </Field>
      </template>,
    )
    const picker = new DatePickerHarness('dob')
    assert.strictEqual(picker.text, 'July 14, 1990')

    await picker.open()
    assert.true(state.open, 'the trigger asks to open')
    assert.deepEqual(picker.calendar.months, ['1990-07-01'], 'it opens on the month of the date')
    assert.strictEqual(picker.calendar.monthDropdown()?.value, '6')
    assert.strictEqual(picker.calendar.yearDropdown()?.value, '1990')
    await a11yAudit()

    await picker.pick('1985-03-02')
    assert.false(picker.isOpen, 'a pick closes it')
    assert.false(state.open)
    assert.strictEqual(picker.text, 'March 2, 1985')
    assert.dom(picker.trigger).isFocused('focus goes back to the trigger')

    state.open = true
    await settled()
    assert.true(picker.isOpen, 'it opens when @open says so')
    assert.true(picker.calendar.isSelected('1985-03-02'))
    await picker.pressOutside()
    assert.false(state.open, 'a press outside asks to close')
    assert.false(picker.isOpen)
    await a11yAudit()
  })

  test("keyboard: the APG date picker dialog's keys", async function (assert) {
    const state = new State()
    state.date = day('2026-01-20')
    await render(
      <template>
        <Popover @open={{state.open}} @onOpenChange={{state.setOpen}} @name="kb" as |p|>
          <Button @variant="outline" {{p.trigger}}>
            {{if state.date (long state.date) "Select date"}}
          </Button>
          <p.Content class="w-auto p-0" @align="start">
            <Calendar
              @mode="single"
              @value={{state.date}}
              @defaultMonth={{state.date}}
              @onValueChange={{state.pickAndClose}}
              @today={{TODAY}}
            />
          </p.Content>
        </Popover>
      </template>,
    )
    const picker = new DatePickerHarness('kb')
    // Enter or Space on the trigger, a button, is a click.
    await click(picker.trigger)
    assert.true(picker.isOpen)
    const calendar = picker.calendar
    assert
      .dom(calendar.previousButton)
      .isFocused('focus moves to the first thing in it, as Radix’s')

    await tab()
    assert.dom(calendar.nextButton).isFocused()
    await tab()
    assert.strictEqual(calendar.focusedDay, '2026-01-20', 'Tab reaches the selected day')
    await pressKey('ArrowRight')
    assert.strictEqual(calendar.focusedDay, '2026-01-21')
    await pressKey('ArrowDown')
    assert.strictEqual(calendar.focusedDay, '2026-01-28')
    await pressKey('PageDown')
    assert.strictEqual(calendar.focusedDay, '2026-02-28', 'the next month, shown')
    assert.strictEqual(calendar.caption, 'February 2026')
    await pressKey('Home')
    assert.strictEqual(calendar.focusedDay, '2026-02-22', 'the start of the week')
    await tab()
    assert.dom(calendar.previousButton).isFocused('Tab goes round inside the popover')
    await tab({ shift: true })
    assert.strictEqual(calendar.focusedDay, '2026-02-22')

    await click(focused()!) // Enter on the focused day: its button is pressed
    assert.false(picker.isOpen, 'the pick closes it')
    assert.strictEqual(picker.text, 'February 22, 2026')
    assert.dom(picker.trigger).isFocused('focus goes back to the trigger')

    await click(picker.trigger)
    await tab()
    await tab()
    assert.strictEqual(calendar.focusedDay, '2026-02-22', 'the selected day is the tab stop')
    await pressKey('ArrowLeft')
    await picker.pressEscape()
    assert.false(picker.isOpen, 'Escape closes it')
    assert.dom(picker.trigger).isFocused('and focus goes back to the trigger')
    assert.strictEqual(picker.text, 'February 22, 2026', 'moving focus picks nothing')
    await a11yAudit()
  })

  test('a range over two months: pickRange(), and the trigger shows both ends', async function (assert) {
    const state = new State()
    state.range = { from: day('2026-01-20'), to: day('2026-02-09') }
    await render(
      <template>
        <Popover @name="stay" as |p|>
          <Button @variant="outline" class="justify-start px-2.5" {{p.trigger}}>
            {{#if state.range.from}}
              {{#if state.range.to}}
                {{short state.range.from}}
                -
                {{short state.range.to}}
              {{else}}
                {{short state.range.from}}
              {{/if}}
            {{else}}
              <span>Pick a date</span>
            {{/if}}
          </Button>
          <p.Content class="w-auto p-0" @align="start">
            <Calendar
              @mode="range"
              @defaultMonth={{state.range.from}}
              @value={{state.range}}
              @onValueChange={{state.setRange}}
              @numberOfMonths={{2}}
              @today={{TODAY}}
            />
          </p.Content>
        </Popover>
      </template>,
    )
    const picker = new DatePickerHarness('stay')
    assert.strictEqual(picker.text, 'Jan 20, 2026 - Feb 09, 2026')

    await picker.open()
    assert.deepEqual(picker.calendar.captions, ['January 2026', 'February 2026'])
    assert.strictEqual(picker.calendar.rangePosition('2026-01-20'), 'start')
    assert.strictEqual(picker.calendar.rangePosition('2026-02-09'), 'end')
    assert.true(picker.shows('2026-02-09'), 'the second month counts as shown')
    assert.false(picker.shows('2026-03-01'), 'an outside day does not')

    await picker.pickRange('2026-03-02', '2026-04-10')
    assert.strictEqual(picker.text, 'Mar 02, 2026 - Apr 10, 2026', 'not Jan 20 - Apr 10')
    assert.deepEqual(picker.calendar.captions, ['March 2026', 'April 2026'])
    assert.strictEqual(picker.calendar.rangePosition('2026-03-02'), 'start')
    assert.strictEqual(picker.calendar.rangePosition('2026-04-10'), 'end')
    assert.true(picker.isOpen, 'the range example stays open')
    await a11yAudit()
  })

  test('pickRange() picks just that range, whatever range the calendar holds', async function (assert) {
    const state = new State()
    state.range = { from: day('2026-01-20'), to: day('2026-02-09') }
    await render(
      <template>
        <Popover @name="stay" as |p|>
          <Button @variant="outline" {{p.trigger}}>Stay</Button>
          <p.Content class="w-auto p-0" @align="start">
            <Calendar
              @mode="range"
              @defaultMonth={{state.range.from}}
              @value={{state.range}}
              @onValueChange={{state.setRange}}
              @numberOfMonths={{2}}
              @today={{TODAY}}
            />
          </p.Content>
        </Popover>
      </template>,
    )
    const picker = new DatePickerHarness('stay')
    const range = () => [state.range?.from, state.range?.to].map(date => date && isoDate(date))

    await picker.pickRange('2026-01-05', '2026-01-10')
    assert.deepEqual(range(), ['2026-01-05', '2026-01-10'], 'starting before the range')
    await picker.pickRange('2026-01-07', '2026-01-08')
    assert.deepEqual(range(), ['2026-01-07', '2026-01-08'], 'inside it')
    await picker.pickRange('2026-01-08', '2026-02-12')
    assert.deepEqual(range(), ['2026-01-08', '2026-02-12'], 'from its end')
    await picker.pickRange('2026-01-08', '2026-01-20')
    assert.deepEqual(range(), ['2026-01-08', '2026-01-20'], 'from its start, inside it')
    await picker.pickRange('2026-01-22', '2026-01-22')
    assert.deepEqual(range(), ['2026-01-22', '2026-01-22'], 'one day')
    await picker.pickRange('2026-01-22', '2026-01-24')
    assert.deepEqual(range(), ['2026-01-22', '2026-01-24'], 'from a one-day range')
    state.range = { from: day('2026-01-26'), to: undefined }
    await settled()
    await picker.pickRange('2026-01-12', '2026-01-14')
    assert.deepEqual(range(), ['2026-01-12', '2026-01-14'], 'from a range with no end yet')
    assert.deepEqual(picker.calendar.captions, ['January 2026', 'February 2026'])
    try {
      await picker.pickRange('2026-01-14', '2026-01-12')
      assert.ok(false, 'it should have thrown')
    } catch (error) {
      assert.true(String(error).includes('takes from (2026-01-14) before to (2026-01-12)'))
    }
    await a11yAudit()
  })

  test("pickRange() throws when the calendar won't take the range", async function (assert) {
    const state = new State()
    await render(
      <template>
        <Popover @name="nights" as |p|>
          <Button @variant="outline" {{p.trigger}}>Nights</Button>
          <p.Content class="w-auto p-0" @align="start">
            <Calendar
              @mode="range"
              @value={{state.range}}
              @onValueChange={{state.setRange}}
              @max={{5}}
              @today={{TODAY}}
            />
          </p.Content>
        </Popover>
      </template>,
    )
    const picker = new DatePickerHarness('nights')
    await picker.pickRange('2026-01-05', '2026-01-09')
    assert.deepEqual(
      [state.range?.from, state.range?.to].map(date => date && isoDate(date)),
      ['2026-01-05', '2026-01-09'],
    )
    try {
      await picker.pickRange('2026-01-12', '2026-01-25')
      assert.ok(false, 'it should have thrown')
    } catch (error) {
      assert.true(
        String(error).includes("calendar didn't end the range on 2026-01-25"),
        String(error),
      )
    }
    await a11yAudit()
  })

  test('showMonth() and pick() go to the month: by the buttons, by the dropdowns, and no further than the calendar goes', async function (assert) {
    const state = new State()
    await render(
      <template>
        <Popover @name="buttons" as |p|>
          <Button @variant="outline" {{p.trigger}}>Buttons</Button>
          <p.Content class="w-auto p-0">
            <Calendar
              @mode="single"
              @value={{state.date}}
              @onValueChange={{state.setDate}}
              @today={{TODAY}}
              @startMonth={{day "2025-11-01"}}
              @endMonth={{day "2026-04-30"}}
            />
          </p.Content>
        </Popover>
        <Popover @name="dropdowns" as |p|>
          <Button @variant="outline" {{p.trigger}}>Dropdowns</Button>
          <p.Content class="w-auto p-0">
            <Calendar
              @mode="single"
              @value={{state.date}}
              @onValueChange={{state.setDate}}
              @today={{TODAY}}
              @captionLayout="dropdown"
            />
          </p.Content>
        </Popover>
      </template>,
    )
    const buttons = new DatePickerHarness('buttons')
    await buttons.pick('2026-04-03')
    assert.strictEqual(buttons.calendar.caption, 'April 2026', 'three presses of next')
    assert.strictEqual(state.date && isoDate(state.date), '2026-04-03')
    await buttons.showMonth(day('2025-11-30'))
    assert.strictEqual(buttons.calendar.caption, 'November 2025', 'and back, for a Date')
    try {
      await buttons.showMonth('2025-10-31')
      assert.ok(false, 'it should have thrown')
    } catch (error) {
      assert.true(
        String(error).includes("calendar can't go to the month of 2025-10-31"),
        String(error),
      )
    }
    await buttons.close()

    const dropdowns = new DatePickerHarness('dropdowns')
    await dropdowns.pick('1936-02-29')
    assert.deepEqual(dropdowns.calendar.months, ['1936-02-01'], 'ninety years back, at once')
    assert.strictEqual(state.date && isoDate(state.date), '1936-02-29')
    assert.true(dropdowns.calendar.isSelected('1936-02-29'))
    await a11yAudit()
  })

  test('right to left: the popover opens at its start, and the arrow keys flip', async function (assert) {
    const state = new State()
    state.date = day('2026-01-20')
    await render(
      <template>
        <DirectionProvider @dir="rtl">
          <Popover @name="rtl" as |p|>
            <Button @variant="outline" {{p.trigger}}>اختر تاريخًا</Button>
            <p.Content class="w-auto p-0" @align="start">
              <Calendar
                @mode="single"
                @value={{state.date}}
                @onValueChange={{state.setDate}}
                @defaultMonth={{state.date}}
                @today={{TODAY}}
                @locale="ar-SA"
              />
            </p.Content>
          </Popover>
        </DirectionProvider>
      </template>,
    )
    const picker = new DatePickerHarness('rtl')
    await picker.open()
    const content = picker.content!
    for (const animation of content.getAnimations()) animation.finish()
    assert.strictEqual(picker.align, 'start')
    const edge = Math.abs(
      content.getBoundingClientRect().right - picker.trigger.getBoundingClientRect().right,
    )
    assert.true(edge <= 1, `its start, the right edge, meets the trigger's (${edge}px off)`)
    assert.strictEqual(getComputedStyle(content).direction, 'rtl')
    assert.strictEqual(picker.calendar.caption, 'يناير 2026', 'Arabic names, Latin digits')
    await picker.calendar.focus('2026-01-20')
    await pressKey('ArrowLeft')
    assert.strictEqual(picker.calendar.focusedDay, '2026-01-21', 'left is the next day')
    await pressKey('ArrowRight')
    await pressKey('ArrowRight')
    assert.strictEqual(picker.calendar.focusedDay, '2026-01-19')
    await picker.pick('2026-02-03')
    assert.strictEqual(state.date && isoDate(state.date), '2026-02-03')
    await a11yAudit()
  })

  test('beside an input: ArrowDown in the input opens it, and a pick writes the input', async function (assert) {
    const state = new State()
    state.text = 'January 20, 2026'
    state.date = day('2026-01-20')
    await render(
      <template>
        <InputGroup @name="subscription" as |g|>
          <g.Input
            aria-label="Subscription date"
            @value={{state.text}}
            @onValueChange={{state.setText}}
            {{on "keydown" state.openOnArrowDown}}
          />
          <g.Addon @align="inline-end">
            <Popover @open={{state.open}} @onOpenChange={{state.setOpen}} @name="input" as |p|>
              <g.Button @size="icon-xs" aria-label="Select date" {{p.trigger}} />
              <p.Content class="w-auto overflow-hidden p-0" @align="end">
                <Calendar
                  @mode="single"
                  @value={{state.date}}
                  @defaultMonth={{state.date}}
                  @onValueChange={{state.pickIntoInput}}
                  @today={{TODAY}}
                />
              </p.Content>
            </Popover>
          </g.Addon>
        </InputGroup>
      </template>,
    )
    const input = new InputGroupHarness('subscription')
    const picker = new DatePickerHarness('input')
    assert.strictEqual(picker.trigger.getAttribute('aria-label'), 'Select date')
    const addon = picker.trigger.closest<HTMLElement>('[data-slot="input-group-addon"]')!
    assert.strictEqual(
      getComputedStyle(addon).marginInlineEnd,
      '-4.8px',
      "the addon's has-[>button] margin reaches the button through the Popover's root",
    )

    await input.focus()
    await pressKey('ArrowDown')
    assert.true(picker.isOpen, 'ArrowDown opens it')
    assert.true(picker.calendar.isSelected('2026-01-20'))

    await picker.pick('2026-01-27')
    assert.false(picker.isOpen)
    assert.strictEqual(input.value, 'January 27, 2026')
    assert.dom(picker.trigger).isFocused()
    await a11yAudit()
  })

  test('DatePickerHarness is a PopoverHarness: it drives any popover, and says what it found', async function (assert) {
    await render(
      <template>
        <Popover @name="plain" as |p|>
          <p.Trigger>Open</p.Trigger>
          <p.Content aria-label="Plain">Nothing to pick</p.Content>
        </Popover>
      </template>,
    )
    const picker = new DatePickerHarness('plain')
    assert.true(picker instanceof PopoverHarness)
    assert.strictEqual(picker.text, 'Open')
    await picker.open()
    assert.false(picker.calendar.exists)
    try {
      await picker.pick('2026-01-20')
      assert.ok(false, 'it should have thrown')
    } catch (error) {
      assert.true(String(error).includes('no calendar in popover "plain" found'), String(error))
    }
    await a11yAudit()
  })
})
