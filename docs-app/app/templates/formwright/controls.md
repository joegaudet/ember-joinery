# Controls

Joinery's inputs as Formwright controls (all but Rating and FileDrop; see
[Not here yet](#not-here-yet)). `setupJoineryForms()` (or `registerJoineryControls()`)
registers them, so a field names one with `@control`:

| `@control`                                                                                                      | Joinery component                                 | Stores                                       |
| --------------------------------------------------------------------------------------------------------------- | ------------------------------------------------- | -------------------------------------------- |
| `input` (the default), `text`, `email`, `password`, `search`, `tel`, `url`, `color`, `date`, `datetime`, `time` | [Input](/components/input.md)                     | a string                                     |
| `number`                                                                                                        | [Input](/components/input.md), `type="number"`    | a number, or `null` while empty              |
| `currency`                                                                                                      | Formwright's currency control, as Joinery's Input | a number, shown in `@currency` and `@locale` |
| `textarea`                                                                                                      | [Textarea](/components/textarea.md)               | a string                                     |
| `select`                                                                                                        | [Select](/components/select.md)                   | the option (or its key, `@storeKey`)         |
| `native-select`                                                                                                 | [Native Select](/components/native-select.md)     | the option, or `null`                        |
| `combobox`                                                                                                      | [Combobox](/components/combobox.md)               | the option, or `null`                        |
| `checkbox`                                                                                                      | [Checkbox](/components/checkbox.md)               | `true` or `false`                            |
| `checkbox-group`                                                                                                | a [Checkbox](/components/checkbox.md) per option  | the options checked                          |
| `radio`                                                                                                         | [Radio Group](/components/radio-group.md)         | the option chosen                            |
| `switch`                                                                                                        | [Switch](/components/switch.md)                   | `true` or `false`                            |
| `toggle`                                                                                                        | [Toggle](/components/toggle.md)                   | `true` (pressed) or `false`                  |
| `toggle-group`                                                                                                  | [Toggle Group](/components/toggle-group.md)       | the option pressed, or a list of them        |
| `slider`, `range`                                                                                               | [Slider](/components/slider.md)                   | a number, or a list for a range              |
| `input-otp`                                                                                                     | [Input OTP](/components/input-otp.md)             | the code, a string                           |
| `date-picker`                                                                                                   | [Date Picker](/components/date-picker.md)         | a `Date`, or `null`                          |

Formwright's own names (`input` and its types, `number`, `textarea`, `currency`, `select`,
`checkbox`, `checkbox-group`, `radio` and `range`) render Joinery's component in place of
Formwright's. To keep one of Formwright's, leave it out:

```ts
setupJoineryForms({ except: ['select'] }) // or registerJoineryControls({ only: [...] })
```

Each control is also exported (`SelectControl`, `SwitchControl`…), for `@control={{SelectControl}}`
or `registerControl('language', SelectControl)`, and `joineryControls` lists them by name. A
control takes the field's arguments (`@options`, `@optionKey`, `@optionLabel`, `@storeKey`,
`@placeholder`, `@min`, `@max`, `@step`, `@maxLength`, `@disabled`, `@readonly`, `@required`),
and its own through the field's block, `<field.Control @variant="card" />`; attributes on
`field.Control` go on its focusable element.

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
[array](/formwright/forms.md#array-fields)'s remove button show.

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

## Not here yet

Joinery's opt-in add-ons on Formwright's libraries (File Upload, Rich Text Editor, Power
Calendar, Masked Input and Phone Input) aren't registered as controls: Formwright's own add-on
packages already offer each, and this package takes no dependency on Joinery's add-ons.

Two of Joinery's own inputs aren't controls yet either:

- **Rating.** Its root is a `<fieldset>` of native radios, and the styled Rating passes nothing
  to the radios, which take the focus. So a field's hint, errors and `aria-invalid` couldn't
  reach them, as a slider's once couldn't reach its thumbs, and a group field's `FieldSet` and
  legend would wrap a second, unnamed group. A Rating control has to render the primitive's
  items itself, as the slider control renders its thumbs, naming its group with `aria-label`.
  Until then, pass a control of your own to `@control`.
- **FileDrop.** It keeps no value: it hands the files dropped or picked to `@onFiles`, and
  shows nothing of them. Its root is the `<label>` of its own hidden file input, which a field's
  label would repeat. A control would have to keep the files and list them, which is what
  Joinery's File Upload add-on does; Formwright's own file-upload add-on is the Formwright
  control for that.

## Upstream

shadcn/ui has no such controls; its forms write each Joinery component into a `Controller` by
hand. See [Forms](/formwright/forms.md).
