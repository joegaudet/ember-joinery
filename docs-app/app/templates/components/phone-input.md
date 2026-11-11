# Phone Input

A phone number input with a country picker, masked as it is typed by each country's rules, that
stores the number in E.164 form.

<div class="callout">

**An opt-in add-on.** Phone Input is in its own package, `@ember-joinery/maskito`, built on
[Maskito](https://maskito.dev)'s `@maskito/phone` and
[libphonenumber-js](https://gitlab.com/catamphetamine/libphonenumber-js). Nothing in Joinery's
core packages imports it, so an app that doesn't install it doesn't load either.

</div>

shadcn/ui has no phone input, so this one is drawn from the nearest shadcn parts: it is an
[Input Group](/components/input-group.md) whose addon is a ghost Input Group Button that opens a
[Select](/components/select.md) of countries, each with its flag and calling code. It follows
the style, base colour and radius you pick, as they do. Its sibling in the same package is
[Masked Input](/components/masked-input.md).

<Example @name="phone-input-demo" @title="Phone Input" />

## Installation

Phone Input is an add-on, so it comes in its own package, with `@maskito/core`,
`@maskito/kit`, `@maskito/phone` and `libphonenumber-js` as its dependencies, so they need no
install of their own:

```bash
pnpm add @ember-joinery/maskito @ember-joinery/ember
```

It ships no CSS of its own: Joinery's `joinery.css` (or any of its styles) styles its parts, as
it does every component. Import that once (see [Installation](/getting-started/installation.md)),
then the component where you use it:

```gts
import { PhoneInput } from '@ember-joinery/maskito'
```

It loads libphonenumber-js's `min` metadata (about 80 kB), with every country's numbering rules.
The package's root brings in every module, this one too; an app that uses only Masked Input can
import it from its own subpath, `@ember-joinery/maskito/components/masked-input`, and never load
the metadata.

## Usage

```gts
<PhoneInput @value={{this.phone}} @onValueChange={{this.setPhone}} />
```

## Typing and storing

The value is the number in [E.164](https://en.wikipedia.org/wiki/E.164) form,
`+12125550123`, whatever the input shows, or `null` while it is empty, controlled or not
(`@value`, `@defaultValue` and `@onValueChange`). A number you pass is shown formatted; while a
number is being typed, the value holds its digits so far, with the `+`.

The input shows the international format, `+1 212 555-0123`, with the country's calling code
fixed in front: it goes in when the input takes focus and comes out again on blur if nothing
follows it. Backspace stops at it. The input is `type="tel"` with `autocomplete="tel"` and
`inputmode="tel"`, so phones show a dial pad and browsers can fill in the user's number.

A number that arrives whole (pasted, dropped, or filled in by the browser, which fills a
`tel` field with the full international number) is read before the mask sees it. One that
starts with `+` or `00` is read in its own country, which the picker switches to, so a saved
`+44 7400 123456` stays a number of the United Kingdom however the input was set up. Anything
else, such as a national number, the mask shapes for the country shown.

## Choosing a country

The picker shows the country of the value, else `@defaultCountry`, else the first of
`@countries`, else the United States. Choose another, and the national number typed so far moves
to its calling code, and focus goes back to the input to go on typing. A number that starts with
`+` (or `00`) pasted, dropped or autofilled switches to that number's country, and so does a
value from another country you pass. Typing a `+` doesn't: the mask keeps the calling code of the
country shown in front, so choose the country first. Typing on the closed picker chooses the
country whose name starts with what was typed, as any Select does.

The country is controlled or not too (`@country`, `@defaultCountry` and `@onCountryChange`).
Countries are named in `@locale`'s language (the browser's, by default), with
`Intl.DisplayNames`, and listed by name.

## National format

`@national` shows the number as it is dialled at home, `(212) 555-0123` or `07400 123456`, and
puts the calling code beside the flag. The value is still E.164.

<Example @name="phone-input-national" @title="National format" />

## A list of your own

`@countries` narrows the picker to the countries given, as ISO 3166 codes, in their order, and
without `@defaultCountry` or a value it starts on the first of them. A number from a country the
list leaves out, pasted, dropped or autofilled, is turned away: the input keeps what it held, and
no other number is stored. So is one whose calling code no country has.

<Example @name="phone-input-countries" @title="Some countries" />

## Validating

The mask limits a number's length, but it can't tell a whole number from a partial one.
`isValidPhone(value, country?)` checks a stored number with libphonenumber-js, so use it when the
form is saved, as the first example does:

```ts
import { isValidPhone } from '@ember-joinery/maskito'

isValidPhone('+12125550123') // true
isValidPhone('+1212') // false
```

It returns `false` for `null` and empty strings, and checks against the `min` metadata, which
checks a number's length for its country; pass the `max` metadata as the third argument to
check its digits too. `formatPhone(value)` shows a stored number in international format, to
show it outside an input.

## RTL

Phone Input lays itself out right to left inside any element with `dir="rtl"` (see
[Direction](/primitives/direction.md)): the picker moves to the right, at the field's start, and
the number sits beside it. A phone number reads left to right in any language, so the input is
`dir="ltr"`. Name the countries in the page's language with `@locale`, and the picker with
`@countryLabel`, whose English default (the input's label, then `country`) is the only text
Phone Input adds.

<Example @name="phone-input-rtl" @title="RTL" @dir="rtl" />

## API Reference

### PhoneInput

| Argument           | Type                              | Default            | What it does                                                         |
| ------------------ | --------------------------------- | ------------------ | -------------------------------------------------------------------- |
| `@value`           | `string \| null`                  |                    | The number in E.164 form, or `null`, controlled                      |
| `@defaultValue`    | `string \| null`                  |                    | The number it starts with, uncontrolled                              |
| `@onValueChange`   | `(value: string \| null) => void` |                    | Called with the new number whenever it changes                       |
| `@country`         | `CountryCode`                     |                    | The country, controlled (ISO 3166: `US`, `GB`…)                      |
| `@defaultCountry`  | `CountryCode`                     | see below          | The country it starts with, uncontrolled                             |
| `@onCountryChange` | `(country: CountryCode) => void`  |                    | Called with the new country whenever it changes                      |
| `@countries`       | `CountryCode[]`                   | every country      | The countries the picker offers, in this order                       |
| `@national`        | `boolean`                         | `false`            | Show the national format, with the calling code beside the flag      |
| `@locale`          | `string`                          | the browser's      | The language the countries are named in                              |
| `@countryLabel`    | `string`                          | see below          | The picker's whole accessible name                                   |
| `@icon`            | `IconNode`                        | `chevron-down`     | The picker's chevron                                                 |
| `@metadata`        | `MetadataJson`                    | the `min` metadata | libphonenumber-js metadata (`max`, `mobile`, or your own)            |
| `@disabled`        | `boolean`                         | `false`            | Disables the input and the picker                                    |
| `@formName`        | `string`                          |                    | Puts a hidden input by this name in a form, holding the E.164 number |
| `@name`            | `string`                          |                    | Its name, for `PhoneInputHarness` (`data-test-jn-name`)              |

Its attributes go on the `<input>`: `id` (for a `<FieldLabel for>`), `placeholder`,
`aria-invalid`, `aria-describedby`, `required`. An invalid input rings the whole group.

Without `@defaultCountry`, it starts in the country of its value, else the first of
`@countries`, else `US`. Without `@countryLabel`, the picker is named after the input: its label
(its `aria-labelledby`, its `<label>`, or its `aria-label`), then `country`, as in `Phone country`.

### The helpers

| Export                                 | What it is                                                               |
| -------------------------------------- | ------------------------------------------------------------------------ |
| `isValidPhone(value, country?, meta?)` | Whether a stored number is valid                                         |
| `formatPhone(value, meta?)`            | A stored number in international format                                  |
| `countryOfPhone(value, current?)`      | The country of a number, keeping `current` while the calling code fits   |
| `phoneMask(country, { national })`     | The Maskito options for a country, for a `{{maskito}}` input of your own |
| `phoneCountries()`, `callingCode(c)`   | Every country the metadata has, and a country's calling code             |
| `countryFlag(country)`                 | A country's flag emoji                                                   |

### Data attributes

| Part    | Attribute            | Value                                                   |
| ------- | -------------------- | ------------------------------------------------------- |
| root    | `data-test-jn`       | `phone-input` (a wrapper with `display: contents`)      |
| root    | `data-test-jn-value` | the country shown                                       |
| group   | `data-slot`          | `input-group`, Input Group's                            |
| group   | `data-country`       | the country shown                                       |
| input   | `data-slot`          | `input-group-control`                                   |
| input   | `data-test-jn`       | `input`, so `InputHarness` drives it                    |
| picker  | `data-test-jn`       | `select`, named `country`, so `SelectHarness` drives it |
| trigger | `data-slot`          | `button` (a ghost, `xs` Input Group Button)             |
| item    | `data-slot`          | `select-item`; its value is the country's code          |

## Keyboard interactions

| Key                        | What it does                                                             |
| -------------------------- | ------------------------------------------------------------------------ |
| `Tab`                      | Moves from the input to the picker, then on                              |
| `Enter`, `Space`, `↓`, `↑` | On the picker, opens the list of countries                               |
| A letter                   | On the closed picker, chooses the next country whose name starts with it |
| `↓`, `↑`, `Home`, `End`    | In the open list, move between countries; typing finds one by name       |
| `Enter`                    | Chooses the country and sends focus to the input                         |
| `Escape`                   | Closes the list and sends focus back to the picker                       |

The input is a text input: the mask decides what a key puts in, and Backspace stops at the
calling code.

## Accessibility

- The input is named as any input is: by a `<FieldLabel for>` (its `id`), `aria-label` or
  `aria-labelledby`. The picker is a `combobox` named after the input, `Phone country`, so a
  form with several phone inputs, as in the first example, has pickers a screen reader tells
  apart: `aria-labelledby` names the input's label and a hidden `country` (a `<label>` without
  an `id` is given one), or, for an input named by `aria-label`, `aria-label` repeats it.
  `@countryLabel` replaces that name, whole: give each picker its own. The picker holds the
  country's name for assistive technology; its flag is hidden from it.
- Each country in the list is an option named by its name and calling code.
- The input reads left to right in any language (`dir="ltr"`), as phone numbers do.

## Testing

`PhoneInputHarness`, from `@ember-joinery/maskito/test-support`, drives the input as a keyboard
or a paste would, and the picker as a Select:

```ts
import { PhoneInputHarness } from '@ember-joinery/maskito/test-support'

const phone = new PhoneInputHarness('phone')
await phone.selectCountry('GB')
await phone.typeText('7400123456')
assert.strictEqual(phone.value, '+44 7400 123456')
await phone.paste('+33 6 12 34 56 78')
assert.strictEqual(phone.country, 'FR')
```

| Member                                 | What it is                                                |
| -------------------------------------- | --------------------------------------------------------- |
| `value`                                | What the input shows, masked                              |
| `country`                              | The country shown, as its ISO code                        |
| `countryName`                          | Its name, as the picker reads it                          |
| `flag`                                 | The flag the picker shows                                 |
| `callingCode`                          | The calling code beside the flag (`+1`), with `@national` |
| `label`, `description`, `placeholder`  | The input's                                               |
| `isDisabled`, `isInvalid`, `isFocused` | The input's state                                         |
| `input`                                | The input, as an [`InputHarness`](/components/input.md)   |
| `picker`                               | The picker, as a [`SelectHarness`](/components/select.md) |
| `control`, `group`                     | The `<input>` and the Input Group around it               |
| `countries()`                          | Opens the picker and reads its countries' codes           |
| `selectCountry(c)`                     | Opens the picker and chooses a country                    |
| `typeText(text)`                       | Types at the end, as a keyboard does                      |
| `backspace(n)`                         | Presses Backspace at the end, `n` times                   |
| `paste(text)`                          | Selects everything and pastes over it                     |
| `drop(text)`                           | Drops text at the end, as a drag and drop does            |
| `fillIn(text)`                         | Fills the input at once, as the browser's autofill does   |
| `clear()`, `focus()`, `blur()`         | Empties the input, focuses it, takes focus off it         |

## Built on

[Maskito](https://github.com/taiga-family/maskito) 5 (Apache 2.0): `@maskito/phone`'s strict
phone mask, one country at a time, with `@maskito/kit`'s focus and blur plugins for the calling
code; and [libphonenumber-js](https://gitlab.com/catamphetamine/libphonenumber-js) (MIT), whose
metadata holds each country's rules, which converts what is typed to E.164 and finds a number's
country. Formwright's `@ember-formwright/maskito/phone` offers the same as its `phone` control,
without a country picker; this is the standalone component, for use without a form library. The
first example on this page ports Formwright's guide example for it. Formwright's office field is
`@strict={{false}}`, which takes any country's number typed from its `+`; with a country picker,
Phone Input has no such mode, so that field's hint says to pick the country or paste the number
instead.
