import Component from '@glimmer/component'
import { cached, tracked } from '@glimmer/tracking'
import { on } from '@ember/modifier'
import { renderSettled } from '@ember/renderer'
import { waitForPromise } from '@ember/test-waiters'
import { modifier } from 'ember-modifier'
import { ChevronDown } from 'lucide'
import { maskitoTransform, type MaskitoOptions } from '@maskito/core'
import { AsYouType, parsePhoneNumberFromString } from 'libphonenumber-js/core'
import { ControllableState } from '@ember-joinery/primitives/controllable-state'
import { idFor } from '@ember-joinery/primitives/id'
import { nativeValue } from '@ember-joinery/primitives/native-value'
import { VisuallyHidden } from '@ember-joinery/primitives/visually-hidden'
import Icon, { type IconNode } from '@ember-joinery/ember/components/icon'
import {
  inputGroupAddonClasses,
  inputGroupButtonClasses,
} from '@ember-joinery/ember/components/input-group'
import { inputClasses } from '@ember-joinery/ember/components/input'
import Select from '@ember-joinery/ember/components/select'
import { maskito } from '../maskito.ts'
import {
  callingCode,
  countryFlag,
  countryOfPhone,
  phoneCountries,
  phoneMask,
  phoneMetadata,
  type CountryCode,
  type MetadataJson,
} from '../phone.ts'
import { t, translate, translator } from '@ember-joinery/primitives/i18n'
import { messages } from '../messages.ts'

/** A country in the picker. */
export interface PhoneCountry {
  /** Its ISO 3166 code, such as `GB`. */
  code: CountryCode
  /** Its name, in `@locale`'s language. */
  name: string
  /** Its calling code, without the `+`. */
  callingCode: string
  /** Its flag, as an emoji. */
  flag: string
}

export interface PhoneInputSignature {
  Args: {
    /**
     * The number in E.164 form (`+12125550123`), or `null` while it is empty, when you control
     * it. While a number is being typed it holds the digits so far, with the `+`.
     */
    value?: string | null
    /** The number it starts with when you don't control it. */
    defaultValue?: string | null
    /** Called with the new number (E.164, or `null`) whenever it changes. */
    onValueChange?: (value: string | null) => void
    /** The country whose numbers are typed (ISO 3166), when you control it. */
    country?: CountryCode
    /**
     * The country it starts with: by default the country of its value, else the first of
     * `@countries`, else `US`.
     */
    defaultCountry?: CountryCode
    /** Called with the new country whenever it changes. */
    onCountryChange?: (country: CountryCode) => void
    /** The countries the picker offers, in this order. Default: every country, by name. */
    countries?: readonly CountryCode[]
    /** Show numbers in the national format, `(212) 555-0123`; the calling code sits by the flag. */
    national?: boolean
    /** libphonenumber-js metadata. Default its `min` metadata. */
    metadata?: MetadataJson
    /** The language the countries are named in. Default the app's translator's, or the browser's. */
    locale?: string
    /**
     * The country picker's whole accessible name. By default it is named after the input: its
     * label and `country` (`Phone country`), so several phone inputs' pickers differ.
     */
    countryLabel?: string
    /** The picker's chevron. Default lucide's `chevron-down`. */
    icon?: IconNode
    /** Disables the input and the country picker. */
    disabled?: boolean
    /** Puts a hidden input by this name in a form, holding the number in E.164 form. */
    formName?: string
    /** Its name, for `PhoneInputHarness` (`data-test-jn-name`). */
    name?: string
  }
  /** The `<input type="tel">`: give it `id`, `placeholder`, `aria-invalid`, `aria-describedby`… */
  Element: HTMLInputElement
}

/** `display: contents`, set through the CSSOM so a strict Content Security Policy allows it. */
const displayContents = modifier((element: HTMLElement) => {
  element.style.setProperty('display', 'contents')
})

/**
 * The number in `text` when it is an international one, `+` or `00` and then digits, written
 * `+…` with its spaces and punctuation gone; else `undefined`.
 */
function internationalNumber(text: string): string | undefined {
  const number = text
    .trim()
    .replace(/^00/, '+')
    .replace(/[^\d+]/g, '')
  return /^\+\d+$/.test(number) ? number : undefined
}

/** The `beforeinput` types that bring a whole number at once, read before the mask sees them. */
const WHOLE_INSERTS = new Set(['insertFromDrop', 'insertFromPaste', 'insertReplacementText'])

/** A press on the addon, but not on its button, focuses the input, as Input Group's does. */
function focusInput(event: MouseEvent): void {
  if ((event.target as Element | null)?.closest('button')) return
  const addon = event.currentTarget as HTMLElement
  addon.parentElement?.querySelector('input')?.focus()
}

const INPUT_CLASSES = `${inputClasses()} jn-input-group-input jn-phone-input-input`
const ADDON_CLASSES = `${inputGroupAddonClasses({ align: 'inline-start' })} jn-phone-input-addon`
const TRIGGER_CLASSES = `${inputGroupButtonClasses({ variant: 'ghost', size: 'xs' })} jn-phone-input-trigger`

/**
 * A phone number input with a country picker, in shadcn's look: an Input Group whose addon is
 * a Select of countries (each with its flag and calling code), and whose input
 * `@maskito/phone` masks as it is typed in, by the rules libphonenumber-js has for the chosen
 * country. Its value is the number in E.164 form, `+12125550123`, or `null` while it is empty:
 *
 *   <PhoneInput @value={{this.phone}} @onValueChange={{this.setPhone}} />
 *   <PhoneInput @defaultCountry="GB" @national={{true}} />
 *
 * The picker shows the country of the value: a number from another country, set, pasted,
 * dropped or autofilled, switches it, and choosing a country keeps the national number typed so
 * far. `@countries` narrows the list.
 */
export default class PhoneInput extends Component<PhoneInputSignature> {
  /** What was last typed; shown while it still stands for the value. */
  @tracked private typed: string | undefined
  /** Whether the picker closed because a country was chosen, so focus goes to the input. */
  #chose = false
  #input: HTMLInputElement | undefined
  #mask: { key: string; metadata: MetadataJson; options: MaskitoOptions } | undefined

  valueState = new ControllableState<string | null>({
    name: 'value',
    value: () => this.args.value,
    defaultValue: () => this.args.defaultValue,
    onChange: () => this.args.onValueChange,
    fallback: null,
  })

  countryState = new ControllableState<CountryCode>({
    name: 'country',
    value: () => this.args.country,
    defaultValue: () =>
      this.args.defaultCountry ??
      countryOfPhone(this.valueState.value, undefined, this.metadata) ??
      this.args.countries?.[0] ??
      'US',
    onChange: () => this.args.onCountryChange,
    fallback: 'US',
  })

  get metadata(): MetadataJson {
    return this.args.metadata ?? phoneMetadata
  }

  get national(): boolean {
    return this.args.national ?? false
  }

  /** The number, in E.164 form, or `null`. */
  get value(): string | null {
    return this.valueState.value
  }

  /** The country shown: the value's, whose calling code decides, else the one chosen. */
  get country(): CountryCode {
    const chosen = this.countryState.value
    return countryOfPhone(this.value, chosen, this.metadata) ?? chosen
  }

  get callingCode(): string {
    return callingCode(this.country, this.metadata)
  }

  get flag(): string {
    return countryFlag(this.country)
  }

  get countryName(): string {
    return this.nameOf(this.country)
  }

  /** The hidden `country` that follows the input's label in the picker's default name. */
  get countryWordId(): string {
    return idFor(this, 'country-word')
  }

  get locale(): string | undefined {
    return this.args.locale ?? translator(this)?.locale
  }

  @cached
  get displayNames(): Intl.DisplayNames {
    return new Intl.DisplayNames(this.locale ? [this.locale] : undefined, {
      type: 'region',
    })
  }

  nameOf(code: CountryCode): string {
    return this.displayNames.of(code) ?? code
  }

  /** The countries in the picker. */
  @cached
  get countries(): PhoneCountry[] {
    const metadata = this.metadata
    const given = this.args.countries
    const countries = (given ?? phoneCountries(metadata)).map(code => ({
      code,
      name: this.nameOf(code),
      callingCode: callingCode(code, metadata),
      flag: countryFlag(code),
    }))
    if (given) return countries
    const collator = new Intl.Collator(this.locale)
    return countries.sort((a, b) => collator.compare(a.name, b.name))
  }

  /** The mask for the country shown, made again only when the country or format changes. */
  get options(): MaskitoOptions {
    return this.maskFor(this.country, this.national, this.metadata)
  }

  /** The last mask made, kept while it is for the same country, format and metadata. */
  maskFor(country: CountryCode, national: boolean, metadata: MetadataJson): MaskitoOptions {
    const key = `${country}:${national}`
    const mask = this.#mask
    if (mask?.key === key && mask.metadata === metadata) return mask.options
    const options = phoneMask(country, { national, metadata })
    this.#mask = { key, metadata, options }
    return options
  }

  /** The E.164 form of what the input shows, or `null` when it shows no digits. */
  toE164(text: string, country: CountryCode): string | null {
    const digits = text.replace(/[^\d+]/g, '')
    if (!/\d/.test(digits)) return null
    const formatter = new AsYouType(country, this.metadata)
    formatter.input(digits)
    // A calling code on its own, which the international mask keeps in front, is no number.
    if (!formatter.getNumber()?.nationalNumber) return null
    return formatter.getNumberValue() ?? null
  }

  /** A number in E.164 form, as the input shows it for `country`. */
  format(value: string, country: CountryCode): string {
    const options = phoneMask(country, { national: this.national, metadata: this.metadata })
    if (!this.national) return maskitoTransform(value, options)
    const parsed = parsePhoneNumberFromString(value, this.metadata)
    const national = parsed ? parsed.formatNational() : this.nationalNumberOf(value)
    return maskitoTransform(national.replace(/\D/g, ''), options)
  }

  /** The national part of a number in E.164 form, whole or begun. */
  nationalNumberOf(value: string): string {
    const formatter = new AsYouType(undefined, this.metadata)
    formatter.input(value)
    return formatter.getNumber()?.nationalNumber ?? ''
  }

  /** What the input shows: what was typed, while it stands for the value, else the value. */
  get shown(): string {
    const value = this.value
    const typed = this.typed
    if (typed !== undefined && this.toE164(typed, this.country) === value) return typed
    return value ? this.format(value, this.country) : ''
  }

  /** The input changed (the mask has shaped it already). */
  onText = (text: string): void => {
    const country = this.country
    // A number set from outside may show another country than the one chosen: typing keeps it.
    if (country !== this.countryState.value) this.countryState.set(country)
    this.typed = text
    this.valueState.set(this.toE164(text, country))
  }

  /** A country was chosen: the national number typed so far moves to its calling code. */
  chooseCountry = (code: string): void => {
    const country = code as CountryCode
    this.#chose = true
    if (country === this.country) return
    const value = this.value
    this.countryState.set(country)
    // A controlled country that didn't change leaves the number alone.
    if (this.countryState.value !== country) return
    this.typed = undefined
    if (!value) return
    const national = this.nationalNumberOf(value)
    const moved = national ? `+${callingCode(country, this.metadata)}${national}` : null
    this.valueState.set(moved ? this.toE164(this.format(moved, country), country) : null)
  }

  /**
   * A whole number that arrives at once: pasted, dropped, autofilled, or filled in by a test.
   * One that starts with `+` (or `00`) is read in its own country, which the picker switches
   * to, and replaces what the input holds: the mask of the country shown would read its calling
   * code as the first digits of a number of its own, and store another number. A number from a
   * country `@countries` leaves out, or whose calling code is unknown, is turned away. Anything
   * else is left to the mask (`undefined`).
   */
  takeNumber(text: string): 'taken' | 'refused' | undefined {
    const number = internationalNumber(text)
    if (!number) return undefined
    const country = countryOfPhone(number, this.country, this.metadata)
    const allowed = this.args.countries
    if (!country || (allowed && !allowed.includes(country))) return 'refused'
    if (country !== this.countryState.value) this.countryState.set(country)
    this.typed = undefined
    this.valueState.set(this.toE164(this.format(number, country), country))
    return 'taken'
  }

  /** Whether the mask of the country shown leaves `text` as it is: text it shaped itself. */
  fitsMask(text: string): boolean {
    const options = phoneMask(this.country, { national: this.national, metadata: this.metadata })
    return maskitoTransform(text, options) === text
  }

  /**
   * Reads a whole number before the mask does, in the capture phase, so it goes before
   * `{{maskito}}` in the template: a paste (its clipboard), a drop or a writing suggestion (its
   * `beforeinput`), and an `input` no `beforeinput` announced, as Chrome's autofill and
   * `fillIn()` send (with no `inputType`) and Firefox's (`insertReplacementText`). Typing has an
   * `inputType` and is left alone, and so is text the mask shaped itself (the calling code its
   * focus plugin puts in, with an `input` of no type). A number taken or turned away goes no
   * further, and the input shows what the value now is.
   */
  wholeNumbers = modifier((element: HTMLInputElement) => {
    const read = (text: string, event: Event): void => {
      if (!this.takeNumber(text)) return
      event.preventDefault()
      event.stopImmediatePropagation()
      element.value = this.shown
    }
    const onPaste = (event: ClipboardEvent) =>
      read(event.clipboardData?.getData('text/plain') ?? '', event)
    const onBeforeInput = (event: InputEvent) => {
      if (!WHOLE_INSERTS.has(event.inputType)) return
      // One that can't be cancelled is read from its `input`, once it is in.
      if (!event.cancelable) return
      read(event.data ?? event.dataTransfer?.getData('text/plain') ?? '', event)
    }
    const onInput = (event: Event) => {
      const { inputType } = event as InputEvent
      if (inputType && inputType !== 'insertReplacementText') return
      if (this.fitsMask(element.value)) return
      read(element.value, event)
    }
    const options = { capture: true }
    element.addEventListener('paste', onPaste, options)
    element.addEventListener('beforeinput', onBeforeInput, options)
    element.addEventListener('input', onInput, options)
    return () => {
      element.removeEventListener('paste', onPaste, options)
      element.removeEventListener('beforeinput', onBeforeInput, options)
      element.removeEventListener('input', onInput, options)
    }
  })

  /**
   * Names the picker after its input, `Phone country`, so a screen reader tells apart the
   * pickers of a form with several phone inputs: the input's `aria-labelledby`, else its
   * `<label>`s (given an id if they have none), then a hidden `country`; else its `aria-label`
   * and `country`. `@countryLabel` names it instead.
   */
  nameTrigger = modifier((trigger: HTMLElement, [label]: [string | undefined]) => {
    if (label) {
      trigger.setAttribute('aria-label', label)
      return () => trigger.removeAttribute('aria-label')
    }
    const input = trigger
      .closest('[data-slot="input-group"]')
      ?.querySelector<HTMLInputElement>('input[data-slot="input-group-control"]')
    const given = new Map<HTMLLabelElement, string>()
    let ids = input?.getAttribute('aria-labelledby')?.trim()
    if (!ids && input?.labels?.length) {
      ids = [...input.labels]
        .map((element, index) => {
          if (element.id) return element.id
          element.id = idFor(this, `label-${index}`)
          given.set(element, element.id)
          return element.id
        })
        .join(' ')
    }
    if (ids) {
      trigger.setAttribute('aria-labelledby', `${ids} ${this.countryWordId}`)
    } else {
      const name = input?.getAttribute('aria-label')?.trim()
      trigger.setAttribute(
        'aria-label',
        name ? translate(this, messages.namedCountry, { name }) : translate(this, messages.country),
      )
    }
    return () => {
      trigger.removeAttribute('aria-labelledby')
      trigger.removeAttribute('aria-label')
      for (const [element, id] of given) if (element.id === id) element.removeAttribute('id')
    }
  })

  /**
   * Choosing a country sends focus to the input, to type the number; Escape, to the picker.
   * It goes once the input shows the new country's mask, so that mask's calling code goes in.
   */
  onCloseAutoFocus = (event: Event): void => {
    if (!this.#chose) return
    this.#chose = false
    event.preventDefault()
    void waitForPromise(renderSettled().then(() => this.#input?.focus()))
  }

  onOpenChange = (open: boolean): void => {
    if (open) this.#chose = false
  }

  registerInput = modifier((element: HTMLInputElement) => {
    this.#input = element
    return () => {
      if (this.#input === element) this.#input = undefined
    }
  })

  <template>
    <div
      class="jn-phone-input"
      data-test-jn="phone-input"
      data-test-jn-name={{@name}}
      data-test-jn-value={{this.country}}
      {{displayContents}}
    >
      <Select
        @value={{this.country}}
        @onValueChange={{this.chooseCountry}}
        @onOpenChange={{this.onOpenChange}}
        @disabled={{@disabled}}
        @name="country"
        as |s|
      >
        <div
          class="group/input-group jn-input-group"
          role="group"
          data-slot="input-group"
          data-country={{this.country}}
          data-test-jn-part="group"
        >
          <input
            class={{INPUT_CLASSES}}
            data-slot="input-group-control"
            data-test-jn="input"
            type="tel"
            autocomplete="tel"
            inputmode="tel"
            dir="ltr"
            disabled={{@disabled}}
            {{this.registerInput}}
            {{this.wholeNumbers}}
            {{nativeValue value=this.shown onValueChange=this.onText}}
            {{maskito this.options}}
            ...attributes
          />
          <div
            class={{ADDON_CLASSES}}
            role="group"
            data-slot="input-group-addon"
            data-align="inline-start"
            data-test-jn-part="addon"
            {{on "click" focusInput}}
          >
            <button
              class={{TRIGGER_CLASSES}}
              data-slot="button"
              data-variant="ghost"
              data-size="xs"
              {{this.nameTrigger @countryLabel}}
              {{s.trigger}}
            >
              <span class="jn-phone-input-flag" aria-hidden="true">{{this.flag}}</span>
              <VisuallyHidden data-test-jn-part="country-name">{{this.countryName}}</VisuallyHidden>
              {{#if this.national}}
                <span class="jn-phone-input-calling-code" data-test-jn-part="calling-code">
                  +{{this.callingCode}}
                </span>
              {{/if}}
              <Icon
                @icon={{if @icon @icon ChevronDown}}
                class="jn-phone-input-chevron"
                aria-hidden="true"
              />
            </button>
          </div>
        </div>
        <s.Content
          @position="popper"
          @align="start"
          @onCloseAutoFocus={{this.onCloseAutoFocus}}
          class="jn-phone-input-content"
        >
          {{#each this.countries key="code" as |country|}}
            <s.Item @value={{country.code}} @textValue={{country.name}} class="jn-phone-input-item">
              <span class="jn-phone-input-flag" aria-hidden="true">{{country.flag}}</span>
              <span class="jn-phone-input-item-name">{{country.name}}</span>
              <span class="jn-phone-input-item-code">+{{country.callingCode}}</span>
            </s.Item>
          {{/each}}
        </s.Content>
      </Select>
      <span id={{this.countryWordId}} hidden>{{t messages.countryWord}}</span>
      {{#if @formName}}
        <input type="hidden" name={{@formName}} value={{if this.value this.value ""}} />
      {{/if}}
    </div>
  </template>
}
