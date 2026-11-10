import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { Field, FieldDescription, FieldGroup, FieldLabel } from '@ember-joinery/ember'
import {
  MaskedInput,
  dateMask,
  numberMask,
  parseDate,
  parseNumber,
  parseTime,
  timeMask,
} from '@ember-joinery/maskito'

const money = { maximumFractionDigits: 2, thousandSeparator: ',', prefix: '$' }
const priceMask = numberMask(money)
const birthdayMask = dateMask({ mode: 'mm/dd/yyyy', max: new Date(2026, 11, 31) })
const startMask = timeMask({ mode: 'HH:MM AA' })

export default class MaskedInputPresets extends Component {
  @tracked price = ''
  @tracked birthday = ''
  @tracked start = ''

  setPrice = (value: string) => (this.price = value)
  setBirthday = (value: string) => (this.birthday = value)
  setStart = (value: string) => (this.start = value)

  /** What the masked texts read as: a number, a date and a time of day. */
  get amount(): string {
    const amount = parseNumber(this.price, money)
    return Number.isNaN(amount) ? '—' : String(amount)
  }

  get date(): string {
    const date = parseDate(this.birthday, { mode: 'mm/dd/yyyy' })
    return date ? date.toDateString() : '—'
  }

  get minutes(): string {
    if (this.start.length < 8) return '—'
    return `${parseTime(this.start, { mode: 'HH:MM AA' }) / 60_000} minutes after midnight`
  }

  <template>
    <FieldGroup class="w-full max-w-xs">
      <Field>
        <FieldLabel for="masked-input-presets-price">Price</FieldLabel>
        <MaskedInput
          id="masked-input-presets-price"
          @name="price"
          @mask={{priceMask}}
          @value={{this.price}}
          @onValueChange={{this.setPrice}}
          placeholder="$0.00"
          inputmode="decimal"
          aria-describedby="masked-input-presets-price-value"
        />
        <FieldDescription id="masked-input-presets-price-value">
          Reads as
          {{this.amount}}
        </FieldDescription>
      </Field>
      <Field>
        <FieldLabel for="masked-input-presets-birthday">Birthday</FieldLabel>
        <MaskedInput
          id="masked-input-presets-birthday"
          @name="birthday"
          @mask={{birthdayMask}}
          @value={{this.birthday}}
          @onValueChange={{this.setBirthday}}
          placeholder="mm/dd/yyyy"
          inputmode="numeric"
          aria-describedby="masked-input-presets-birthday-value"
        />
        <FieldDescription id="masked-input-presets-birthday-value">
          Reads as
          {{this.date}}
        </FieldDescription>
      </Field>
      <Field>
        <FieldLabel for="masked-input-presets-start">Starts at</FieldLabel>
        <MaskedInput
          id="masked-input-presets-start"
          @name="start"
          @mask={{startMask}}
          @value={{this.start}}
          @onValueChange={{this.setStart}}
          placeholder="09:00 AM"
          aria-describedby="masked-input-presets-start-value"
        />
        <FieldDescription id="masked-input-presets-start-value">
          Reads as
          {{this.minutes}}
        </FieldDescription>
      </Field>
    </FieldGroup>
  </template>
}
