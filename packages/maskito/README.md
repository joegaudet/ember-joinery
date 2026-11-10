# @ember-joinery/maskito

Masked inputs in shadcn/ui's look for Ember, an opt-in add-on to
[Joinery](https://joegaudet.com/ember-joinery/), on [Maskito](https://maskito.dev): a Masked
Input with number, date and time presets, a `{{maskito}}` modifier for inputs of your own, and a
Phone Input with a country picker that stores E.164.

> **Pre-release.** Nothing is published yet; see the
> [repository](https://github.com/joegaudet/ember-joinery#readme).

```bash
npm install @ember-joinery/maskito @ember-joinery/ember
```

`@maskito/core`, `@maskito/kit`, `@maskito/phone` and `libphonenumber-js` come with it, as its
dependencies. It ships no CSS of its own: `@ember-joinery/ember`'s `joinery.css` (or any of its
styles) styles its parts, as it does every Joinery component.

```gts
import { MaskedInput, PhoneInput, numberMask } from '@ember-joinery/maskito'

const phoneMask = {
  mask: ['(', /\d/, /\d/, /\d/, ')', ' ', /\d/, /\d/, /\d/, '-', /\d/, /\d/, /\d/, /\d/],
}

<template>
  <MaskedInput @mask={{phoneMask}} @value={{this.phone}} @onValueChange={{this.setPhone}} />
  <MaskedInput @mask={{numberMask maximumFractionDigits=2 thousandSeparator="," prefix="$"}} />
  <PhoneInput @value={{this.mobile}} @onValueChange={{this.setMobile}} @defaultCountry="GB" />
</template>
```

- **`MaskedInput`** is Joinery's Input with a mask: `@mask` takes any Maskito options. Its value
  is the masked text, controlled or not (`@value`, `@defaultValue`, `@onValueChange`).
- **Presets**: `numberMask`, `dateMask`, `timeMask`, `dateTimeMask` and `dateRangeMask` wrap
  `@maskito/kit`'s generators; `parseNumber`, `parseDate` and `parseTime` read their text back,
  and `formatNumber`, `formatDate` and `formatTime` write it.
- **`{{maskito options}}`** masks an `<input>` or `<textarea>` of your own (an Input Group's,
  say), and `maskText(text, options)` shows a value set from code as the mask would.
- **`PhoneInput`** is an Input Group with a Select of countries (flag, name and calling code) in
  its addon, masked by `@maskito/phone` for the country chosen. Its value is E.164
  (`+12125550123`) or `null`; a pasted international number switches the country. It takes
  `@country`, `@countries`, `@national`, `@locale` and `@metadata`, and `isValidPhone()`,
  `formatPhone()` and `countryOfPhone()` check and show stored numbers.

Each module is also a subpath of its own (`@ember-joinery/maskito/components/masked-input`,
`/components/phone-input`, `/maskito`, `/presets`, `/phone`), so an app that uses only the masked
input never loads libphonenumber-js's metadata.

Its harnesses, `MaskedInputHarness` and `PhoneInputHarness`, are in
`@ember-joinery/maskito/test-support`. They type the way a browser does, with the `beforeinput`
events the mask answers, and paste.

Full documentation: the Masked Input and Phone Input pages of the guide at
**https://joegaudet.com/ember-joinery/guide/**. Built on [Maskito](https://maskito.dev)
(Apache 2.0) and [libphonenumber-js](https://gitlab.com/catamphetamine/libphonenumber-js) (MIT);
design ported from [shadcn/ui](https://ui.shadcn.com/) (MIT).
