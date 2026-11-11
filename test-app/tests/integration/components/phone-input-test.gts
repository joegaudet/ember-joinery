import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { render, rerender, settled } from '@ember/test-helpers'
import { tracked } from '@glimmer/tracking'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import { Field, FieldDescription, FieldLabel } from '@ember-joinery/ember'
import { FieldHarness, pressKey, tab } from '@ember-joinery/test-support'
import {
  PhoneInput,
  callingCode,
  countryFlag,
  countryOfPhone,
  formatPhone,
  isValidPhone,
  phoneCountries,
  type CountryCode,
} from '@ember-joinery/maskito'
import { PhoneInputHarness } from '@ember-joinery/maskito/test-support'

const rect = (element: Element) => element.getBoundingClientRect()

class State {
  @tracked value: string | null | undefined = undefined
  @tracked country: CountryCode | undefined = undefined
  changes: Array<string | null> = []
  countries: string[] = []
  take = true
  onValueChange = (value: string | null) => {
    this.changes.push(value)
    if (this.take) this.value = value
  }
  onCountryChange = (country: CountryCode) => {
    this.countries.push(country)
    if (this.take) this.country = country
  }
}

const EUROPE: CountryCode[] = ['GB', 'FR', 'DE']

module('Integration | components | phone-input', function (hooks) {
  setupRenderingTest(hooks)

  test('it renders an Input Group: a tel input, and a country picker in its addon', async function (assert) {
    await render(
      <template>
        <PhoneInput @name="phone" aria-label="Phone" placeholder="+1 212 555-0123" />
      </template>,
    )
    const phone = new PhoneInputHarness('phone')
    assert.dom(phone.group).hasClass('jn-input-group').hasAttribute('role', 'group')
    assert.dom(phone.group).hasAttribute('data-slot', 'input-group')
    assert
      .dom(phone.control)
      .hasClass('jn-input')
      .hasClass('jn-input-group-input')
      .hasAttribute(
        'data-slot',
        'input-group-control',
        "the group's focus and invalid rings follow it",
      )
      .hasAttribute('type', 'tel')
      .hasAttribute('autocomplete', 'tel', 'browsers can fill in the number')
      .hasAttribute('inputmode', 'tel', 'phones show a dial pad')
      .hasAttribute('dir', 'ltr', 'a number reads left to right')
    const addon = phone.picker.trigger.parentElement!
    assert
      .dom(addon)
      .hasClass('jn-input-group-addon-align-inline-start')
      .hasAttribute('data-align', 'inline-start')
    assert
      .dom(phone.picker.trigger)
      .hasClass('jn-input-group-button', 'the picker is a ghost Input Group Button')
      .hasAttribute('data-variant', 'ghost')
      .hasAttribute('role', 'combobox')
      .hasAttribute('aria-expanded', 'false')
    assert.strictEqual(phone.picker.label, 'Phone country', 'named after the input')
    assert.strictEqual(phone.country, 'US', 'the United States, with no value or country')
    assert.strictEqual(phone.countryName, 'United States', 'named for assistive technology')
    assert.strictEqual(phone.flag, countryFlag('US'))
    assert.strictEqual(phone.label, 'Phone')
    assert.strictEqual(phone.value, '')

    const group = getComputedStyle(phone.group)
    assert.strictEqual(group.height, '32px', "Input Group's h-8")
    assert.strictEqual(group.borderTopWidth, '1px')
    assert.strictEqual(getComputedStyle(phone.picker.trigger).height, '24px', "the button's h-6")
    assert.strictEqual(
      getComputedStyle(phone.control).borderTopWidth,
      '0px',
      "the input's border is the group's",
    )
    assert.true(
      rect(addon).right <= rect(phone.control).left + 1,
      'the picker sits before the input',
    )
    await a11yAudit()
  })

  test('typing stores the number in E.164 form, and shows it masked', async function (assert) {
    const state = new State()
    await render(
      <template>
        <PhoneInput @name="phone" @onValueChange={{state.onValueChange}} aria-label="Phone" />
      </template>,
    )
    const phone = new PhoneInputHarness('phone')

    await phone.typeText('212')
    assert.strictEqual(phone.value, '+1 212', "the country's calling code goes in front")
    assert.strictEqual(state.changes.at(-1), '+1212', 'while it is typed, the digits so far')
    await phone.typeText('5550123')
    assert.strictEqual(phone.value, '+1 212 555-0123')
    assert.strictEqual(state.changes.at(-1), '+12125550123')
    await phone.typeText('9')
    assert.strictEqual(phone.value, '+1 212 555-0123', 'nothing goes past a whole number')

    await phone.backspace(12)
    assert.strictEqual(phone.value, '+1 ', 'Backspace leaves the calling code')
    assert.strictEqual(state.changes.at(-1), null, 'which is no number: null')
    await a11yAudit()
  })

  test('the calling code goes in on focus, and comes out on blur if nothing follows it', async function (assert) {
    await render(<template><PhoneInput @name="phone" aria-label="Phone" /></template>)
    const phone = new PhoneInputHarness('phone')
    await phone.focus()
    assert.strictEqual(phone.value, '+1 ', 'in front, ready for the first digit')
    await phone.blur()
    assert.strictEqual(phone.value, '', 'out again, so the placeholder shows')

    await phone.typeText('212')
    await phone.blur()
    assert.strictEqual(phone.value, '+1 212', 'it stays in front of a number')
    await a11yAudit()
  })

  test('controlled, it shows @value formatted, follows it, and undoes a change it is not given back', async function (assert) {
    const state = new State()
    state.value = '+12125550123'
    await render(
      <template>
        <PhoneInput
          @name="phone"
          @value={{state.value}}
          @onValueChange={{state.onValueChange}}
          aria-label="Phone"
        />
      </template>,
    )
    const phone = new PhoneInputHarness('phone')
    assert.strictEqual(phone.value, '+1 212 555-0123')

    state.value = '+447400123456'
    await rerender()
    assert.strictEqual(
      phone.value,
      '+44 7400 123456',
      'a number from elsewhere shows in its own format',
    )
    assert.strictEqual(phone.country, 'GB', 'and switches the country to its own')

    state.take = false
    await phone.backspace()
    assert.strictEqual(phone.value, '+44 7400 123456', 'a change not taken is undone')
    assert.strictEqual(state.changes.at(-1), '+44740012345')

    state.take = true
    state.value = null
    await rerender()
    assert.strictEqual(phone.value, '', 'null empties it')
    await a11yAudit()
  })

  test('uncontrolled, it starts from @defaultValue, in that number’s country', async function (assert) {
    await render(
      <template>
        <PhoneInput @name="phone" @defaultValue="+33612345678" aria-label="Phone" />
        <PhoneInput @name="canada" @defaultValue="+14165550123" aria-label="Canada" />
        <PhoneInput @name="japan" @defaultCountry="JP" aria-label="Japan" />
      </template>,
    )
    const phone = new PhoneInputHarness('phone')
    assert.strictEqual(phone.value, '+33 6 12-34-56-78')
    assert.strictEqual(phone.country, 'FR')
    assert.strictEqual(phone.countryName, 'France')
    assert.strictEqual(
      new PhoneInputHarness('canada').country,
      'CA',
      'a +1 number of Canada is Canadian',
    )
    const japan = new PhoneInputHarness('japan')
    assert.strictEqual(japan.country, 'JP', '@defaultCountry, with no value')
    await japan.typeText('9012345678')
    assert.strictEqual(japan.value, '+81 90 1234-5678')
    await a11yAudit()
  })

  test('choosing a country moves the national number to its calling code, and focus to the input', async function (assert) {
    const state = new State()
    await render(
      <template>
        <PhoneInput
          @name="phone"
          @onValueChange={{state.onValueChange}}
          @onCountryChange={{state.onCountryChange}}
          aria-label="Phone"
        />
      </template>,
    )
    const phone = new PhoneInputHarness('phone')
    await phone.typeText('7400123456')
    assert.strictEqual(phone.value, '+1 740 012-3456', 'typed as a number of the United States')

    await phone.selectCountry('GB')
    assert.strictEqual(phone.country, 'GB')
    assert.deepEqual(state.countries, ['GB'], '@onCountryChange hears it')
    assert.strictEqual(phone.value, '+44 7400 123456', 'the digits typed stay, under +44')
    assert.strictEqual(state.changes.at(-1), '+447400123456')
    assert.true(phone.isFocused, 'focus goes to the input, to go on typing')
    assert.false(phone.picker.isOpen)

    await phone.picker.open()
    await phone.picker.pressEscape()
    assert
      .dom(phone.picker.trigger)
      .isFocused('Escape sends focus back to the picker, as a Select does')
    await a11yAudit()
  })

  test('the picker lists every country by name, with its flag and calling code', async function (assert) {
    await render(<template><PhoneInput @name="phone" aria-label="Phone" /></template>)
    const phone = new PhoneInputHarness('phone')
    const countries = await phone.countries()
    assert.strictEqual(countries.length, phoneCountries().length, 'every country the metadata has')
    assert.strictEqual(countries[0], 'AF', 'in order of their names: Afghanistan first')
    assert.strictEqual(phone.picker.position, 'popper', 'below the picker, as a dropdown')
    const gb = phone.picker.option('GB')
    assert.strictEqual(
      gb.textContent?.replace(/\s+/g, ' ').trim(),
      `${countryFlag('GB')} United Kingdom +44`,
    )
    assert.dom(gb.querySelector('.jn-phone-input-flag')).hasAttribute('aria-hidden', 'true')
    assert.true(phone.picker.isOptionSelected('US'), 'the country shown is selected')
    const content = phone.picker.content!
    assert.true(rect(content).height <= 288 + 1, 'no taller than 18rem')
    // As if the page left 120px for it; its transition (`duration-100`) would ease the change.
    content.style.setProperty('transition', 'none')
    content.style.setProperty('--radix-select-content-available-height', '120px')
    assert.strictEqual(
      getComputedStyle(content).maxHeight,
      '120px',
      'nor than the space left on the page, as a Select',
    )
    await a11yAudit()
  })

  test('@countries narrows the list and keeps its order; @locale names them', async function (assert) {
    await render(
      <template>
        <PhoneInput
          @name="phone"
          @countries={{EUROPE}}
          @defaultCountry="FR"
          @locale="fr"
          aria-label="Téléphone"
        />
      </template>,
    )
    const phone = new PhoneInputHarness('phone')
    assert.strictEqual(phone.countryName, 'France')
    assert.deepEqual(await phone.countries(), ['GB', 'FR', 'DE'])
    assert.deepEqual(
      phone.picker.optionTexts.map(text => text.replace(/^\S+ /, '')),
      ['Royaume-Uni +44', 'France +33', 'Allemagne +49'],
    )
    await a11yAudit()
  })

  test('pasting an international number switches to its country', async function (assert) {
    const state = new State()
    await render(
      <template>
        <PhoneInput
          @name="phone"
          @onValueChange={{state.onValueChange}}
          @onCountryChange={{state.onCountryChange}}
          aria-label="Phone"
        />
      </template>,
    )
    const phone = new PhoneInputHarness('phone')
    await phone.paste('+33 6 12 34 56 78')
    assert.strictEqual(phone.country, 'FR')
    assert.strictEqual(phone.value, '+33 6 12-34-56-78')
    assert.strictEqual(state.changes.at(-1), '+33612345678')
    assert.deepEqual(state.countries, ['FR'])

    await phone.paste('0049 1512 3456789')
    assert.strictEqual(phone.country, 'DE', '00 reads as +')
    assert.strictEqual(state.changes.at(-1), '+4915123456789')

    await phone.paste('030 1234')
    assert.strictEqual(phone.country, 'DE', 'a national number stays in the country')
    await a11yAudit()
  })

  test('an international number filled in at once (autofill) or dropped switches to its country', async function (assert) {
    const state = new State()
    await render(
      <template>
        <PhoneInput
          @name="phone"
          @onValueChange={{state.onValueChange}}
          @onCountryChange={{state.onCountryChange}}
          aria-label="Phone"
        />
        <PhoneInput @name="national" @national={{true}} aria-label="National" />
      </template>,
    )
    const phone = new PhoneInputHarness('phone')
    // fillIn() sends what Chrome's autofill does: the whole number, and an input with no type.
    await phone.fillIn('+447400123456')
    assert.strictEqual(phone.country, 'GB', 'not read as a number of the United States')
    assert.strictEqual(phone.value, '+44 7400 123456')
    assert.strictEqual(state.changes.at(-1), '+447400123456', 'the number filled in, stored')
    assert.deepEqual(state.countries, ['GB'])

    await phone.fillIn('+33 6 12 34 56 78')
    assert.strictEqual(phone.country, 'FR', 'written with spaces')
    assert.strictEqual(state.changes.at(-1), '+33612345678')

    await phone.fillIn('0049 1512 3456789')
    assert.strictEqual(phone.country, 'DE', '00 reads as +')
    assert.strictEqual(state.changes.at(-1), '+4915123456789')

    await phone.fillIn('+1 212 555 0123')
    assert.strictEqual(phone.country, 'US')
    assert.strictEqual(phone.value, '+1 212 555-0123')

    await phone.fillIn('2125550199')
    assert.strictEqual(phone.value, '+1 212 555-0199', 'a national number is the mask’s')
    assert.strictEqual(state.changes.at(-1), '+12125550199')

    await phone.clear()
    await phone.drop('+44 7400 123456')
    assert.strictEqual(phone.country, 'GB', 'a number dropped in switches too')
    assert.strictEqual(phone.value, '+44 7400 123456')
    assert.strictEqual(state.changes.at(-1), '+447400123456')

    const national = new PhoneInputHarness('national')
    await national.fillIn('+447400123456')
    assert.strictEqual(national.country, 'GB', 'in the national format too')
    assert.strictEqual(national.value, '07400 123456')
    await national.fillIn('+12125550123')
    assert.strictEqual(national.value, '(212) 555-0123', 'its calling code beside the flag')
    assert.strictEqual(national.callingCode, '+1')
    await a11yAudit()
  })

  test('a number from a country the list leaves out is turned away', async function (assert) {
    const state = new State()
    await render(
      <template>
        <PhoneInput
          @name="phone"
          @countries={{EUROPE}}
          @defaultCountry="GB"
          @onValueChange={{state.onValueChange}}
          aria-label="Phone"
        />
      </template>,
    )
    const phone = new PhoneInputHarness('phone')
    await phone.paste('+1 212 555 0123')
    assert.strictEqual(phone.country, 'GB', 'the country stays')
    assert.strictEqual(phone.value, '+44 ', 'and nothing goes in after its calling code')
    assert.deepEqual(state.changes, [], 'so no other number is stored')

    await phone.typeText('7400123456')
    await phone.fillIn('+12125550123')
    assert.strictEqual(phone.value, '+44 7400 123456', 'filled in, it is undone')
    assert.strictEqual(state.changes.at(-1), '+447400123456')
    await phone.drop('+1 212 555 0123')
    assert.strictEqual(phone.value, '+44 7400 123456', 'dropped, it never goes in')

    await phone.paste('+33 6 12 34 56 78')
    assert.strictEqual(phone.country, 'FR', 'a country the list has is switched to')
    await phone.paste('+999 123')
    assert.strictEqual(phone.value, '+33 6 12-34-56-78', 'as is a calling code no country has')
    await a11yAudit()
  })

  test('with @countries and no country or value, it starts on the first of them', async function (assert) {
    await render(
      <template><PhoneInput @name="phone" @countries={{EUROPE}} aria-label="Phone" /></template>,
    )
    const phone = new PhoneInputHarness('phone')
    assert.strictEqual(phone.country, 'GB', 'not the United States, which the list leaves out')
    assert.strictEqual(phone.countryName, 'United Kingdom')
    await phone.typeText('7400123456')
    assert.strictEqual(phone.value, '+44 7400 123456', 'with its mask')
    await a11yAudit()
  })

  test('@national shows the national format, with the calling code by the flag', async function (assert) {
    const state = new State()
    await render(
      <template>
        <PhoneInput
          @name="phone"
          @national={{true}}
          @defaultValue="+12125550123"
          @onValueChange={{state.onValueChange}}
          aria-label="Phone"
        />
        <PhoneInput @name="uk" @national={{true}} @defaultCountry="GB" aria-label="UK" />
      </template>,
    )
    const phone = new PhoneInputHarness('phone')
    assert.strictEqual(phone.value, '(212) 555-0123')
    assert.strictEqual(phone.callingCode, '+1')
    await phone.backspace(4)
    assert.strictEqual(state.changes.at(-1), '+1212555', 'the value is still E.164')

    await phone.selectCountry('CA')
    assert.strictEqual(phone.country, 'CA', 'Canada shares +1')
    assert.strictEqual(phone.value, '(212) 555', 'so the number stays as it is')
    assert.strictEqual(phone.callingCode, '+1')

    const uk = new PhoneInputHarness('uk')
    await uk.typeText('07400123456')
    assert.strictEqual(uk.value, '07400 123456', 'with the national prefix')
    assert.strictEqual(uk.callingCode, '+44')
    await a11yAudit()
  })

  test('controlled country: @country and @onCountryChange', async function (assert) {
    const state = new State()
    state.country = 'GB'
    await render(
      <template>
        <PhoneInput
          @name="phone"
          @country={{state.country}}
          @onCountryChange={{state.onCountryChange}}
          @value={{state.value}}
          @onValueChange={{state.onValueChange}}
          aria-label="Phone"
        />
      </template>,
    )
    const phone = new PhoneInputHarness('phone')
    assert.strictEqual(phone.country, 'GB')
    state.country = 'DE'
    await rerender()
    assert.strictEqual(phone.country, 'DE', 'it follows @country')
    await phone.typeText('15123456789')
    assert.strictEqual(state.value, '+4915123456789')

    state.take = false
    await phone.selectCountry('FR')
    assert.deepEqual(state.countries, ['FR'], 'it asks for the change')
    assert.strictEqual(phone.country, 'DE', 'and keeps the country it is given')
    assert.strictEqual(state.value, '+4915123456789', 'and the number')
    await a11yAudit()
  })

  test('the picker takes the keyboard as a Select: arrows open it, typing chooses', async function (assert) {
    await render(
      <template><PhoneInput @name="phone" @countries={{EUROPE}} aria-label="Phone" /></template>,
    )
    const phone = new PhoneInputHarness('phone')
    assert.strictEqual(phone.country, 'GB', 'the first of @countries')
    await phone.focus()
    await tab()
    assert.dom(phone.picker.trigger).isFocused('Tab moves from the input to the picker')
    await phone.picker.typeahead('fr')
    assert.strictEqual(phone.country, 'FR', 'typing a name on the closed picker chooses it')
    await phone.picker.openWithKeyboard('ArrowDown')
    assert.true(phone.picker.isOpen)
    assert.strictEqual(phone.picker.highlighted, 'FR', 'on the country chosen')
    await pressKey('ArrowDown')
    await pressKey('Enter')
    assert.strictEqual(phone.country, 'DE')
    assert.true(phone.isFocused, 'and focus is in the input')
    await a11yAudit()
  })

  test('@disabled disables the input and the picker', async function (assert) {
    await render(
      <template><PhoneInput @name="phone" @disabled={{true}} aria-label="Phone" /></template>,
    )
    const phone = new PhoneInputHarness('phone')
    assert.true(phone.isDisabled)
    assert.dom(phone.control).isDisabled()
    assert.strictEqual(
      getComputedStyle(phone.group).opacity,
      '0.5',
      "the group's has-disabled:opacity-50",
    )
    await a11yAudit()
  })

  test('in a Field, its label and description name and describe the input', async function (assert) {
    await render(
      <template>
        <Field>
          <FieldLabel for="field-phone">Mobile</FieldLabel>
          <PhoneInput
            id="field-phone"
            @name="phone"
            aria-describedby="field-phone-hint"
            aria-invalid="true"
          />
          <FieldDescription id="field-phone-hint">We text a code to it.</FieldDescription>
        </Field>
      </template>,
    )
    const field = new FieldHarness()
    const phone = field.find(PhoneInputHarness)
    assert.strictEqual(phone.label, 'Mobile')
    assert.strictEqual(phone.description, 'We text a code to it.')
    assert.true(phone.isInvalid)
    assert.notStrictEqual(
      getComputedStyle(phone.group).borderTopColor,
      getComputedStyle(field.element).color,
      'the group rings an invalid input',
    )
    await a11yAudit()
  })

  test('each picker is named after its input, so several of them differ', async function (assert) {
    await render(
      <template>
        <Field>
          <FieldLabel for="names-home">Home</FieldLabel>
          <PhoneInput id="names-home" @name="home" />
        </Field>
        <Field>
          <FieldLabel id="names-work-label" for="names-work">Work</FieldLabel>
          <PhoneInput id="names-work" @name="work" />
        </Field>
        <span id="names-mobile-label">Mobile</span>
        <PhoneInput @name="mobile" aria-labelledby="names-mobile-label" />
        <PhoneInput @name="fax" aria-label="Fax" />
        <PhoneInput @name="own" aria-label="Phone" @countryLabel="Country of the phone" />
      </template>,
    )
    const home = new PhoneInputHarness('home')
    assert.strictEqual(home.picker.label, 'Home country', "its <label>'s text, then country")
    assert.strictEqual(new PhoneInputHarness('work').picker.label, 'Work country')
    assert
      .dom(new PhoneInputHarness('work').picker.trigger)
      .hasAttribute(
        'aria-labelledby',
        /^names-work-label /,
        'a label with an id is named by it, so a new label text follows',
      )
    assert.strictEqual(
      new PhoneInputHarness('mobile').picker.label,
      'Mobile country',
      'its aria-labelledby',
    )
    assert.strictEqual(new PhoneInputHarness('fax').picker.label, 'Fax country', 'its aria-label')
    assert.strictEqual(
      new PhoneInputHarness('own').picker.label,
      'Country of the phone',
      '@countryLabel names it instead',
    )
    await a11yAudit()
  })

  test('@formName puts the number in a form, in E.164 form', async function (assert) {
    await render(
      <template>
        <form data-test-form>
          <PhoneInput @name="phone" @formName="phone" @defaultCountry="GB" aria-label="Phone" />
        </form>
      </template>,
    )
    const phone = new PhoneInputHarness('phone')
    const contact = document.querySelector<HTMLFormElement>('[data-test-form]')!
    assert.strictEqual(new FormData(contact).get('phone'), '', 'empty while it holds no number')
    await phone.typeText('7400123456')
    await settled()
    assert.strictEqual(new FormData(contact).get('phone'), '+447400123456')
    await a11yAudit()
  })

  test('right to left, the picker moves to the right and the number still reads left to right', async function (assert) {
    await render(
      <template>
        <DirectionProvider @dir="rtl">
          <PhoneInput
            @name="phone"
            @defaultValue="+966501234567"
            @locale="ar"
            aria-label="الهاتف"
          />
        </DirectionProvider>
      </template>,
    )
    const phone = new PhoneInputHarness('phone')
    const addon = phone.picker.trigger.parentElement!
    assert.true(
      rect(addon).left >= rect(phone.control).right - 1,
      'the picker is at the inline start: the right',
    )
    assert.strictEqual(getComputedStyle(phone.control).direction, 'ltr')
    assert.strictEqual(
      getComputedStyle(phone.control).textAlign,
      'right',
      'at the start of the field',
    )
    assert.strictEqual(phone.value, '+966 50 123-4567')
    assert.strictEqual(phone.countryName, 'المملكة العربية السعودية', 'named in Arabic')
    await a11yAudit()
  })

  test('its helpers read, check and show numbers', async function (assert) {
    assert.true(isValidPhone('+12125550123'))
    assert.false(isValidPhone('+1212'))
    assert.false(isValidPhone(null))
    assert.true(isValidPhone('2125550123', 'US'), 'a national number, read as the country’s')
    assert.strictEqual(formatPhone('+447400123456'), '+44 7400 123456')
    assert.strictEqual(formatPhone('not a number'), 'not a number')
    assert.strictEqual(formatPhone(null), '')
    assert.strictEqual(countryOfPhone('+33612345678'), 'FR')
    assert.strictEqual(countryOfPhone('+1', 'CA'), 'CA', 'the country given, while its code fits')
    assert.strictEqual(countryOfPhone('+44'), 'GB', 'the main country of a calling code')
    assert.strictEqual(countryOfPhone('212'), undefined)
    assert.strictEqual(callingCode('JP'), '81')
    assert.strictEqual(countryFlag('fr'), '🇫🇷')
    await render(<template><PhoneInput @name="phone" aria-label="Phone" /></template>)
    await a11yAudit()
  })
})
