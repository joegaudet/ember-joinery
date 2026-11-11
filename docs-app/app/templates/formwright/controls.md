# Controls

Joinery's inputs as Formwright controls (all but FileDrop; see [Not here](#not-here)).
`setupJoineryForms()` (or `registerJoineryControls()`) registers them, so a field names one
with `@control`:

| `@control`                                                                                                      | Joinery component                                 | Stores                                          |
| --------------------------------------------------------------------------------------------------------------- | ------------------------------------------------- | ----------------------------------------------- |
| `input` (the default), `text`, `email`, `password`, `search`, `tel`, `url`, `color`, `date`, `datetime`, `time` | [Input](/components/input.md)                     | a string                                        |
| `number`                                                                                                        | [Input](/components/input.md), `type="number"`    | a number, or `null` while empty                 |
| `currency`                                                                                                      | Formwright's currency control, as Joinery's Input | a number, shown in `@currency` and `@locale`    |
| `textarea`                                                                                                      | [Textarea](/components/textarea.md)               | a string                                        |
| `select`                                                                                                        | [Select](/components/select.md)                   | the option (or its key, `@storeKey`), or `null` |
| `native-select`                                                                                                 | [Native Select](/components/native-select.md)     | the option, or `null`                           |
| `combobox`                                                                                                      | [Combobox](/components/combobox.md)               | the option, or `null`                           |
| `checkbox`                                                                                                      | [Checkbox](/components/checkbox.md)               | `true` or `false`                               |
| `checkbox-group`                                                                                                | a [Checkbox](/components/checkbox.md) per option  | the options checked                             |
| `radio`                                                                                                         | [Radio Group](/components/radio-group.md)         | the option chosen                               |
| `switch`                                                                                                        | [Switch](/components/switch.md)                   | `true` or `false`                               |
| `toggle`                                                                                                        | [Toggle](/components/toggle.md)                   | `true` (pressed) or `false`                     |
| `toggle-group`                                                                                                  | [Toggle Group](/components/toggle-group.md)       | the option pressed, or a list of them           |
| `slider`, `range`                                                                                               | [Slider](/components/slider.md)                   | a number, or a list for a range                 |
| `rating`                                                                                                        | [Rating](/components/rating.md)                   | the rating, a number, or `null` for none        |
| `input-otp`                                                                                                     | [Input OTP](/components/input-otp.md)             | the code, a string                              |
| `date-picker`                                                                                                   | [Date Picker](/components/date-picker.md)         | a `Date`, or `null`                             |

Formwright's own names (`input` and its types, `number`, `textarea`, `currency`, `select`,
`checkbox`, `checkbox-group`, `radio` and `range`) render Joinery's component in place of
Formwright's. To keep one of Formwright's, leave it out:

```ts
setupJoineryForms({ except: ['select'] }) // or registerJoineryControls({ only: [...] })
```

Each control is also exported (`SelectControl`, `SwitchControl`…), for `@control={{SelectControl}}`
or `registerControl('language', SelectControl)`, and `joineryControls` lists them by name. A
control takes the field's arguments it declares (`@options`, `@optionKey`, `@optionLabel`,
`@storeKey`, `@min`, `@max`, `@step`, `@maxLength`, as fits it, and every field's `@placeholder`,
`@disabled`, `@readonly`, `@required`), and its own through the field's block,
`<field.Control @variant="card" />`. Attributes on
`field.Control` go on the control's focusable element (an input, a select's trigger, a
combobox's input, a date picker's button), or, for a control made of several (a radio group,
checkbox group, toggle group, slider or rating), on the element around them: the Radio Group's
or Toggle Group's root, the checkboxes' `FieldGroup`, or the Slider's or Rating's root.

## Typed controls

Importing `@ember-joinery/formwright` declares these names to Formwright's types, so Glint checks
each field against its control: the path must hold what the control stores (the Stores column),
and the field and its `field.Control` take only that control's arguments. `@control="switch"` on a
string path, `@control="rating"` on a `number` that can't be `null`, or `@rows` on a switch's
control are type errors. The names are declared whichever `registerJoineryControls({ only, except })`
registers; a name you leave out to keep Formwright's own control is still typed as Joinery's. Under
a name of your own, declare it as Formwright's
[Custom controls](https://joegaudet.com/ember-formwright/guide/controls/custom-controls.md) page
shows.

The [Forms](/formwright/forms.md) page shows the input, textarea, select, checkbox, checkbox
group, radio group and switch, each in one of upstream's forms. Joinery's other inputs follow.

## Slider

A `slider` field stores a number; a `range` field, or a slider whose value is a list, one number
for each thumb. `@min`, `@max` (0 to 100 by default) and `@step` bound it. A `<label>` can't
name a `role="slider"`, so each thumb is named after the field's label (`Price, Minimum`). The
thumbs take the focus, so each carries what a field gives its control: the hint and errors
describe it (`aria-describedby`), it is `aria-invalid` while the field is, and the first has
the field's id, so a failed submit focuses it. Attributes on `field.Control` go on the
Slider's root, so a class sizes it.

<Example @name="formwright-slider" @title="Slider" />

| Argument         | On `field.Control`                       |
| ---------------- | ---------------------------------------- |
| `@orientation`   | `horizontal` (the default) or `vertical` |
| `@onValueCommit` | Called once a drag or a key press ends   |

## Rating

A `rating` field stores the rating picked, a number from `@step` (1 by default; `0.5` gives half
stars) to `@max` (5 by default), or `null` for none: picking the rating already picked clears
it. Each star is a native radio, so the arrow keys move between them and pick, and the stars are
one tab stop. A `<label>` can't name the Rating's `<fieldset role="radiogroup">`, so the group
is named after the field's label (`aria-label`), and it is the field's one group: the field is a
`Field`, not a `FieldSet` around a second, unnamed group. The radios take the focus, so each
carries what a field gives its control: the hint and errors describe it, it is `aria-invalid`
while the field is, and a failed submit focuses the first. Read-only, the stars show the
rating and take the focus but can't change it (`aria-readonly`). Attributes on `field.Control`
go on the Rating's root.

<Example @name="formwright-rating" @title="Rating" />

| Argument     | On `field.Control`                                                |
| ------------ | ----------------------------------------------------------------- |
| `@size`      | `sm` (16px stars), `default` (20px) or `lg` (24px), as Rating's   |
| `@icon`      | The star: a `lucide` icon (lucide's `Star` by default)            |
| `@itemLabel` | Each star's name for assistive technology: `(value) => '3 stars'` |

## Toggle Group and Toggle

A `toggle-group` field stores the option pressed, or, when its value is a list (or with
`@multiple`), the options pressed. It is a group control, so its field is a `FieldSet` and its
legend names the group. A `toggle` field stores whether it is pressed, and shows its block (or
its label). With a block, each toggle group item is named by its option's label, so an icon
alone has a name.

<Example @name="formwright-toggle-group" @title="Toggle Group" />

| Argument                                        | On `field.Control`                    |
| ----------------------------------------------- | ------------------------------------- |
| `@multiple`                                     | Toggle group: several pressed at once |
| `@variant`, `@size`, `@spacing`, `@orientation` | As Toggle Group's and Toggle's        |

## Input OTP

An `input-otp` field stores the code, in `@maxLength` slots (6 by default). `@groups` splits the
slots with a separator (`(array 3 3)`), `@pattern` limits what they take
(`REGEXP_ONLY_DIGITS`), and a block lays them out with Input OTP's own parts.

<Example @name="formwright-input-otp" @title="Input OTP" />

## Combobox

A `combobox` field filters its `@options` by label as you type, and stores the one chosen.

<Example @name="formwright-combobox" @title="Combobox" />

| Argument     | On `field.Control`                                         |
| ------------ | ---------------------------------------------------------- |
| `@emptyText` | What the list says when nothing matches: `No items found.` |
| `@showClear` | Shows a button that clears the choice                      |

## Date Picker

A `date-picker` field is upstream's Date Picker, an outline Button that opens a Popover with a
Calendar. It stores the day picked, a `Date` at local midnight, and closes. Its button writes
the date as Intl's long date in the field's `@locale`.

<Example @name="formwright-date-picker" @title="Date Picker" />

| Argument                   | On `field.Control`                                       |
| -------------------------- | -------------------------------------------------------- |
| `@formatDate`              | How the button writes the date: `(date) => string`       |
| `@disabledDays`            | The days that can't be picked, as Calendar's `@disabled` |
| `@captionLayout`           | `dropdown` picks the month and year from lists           |
| `@startMonth`, `@endMonth` | The months the calendar shows                            |

## Native Select, Number and Currency

A `native-select` field is a native `<select>` of its `@options` after an empty one that shows
`@placeholder`. `number` stores a number, and `currency` (Formwright's own control, drawn as
Joinery's Input) a number it shows formatted in `@currency` and `@locale`.

<Example @name="formwright-native-select" @title="Native Select" />

## Input and Textarea in an Input Group

The input and textarea controls render as an [Input Group](/components/input-group.md)'s own
when you give them the group's parts, `@group`: the group's focus and invalid rings then go
around all of it, as the [demo](/formwright/forms.md#demo)'s count and the
[array](/formwright/forms.md#array-fields)'s remove button show. A textarea field's
`@showCount`, which Formwright's own textarea shows as a count after it, does this for you: the
textarea goes in an Input Group with its length (and `@maxLength`) in an addon under it,
announced as it changes (`aria-live="polite"`, and Formwright's `data-test-fw-count`).

| Argument        | On `field.Control`                                                  |
| --------------- | ------------------------------------------------------------------- |
| `@group`        | The parts an `<InputGroup>` yields                                  |
| `@autocomplete` | The control's `autocomplete` (`username`, `email`, `new-password`…) |
| `@rows`         | A textarea's `rows`                                                 |

## Select, Radio Group and Checkbox Group

| Argument             | Control                             | On `field.Control`                                             |
| -------------------- | ----------------------------------- | -------------------------------------------------------------- |
| `@position`          | `select`                            | `item-aligned` (the default) or `popper`                       |
| `@size`              | `select`, `native-select`, `switch` | The component's `@size`                                        |
| a block              | `select`                            | The items, with the Select's parts (`s.Item`, `s.Separator`)   |
| `@variant`           | `radio`                             | `list` (the default) or `card`                                 |
| `@optionDescription` | `radio`, `checkbox-group`           | Each option's description: a key or a function (`description`) |

## Not here

Joinery's opt-in add-ons on Formwright's libraries (File Upload, Rich Text Editor, Power
Calendar, Masked Input and Phone Input) aren't registered as controls: Formwright's own add-on
packages already offer each, and this package takes no dependency on Joinery's add-ons.

Nor is one of Joinery's own inputs, **FileDrop**. It keeps no value: it hands the files dropped
or picked to `@onFiles`, and shows nothing of them. Its root is the `<label>` of its own hidden
file input, which a field's label would repeat. A control would have to keep the files and list
them, which is what Joinery's File Upload add-on does; Formwright's own file-upload add-on is
the Formwright control for that.

## Upstream

shadcn/ui has no such controls; its forms write each Joinery component into a `Controller` by
hand. See [Forms](/formwright/forms.md).
