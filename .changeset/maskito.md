---
'@ember-joinery/maskito': major
'@ember-joinery/ember': minor
---

`@ember-joinery/maskito` is a new opt-in add-on, on Maskito: masked inputs in shadcn's look.
`MaskedInput` is Joinery's Input with a mask (`@mask`, any Maskito options), whose value is the
masked text, controlled or not, and which shows a value passed in masked. The `{{maskito}}`
modifier masks an input or textarea of your own, such as an Input Group's, and every `input`
listener on it reads the masked text; `maskText()` masks a value from code. The presets,
`numberMask`, `dateMask`, `timeMask`, `dateTimeMask` and `dateRangeMask`, wrap `@maskito/kit`'s
generators, with `parseNumber`, `parseDate`, `parseTime` and their `format*` counterparts to read
and write their text. `PhoneInput` is an Input Group whose addon is a ghost Input Group Button
opening a Select of countries (flag, name in `@locale`'s language, calling code), and whose input
`@maskito/phone` masks for the country chosen; its value is the number in E.164 form, or `null`.
Choosing a country moves the national number to its calling code and sends focus to the input,
and an international number pasted, dropped or autofilled is read in its own country, which the
picker switches to (one from a country `@countries` leaves out is turned away); `@countries`
(whose first country it starts on), `@national`, `@country` and `@metadata` shape it, and the
picker is named after its input (`Phone country`) unless `@countryLabel` names it. It lays
itself out right to left with the number still left to right. `isValidPhone`, `formatPhone` and
`countryOfPhone` check and show stored numbers. Its `/test-support` has `MaskedInputHarness` and
`PhoneInputHarness`, which type, delete, paste, drop, fill in, undo and redo as a browser does. `@ember-joinery/ember`'s style sheets style its parts; nothing in the
core packages imports it.
