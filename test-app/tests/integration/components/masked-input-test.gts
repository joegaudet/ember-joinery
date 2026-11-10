import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { render, rerender, settled } from '@ember/test-helpers'
import { on } from '@ember/modifier'
import { tracked } from '@glimmer/tracking'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import { Field, FieldLabel, asInput } from '@ember-joinery/ember'
import { FieldHarness, InputHarness, tab } from '@ember-joinery/test-support'
import {
  MaskedInput,
  dateMask,
  dateRangeMask,
  dateTimeMask,
  formatDate,
  formatNumber,
  formatTime,
  maskText,
  maskito,
  numberMask,
  parseDate,
  parseNumber,
  parseTime,
  timeMask,
  type MaskitoOptions,
} from '@ember-joinery/maskito'
import { MaskedInputHarness } from '@ember-joinery/maskito/test-support'

const digit = /\d/
const phoneMask: MaskitoOptions = {
  mask: ['(', digit, digit, digit, ')', ' ', digit, digit, digit, '-', digit, digit, digit, digit],
}
const postalMask: MaskitoOptions = {
  mask: [/[A-Za-z]/, digit, /[A-Za-z]/, ' ', digit, /[A-Za-z]/, digit],
}
const price = numberMask({ maximumFractionDigits: 2, thousandSeparator: ',', prefix: '$' })

class State {
  @tracked value: string | undefined = undefined
  @tracked mask: MaskitoOptions | null = phoneMask
  changes: string[] = []
  heard: string[] = []
  take = true
  onValueChange = (value: string) => {
    this.changes.push(value)
    if (this.take) this.value = value
  }
  hear = (event: Event) => this.heard.push((event.target as HTMLInputElement).value)
}

module('Integration | components | masked-input', function (hooks) {
  setupRenderingTest(hooks)

  test("it renders Joinery's Input, with its classes and its own harness's attribute", async function (assert) {
    await render(
      <template>
        <MaskedInput
          @name="phone"
          @mask={{phoneMask}}
          aria-label="Phone"
          placeholder="(555) 555-5555"
        />
      </template>,
    )
    const phone = new MaskedInputHarness('phone')
    assert
      .dom(phone.element)
      .hasTagName('input')
      .hasClass('jn-input')
      .hasAttribute('data-slot', 'input', "shadcn's Input, so the style sheets style it")
      .hasAttribute('data-test-jn', 'masked-input')
      .hasAttribute('data-test-jn-name', 'phone')
    const style = getComputedStyle(phone.control)
    assert.strictEqual(style.height, '32px', "Input's h-8")
    assert.strictEqual(style.borderTopWidth, '1px', "Input's border")
    assert.strictEqual(style.paddingInlineStart, '10px', "Input's px-2.5")
    assert.strictEqual(phone.label, 'Phone')
    assert.strictEqual(phone.placeholder, '(555) 555-5555')
    assert.strictEqual(phone.value, '')
    await a11yAudit()
  })

  test('the mask shapes what is typed, and turns away what does not fit', async function (assert) {
    const state = new State()
    await render(
      <template>
        <MaskedInput
          @name="phone"
          @mask={{phoneMask}}
          @onValueChange={{state.onValueChange}}
          aria-label="Phone"
        />
      </template>,
    )
    const phone = new MaskedInputHarness('phone')

    await phone.typeText('555')
    assert.strictEqual(phone.value, '(555', 'its fixed characters go in as digits reach them')
    await phone.typeText('x1234567')
    assert.strictEqual(phone.value, '(555) 123-4567', 'a letter is turned away')
    await phone.typeText('89')
    assert.strictEqual(phone.value, '(555) 123-4567', 'nothing goes past the end')
    assert.strictEqual(
      state.changes.at(-1),
      '(555) 123-4567',
      '@onValueChange hears the masked text',
    )
    assert.false(
      state.changes.some(change => /[^\d() -]/.test(change)),
      'and never a character the mask turned away',
    )

    await phone.backspace(5)
    assert.strictEqual(phone.value, '(555) 12', 'Backspace steps over its fixed characters')
    await a11yAudit()
  })

  test('a value filled in at once (autofill, a test) is masked before any listener reads it', async function (assert) {
    const state = new State()
    await render(
      <template>
        <MaskedInput
          @name="phone"
          @mask={{phoneMask}}
          @onValueChange={{state.onValueChange}}
          aria-label="Phone"
          {{on "input" state.hear}}
        />
      </template>,
    )
    const phone = new MaskedInputHarness('phone')

    await phone.fillIn('5551234567')
    assert.strictEqual(phone.value, '(555) 123-4567')
    assert.deepEqual(state.changes, ['(555) 123-4567'], '@onValueChange hears only the masked text')
    assert.deepEqual(state.heard, ['(555) 123-4567'], 'and so does an input listener of your own')

    await phone.paste('555 987 6543')
    assert.strictEqual(phone.value, '(555) 987-6543', 'a paste is masked too')
    await a11yAudit()
  })

  test('controlled, it shows @value masked, and a change it is not given back is undone', async function (assert) {
    const state = new State()
    state.value = '5551234567'
    await render(
      <template>
        <MaskedInput
          @name="phone"
          @mask={{phoneMask}}
          @value={{state.value}}
          @onValueChange={{state.onValueChange}}
          aria-label="Phone"
        />
      </template>,
    )
    const phone = new MaskedInputHarness('phone')
    assert.strictEqual(phone.value, '(555) 123-4567', 'a value set from code is shown masked')

    state.value = '2125550123'
    await rerender()
    assert.strictEqual(phone.value, '(212) 555-0123', 'and follows @value')

    state.take = false
    await phone.typeText('9')
    assert.strictEqual(phone.value, '(212) 555-0123', 'a change not taken is undone')

    state.take = true
    await phone.backspace()
    assert.strictEqual(state.value, '(212) 555-012', 'a change taken is the masked text')
    assert.strictEqual(phone.value, '(212) 555-012')
    await a11yAudit()
  })

  test('uncontrolled, it starts from @defaultValue, masked, and keeps its own value', async function (assert) {
    const state = new State()
    await render(
      <template>
        <MaskedInput
          @name="postal"
          @mask={{postalMask}}
          @defaultValue="k1a0b1"
          @onValueChange={{state.onValueChange}}
          aria-label="Postal code"
        />
      </template>,
    )
    const postal = new MaskedInputHarness('postal')
    assert.strictEqual(postal.value, 'k1a 0b1')
    await postal.backspace(3)
    assert.strictEqual(postal.value, 'k1a', 'it keeps its own value, its space stepped over')
    await postal.typeText('9z9')
    assert.strictEqual(postal.value, 'k1a 9z9')
    assert.deepEqual(state.changes.at(-1), 'k1a 9z9')
    await a11yAudit()
  })

  test('a new @mask replaces the mask; none takes it off', async function (assert) {
    const state = new State()
    await render(
      <template><MaskedInput @name="code" @mask={{state.mask}} aria-label="Code" /></template>,
    )
    const code = new MaskedInputHarness('code')
    await code.typeText('a5551234567')
    assert.strictEqual(code.value, '(555) 123-4567')

    state.mask = postalMask
    await settled()
    await code.clear()
    await code.typeText('h0h0h0')
    assert.strictEqual(code.value, 'h0h 0h0', 'the new mask shapes what comes next')

    state.mask = null
    await settled()
    await code.typeText('!?')
    assert.strictEqual(code.value, 'h0h 0h0!?', 'without one, anything goes in')
    await a11yAudit()
  })

  test("the presets mask numbers, dates and times with @maskito/kit's generators", async function (assert) {
    await render(
      <template>
        <MaskedInput @name="price" @mask={{price}} aria-label="Price" inputmode="decimal" />
        <MaskedInput @name="date" @mask={{(dateMask)}} aria-label="Date" />
        <MaskedInput @name="us-date" @mask={{dateMask mode="mm/dd/yyyy"}} aria-label="US date" />
        <MaskedInput @name="time" @mask={{(timeMask)}} aria-label="Time" />
        <MaskedInput @name="seconds" @mask={{timeMask mode="HH:MM:SS"}} aria-label="Seconds" />
        <MaskedInput @name="when" @mask={{(dateTimeMask)}} aria-label="When" />
        <MaskedInput @name="stay" @mask={{(dateRangeMask)}} aria-label="Stay" />
      </template>,
    )
    const amount = new MaskedInputHarness('price')
    await amount.typeText('1234567.891')
    assert.strictEqual(amount.value, '$1,234,567.89', 'thousands, two decimals and a prefix')
    assert.strictEqual(
      parseNumber(amount.value, { prefix: '$', thousandSeparator: ',' }),
      1234567.89,
    )
    assert.strictEqual(
      formatNumber(1234.5, { maximumFractionDigits: 2, thousandSeparator: ',' }),
      '1,234.5',
    )

    const date = new MaskedInputHarness('date')
    await date.typeText('31122024')
    assert.strictEqual(date.value, '31/12/2024', 'dd/mm/yyyy, with slashes, by default')
    const parsed = parseDate(date.value)
    assert.deepEqual(
      [parsed?.getFullYear(), parsed?.getMonth(), parsed?.getDate()],
      [2024, 11, 31],
      'a local date',
    )
    assert.strictEqual(parseDate('31/12'), null, 'or null while the date is begun')
    assert.strictEqual(formatDate(new Date(2024, 0, 2)), '02/01/2024')

    const usDate = new MaskedInputHarness('us-date')
    await usDate.typeText('13')
    assert.strictEqual(usDate.value, '01/3', 'a month past 12 is read as a single digit')

    const time = new MaskedInputHarness('time')
    await time.typeText('1435')
    assert.strictEqual(time.value, '14:35', 'HH:MM by default')
    assert.strictEqual(parseTime(time.value), 52_500_000, 'in milliseconds since midnight')
    assert.strictEqual(formatTime(52_500_000), '14:35')

    const seconds = new MaskedInputHarness('seconds')
    await seconds.typeText('235959')
    assert.strictEqual(seconds.value, '23:59:59')

    const when = new MaskedInputHarness('when')
    await when.typeText('311220241435')
    assert.strictEqual(when.value, '31/12/2024, 14:35')

    const stay = new MaskedInputHarness('stay')
    await stay.typeText('0101202431122024')
    assert.strictEqual(
      stay.value.replace(/\u00a0/g, ' '),
      '01/01/2024 – 31/12/2024',
      'two dates, an en dash between them (with no-break spaces)',
    )
    await a11yAudit()
  })

  test('the maskito modifier masks an input of your own, and maskText a value from code', async function (assert) {
    const state = new State()
    await render(
      <template>
        <input
          aria-label="Phone"
          {{asInput name="own"}}
          {{maskito phoneMask}}
          {{on "input" state.hear}}
        />
      </template>,
    )
    const own = new InputHarness('own')
    await own.fillIn('5551234567')
    assert.strictEqual(own.value, '(555) 123-4567')
    assert.deepEqual(state.heard, ['(555) 123-4567'], 'its own listener reads the masked text')
    assert.strictEqual(maskText('2125550123', phoneMask), '(212) 555-0123')
    assert.strictEqual(maskText('2125550123'), '2125550123', 'without a mask, it is left alone')
    assert.strictEqual(maskText(undefined, phoneMask), undefined)
    await a11yAudit()
  })

  test('in a Field, its label names it and Tab reaches it', async function (assert) {
    await render(
      <template>
        <button type="button">Before</button>
        <Field>
          <FieldLabel for="masked-phone">Phone</FieldLabel>
          <MaskedInput id="masked-phone" @name="phone" @mask={{phoneMask}} aria-invalid="true" />
        </Field>
      </template>,
    )
    const field = new FieldHarness()
    const phone = field.find(MaskedInputHarness)
    assert.strictEqual(phone.label, 'Phone')
    assert.true(phone.isInvalid)
    await tab()
    await tab()
    assert.true(phone.isFocused, 'it is in the tab order, as any input')
    await a11yAudit()
  })

  test('right to left, it takes the direction around it, and still masks', async function (assert) {
    await render(
      <template>
        <DirectionProvider @dir="rtl">
          <MaskedInput @name="date" @mask={{(dateMask)}} aria-label="التاريخ" />
        </DirectionProvider>
      </template>,
    )
    const date = new MaskedInputHarness('date')
    assert.strictEqual(getComputedStyle(date.control).direction, 'rtl')
    await date.typeText('01022025')
    assert.strictEqual(date.value, '01/02/2025')
    await a11yAudit()
  })
})
