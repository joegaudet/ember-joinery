# @ember-joinery/maskito

## 1.0.1

### Patch Changes

- Updated dependencies [2b887bf]
- Updated dependencies [2b887bf]
- Updated dependencies [2b887bf]
- Updated dependencies [2b887bf]
- Updated dependencies [2b887bf]
- Updated dependencies [2b887bf]
- Updated dependencies [2b887bf]
- Updated dependencies [2b887bf]
  - @ember-joinery/primitives@1.0.1
  - @ember-joinery/ember@1.0.1
  - @ember-joinery/test-support@1.0.1

## 1.0.0

### Major Changes

- a73065d: `@ember-joinery/maskito` is a new opt-in add-on, on Maskito: masked inputs in shadcn's look.
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

### Minor Changes

- 17c5b5c: The add-ons' built-in strings go through the app's translator, each package's in its own
  `<package>/messages`: Carousel's role descriptions, slide names (`{index} of {count}`) and step
  buttons; Code Block's Copy and Copied; File Upload's prompt, hint, drop label, its rejected,
  left-out, remove, retry and progress names, Upload failed and `FILE`; Phone Input's country
  picker's name; Power Calendar's month buttons, its calendars' names and the pickers' placeholder,
  trigger names and range (`{from} – {to}`); the Rich Text Editor's toolbar, text styles,
  tools and its shortcuts' Ctrl, Shift and Alt. An argument still wins. File Upload's, Phone Input's and Power Calendar's `@locale`
  default to the translator's. Chart and Data Table show no strings of their own.

### Patch Changes

- a73065d: Every package's tarball carries Joinery's `LICENSE.md` and `NOTICE`, with the licences and
  notices of what it ports (shadcn/ui, ember-primitives, sonner, recharts and the rest), copied in
  from the repository's root by the package's `prepack`.
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [17c5b5c]
- Updated dependencies [17c5b5c]
- Updated dependencies [99eab0c]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
  - @ember-joinery/primitives@1.0.0
  - @ember-joinery/ember@1.0.0
  - @ember-joinery/test-support@1.0.0
