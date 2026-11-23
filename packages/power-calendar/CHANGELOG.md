# @ember-joinery/power-calendar

## 1.0.1

### Patch Changes

- 2b887bf: The date pickers track their modes with a Switchyard chart; nothing changes in behavior, except that a close a controlled `@open` refuses no longer forgets the month paged to or the start of a range. A controlled Dialog no longer calls `@onClose`, nor clears its `returnValue`, for a close or open its `@open` refused, and InputOTP clears its pending selection sync when it goes.
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

- a73065d: `@ember-joinery/power-calendar` is a new opt-in add-on, on ember-power-calendar 2:
  `PowerCalendar`, `PowerCalendarRange` and `PowerCalendarMultiple`, ember-power-calendar's
  calendars drawn as shadcn's Calendar (ghost-Button chevrons around the caption, a grid of ghost
  icon Buttons, today shaded, the chosen days filled, a range's middle shaded as one band, each
  style's `--cell-size` and `--cell-radius`), and `DatePicker` and `DateRangePicker`, which open one
  in a Joinery Popover from an outlined Button or from an Input Group's input that reads typed
  dates. Values are `Date`s at local midnight and ranges `{ from, to }`, controlled or not
  (`@value`, `@defaultValue`, `@onValueChange`), with `@center` for the month shown, `@minDate`,
  `@maxDate`, `@disabledDates` (dates, `YYYY-MM-DD` or weekdays), `@locale`, `@startOfWeek`,
  `@weekdayFormat` and `@showDaysAround`; a range takes `@minRange`, `@maxRange` and
  `@proximitySelection`, several days `@maxLength`, and the pickers `@trigger`, `@placeholder`,
  `@format`, `@id`, `@disabled`, `@invalid`, `@describedBy` and `@open`. The grid is WAI-ARIA's:
  one tab stop, the arrow keys (flipped right to left), Home, End, Page Up and Page Down, past
  days that can't be chosen, each day named by its full date. A picker's button is named by its
  label and the date it shows, and its calendar opens with focus on the chosen day. A native `Date`
  and `Intl` date library is registered for ember-power-calendar unless the app has one
  (`nativeDateLibrary`, `ensureDateLibrary()`), and `formatDate`, `formatDateRange`, `parseDate`,
  `toDate` and `toIsoDate` are exported. Its `/test-support` has `PowerCalendarHarness` and
  `DatePickerHarness`. `@ember-joinery/ember`'s style sheets style its parts
  (`power-calendar.css`); nothing in the core packages imports it.

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

- a53c07b: Type checks in package source use `@sindresorhus/is` (`isString`, `isFunction`, …) instead of `typeof`, and a lint rule keeps it that way. `@sindresorhus/is` is a new runtime dependency, so `ember-joinery add` now installs it into the app for most components, `icon` included. `isNumber` rejects `NaN`, so a `NaN` reaching a numeric check now takes the non-number branch.
- 99eab0c: Built-in strings follow a live change of the translator's `locale`: a carousel's slide names
  (`1 of 5`) and an input OTP's fallback name (`One-time password`) are set again in the new
  language, not only on the next render. A date range picker reads typed text with the range
  message it writes (`{from} – {to}`, or its translation), so a translated separator reads back,
  and a dash, a hyphen or `to` still split English.
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
