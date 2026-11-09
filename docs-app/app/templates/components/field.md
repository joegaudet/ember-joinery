# Field

Combine labels, controls, and help text to compose accessible form fields and grouped inputs.

Upstream's first example, `field-demo`, is a payment form whose expiry month and year are
Selects; it comes with Select. The examples below show each part.

## Installation

```bash
pnpm add @ember-joinery/ember lucide
```

Import Joinery's CSS once (see [Installation](/getting-started/installation.md)), then the
parts where you use them:

```gts
import {
  Field,
  FieldContent,
  FieldDescription,
  FieldError,
  FieldGroup,
  FieldLabel,
  FieldLegend,
  FieldSeparator,
  FieldSet,
  FieldTitle,
} from '@ember-joinery/ember'
```

## Usage

```gts
<FieldSet>
  <FieldLegend>Profile</FieldLegend>
  <FieldDescription>This appears on invoices and emails.</FieldDescription>
  <FieldGroup>
    <Field>
      <FieldLabel for="name">Full name</FieldLabel>
      <Input id="name" autocomplete="off" placeholder="Evil Rabbit" />
      <FieldDescription>This appears on invoices and emails.</FieldDescription>
    </Field>
    <Field @invalid={{true}}>
      <FieldLabel for="username">Username</FieldLabel>
      <Input id="username" autocomplete="off" aria-invalid="true" />
      <FieldError>Choose another username.</FieldError>
    </Field>
    <Field @orientation="horizontal">
      <Switch id="newsletter" />
      <FieldLabel for="newsletter">Subscribe to the newsletter</FieldLabel>
    </Field>
  </FieldGroup>
</FieldSet>
```

Each part is a component of its own, as upstream's are, so they nest in any order. Tie a
`FieldLabel` to its control with `for` (React's `htmlFor`).

## Composition

### Field

A single control with label, helper text, and validation.

```text
Field
├── FieldLabel
├── Input / Textarea / Switch / Select
├── FieldDescription
└── FieldError
```

### FieldGroup

Related fields in one group. Use `FieldSeparator` between sections when needed.

```text
FieldGroup
├── Field
│   ├── FieldLabel
│   ├── Input / Textarea / Switch / Select
│   ├── FieldDescription
│   └── FieldError
├── FieldSeparator
└── Field
    ├── FieldLabel
    └── Input / Textarea / Switch / Select
```

### FieldSet

Semantic grouping with a legend and description, usually containing a `FieldGroup`.

```text
FieldSet
├── FieldLegend
├── FieldDescription
└── FieldGroup
    ├── Field
    │   ├── FieldLabel
    │   ├── Input / Textarea / Switch / Select
    │   ├── FieldDescription
    │   └── FieldError
    └── Field
        ├── FieldLabel
        └── Input / Textarea / Switch / Select
```

## Anatomy

The `Field` family is designed for composing accessible forms. A typical field is structured as
follows:

```gts
<Field>
  <FieldLabel for="input-id">Label</FieldLabel>
  {{! Input, Select, Switch, etc. }}
  <FieldDescription>Optional helper text.</FieldDescription>
  <FieldError>Validation message.</FieldError>
</Field>
```

- `Field` is the core wrapper for a single field.
- `FieldContent` is a flex column that groups label and description. Not required if you have
  no description.
- Wrap related fields with `FieldGroup`, and use `FieldSet` with `FieldLegend` for semantic
  grouping.

## Form

Upstream builds forms with `Field` and React Hook Form, TanStack Form or Formisch. Joinery's
forms are [Formwright](/formwright/index.md)'s, whose Field layout uses this anatomy; it comes
with the Formwright bridge. For a form of plain native controls, the primitives'
[Native Form](/primitives/native-form.md) hands you its `FormData` as an object.

## Input

<Example @name="field-input" @title="Input" />

## Textarea

<Example @name="field-textarea" @title="Textarea" />

## Select

Upstream's example labels a Select of departments; it comes with Select. Until then,
[Native Select](/components/native-select.md) works in a `Field` as any native control does.

## Slider

Upstream's example titles a price-range Slider with `FieldTitle`, and shows its two values in
the description; it comes with Slider.

## Fieldset

<Example @name="field-fieldset" @title="Fieldset" />

## Checkbox

<Example @name="field-checkbox" @title="Checkbox" />

## Radio

<Example @name="field-radio" @title="Radio" />

## Switch

<Example @name="field-switch" @title="Switch" />

## Choice Card

Wrap `Field` components inside `FieldLabel` to create selectable field groups. This works with
`RadioGroup`'s items, `Checkbox` and `Switch` components.

<Example @name="field-choice-card" @title="Choice Card" />

## Field Group

Stack `Field` components with `FieldGroup`. Add `FieldSeparator` to divide them.

<Example @name="field-group" @title="Field Group" />

## RTL

Every part lays itself out right to left inside any element with `dir="rtl"` (see
[Direction](/primitives/direction.md)). Upstream's right-to-left example is `field-demo` in
Arabic, with its Selects; it comes with Select.

## Responsive Layout

- **Vertical fields:** Default orientation stacks label, control, and helper text, ideal for
  mobile-first layouts.
- **Horizontal fields:** Set `@orientation="horizontal"` on `Field` to align the label and
  control side-by-side. Pair with `FieldContent` to keep descriptions aligned.
- **Responsive fields:** Set `@orientation="responsive"` for automatic column layouts inside
  container-aware parents. `FieldGroup` is the container (`@container/field-group`): a
  responsive field sits side by side once its group is at least 28rem wide.

<Example @name="field-responsive" @title="Responsive Layout" />

## Validation and Errors

- Give `Field` `@invalid={{true}}` to switch the entire block into an error state (upstream's
  `data-invalid`; `data-invalid="true"` works too).
- Add `aria-invalid="true"` on the control itself for assistive technologies.
- Render `FieldError` immediately after the control or inside `FieldContent` to keep error
  messages aligned with the field.

```gts
<Field @invalid={{true}}>
  <FieldLabel for="email">Email</FieldLabel>
  <Input id="email" type="email" aria-invalid="true" />
  <FieldError>Enter a valid email address.</FieldError>
</Field>
```

## API Reference

### FieldSet

Container that renders a semantic `fieldset` with spacing presets.

| Argument | Type     | Default    | What it does                                          |
| -------- | -------- | ---------- | ----------------------------------------------------- |
| `@as`    | tag name | `fieldset` | The tag to render                                     |
| `@name`  | `string` |            | Its name, for `FieldSetHarness` (`data-test-jn-name`) |

```gts
<FieldSet>
  <FieldLegend>Delivery</FieldLegend>
  <FieldGroup>{{! Fields }}</FieldGroup>
</FieldSet>
```

Give it `disabled` to disable every control in it, as any `<fieldset>`.

### FieldLegend

Legend element for a `FieldSet`. Switch to the `label` variant to align with label sizing.

| Argument   | Type                  | Default  | What it does      |
| ---------- | --------------------- | -------- | ----------------- |
| `@variant` | `"legend" \| "label"` | `legend` | How it is set     |
| `@as`      | tag name              | `legend` | The tag to render |

```gts
<FieldLegend @variant="label">Notification Preferences</FieldLegend>
```

The `label` variant applies label sizing and alignment. Handy if you have nested `FieldSet`s.

### FieldGroup

Layout wrapper that stacks `Field` components and enables container queries for responsive
orientations.

| Argument | Type     | Default | What it does                                            |
| -------- | -------- | ------- | ------------------------------------------------------- |
| `@as`    | tag name | `div`   | The tag to render                                       |
| `@name`  | `string` |         | Its name, for `FieldGroupHarness` (`data-test-jn-name`) |

Give it `data-slot="checkbox-group"` for a list of checkboxes, as upstream's examples do, to
set them closer together.

### Field

The core wrapper for a single field. Provides orientation control, invalid state styling, and
spacing.

| Argument       | Type                                         | Default    | What it does                                          |
| -------------- | -------------------------------------------- | ---------- | ----------------------------------------------------- |
| `@orientation` | `"vertical" \| "horizontal" \| "responsive"` | `vertical` | How it lays out its label, control and text           |
| `@invalid`     | `boolean`                                    | `false`    | Its error state (`data-invalid="true"`)               |
| `@disabled`    | `boolean`                                    | `false`    | Dims its labels (`data-disabled="true"`); styles only |
| `@as`          | tag name                                     | `div`      | The tag to render                                     |
| `@name`        | `string`                                     |            | Its name, for `FieldHarness` (`data-test-jn-name`)    |

```gts
<Field @orientation="horizontal">
  <FieldLabel for="remember">Remember me</FieldLabel>
  <Switch id="remember" />
</Field>
```

`@disabled` only styles the field: disable its control too.

### FieldContent

Flex column that groups control and descriptions when the label sits beside the control. Not
required if you have no description.

```gts
<Field>
  <Checkbox id="notifications" />
  <FieldContent>
    <FieldLabel for="notifications">Notifications</FieldLabel>
    <FieldDescription>Email, SMS, and push options.</FieldDescription>
  </FieldContent>
</Field>
```

### FieldLabel

Label styled for both direct inputs and nested `Field` children. It is a
[Label](/components/label.md), so it takes Label's arguments (`@as`, `@name`, for its
`LabelHarness`).

```gts
<FieldLabel for="email">Email</FieldLabel>
```

### FieldTitle

Renders a title with label styling inside `FieldContent`.

```gts
<FieldContent>
  <FieldTitle>Enable Touch ID</FieldTitle>
  <FieldDescription>Unlock your device faster.</FieldDescription>
</FieldContent>
```

### FieldDescription

Helper text slot that automatically balances long lines in horizontal layouts.

```gts
<FieldDescription>We never share your email with anyone.</FieldDescription>
```

### FieldSeparator

Visual divider to separate sections inside a `FieldGroup`. Accepts optional inline content.

```gts
<FieldSeparator>Or continue with</FieldSeparator>
```

### FieldError

Accessible error container that accepts a block or an `@errors` array.

| Argument  | Type                                       | Default | What it does                      |
| --------- | ------------------------------------------ | ------- | --------------------------------- |
| `@errors` | `Array<{ message?: string } \| undefined>` |         | The errors, when there's no block |
| `@as`     | tag name                                   | `div`   | The tag to render                 |

```gts
<FieldError @errors={{this.errors.username}} />
```

When the `@errors` array contains multiple messages, the component renders a list
automatically; a message that repeats shows once, and with no block and no messages it renders
nothing. Any validator's issues with a `message` work, including those of a
[Standard Schema](https://standardschema.dev/) library (Zod, Valibot, ArkType): pass the
`issues` array from the schema result.

### Modifiers

For an element or component of your own, each part with nothing of its own to render has a
modifier that gives it the part's classes and attributes: `asField` (taking `orientation`,
`invalid`, `disabled` and `name`), `asFieldSet`, `asFieldLegend` (`variant`), `asFieldGroup`,
`asFieldContent`, `asFieldLabel`, `asFieldTitle` and `asFieldDescription`.

```gts
<section {{asField orientation="horizontal"}}>…</section>
```

### Data attributes

| Part        | Attribute           | Value                                                        |
| ----------- | ------------------- | ------------------------------------------------------------ |
| field set   | `class`             | `jn-field-set`                                               |
| field set   | `data-slot`         | `field-set`                                                  |
| field set   | `data-test-jn`      | `field-set`                                                  |
| legend      | `class`             | `jn-field-legend`                                            |
| legend      | `data-slot`         | `field-legend`                                               |
| legend      | `data-variant`      | `legend` or `label`                                          |
| legend      | `data-test-jn-part` | `legend`                                                     |
| field group | `class`             | `jn-field-group group/field-group`                           |
| field group | `data-slot`         | `field-group`                                                |
| field group | `data-test-jn`      | `field-group`                                                |
| field       | `role`              | `group`                                                      |
| field       | `class`             | `jn-field group/field jn-field-orientation-<orientation>`    |
| field       | `data-slot`         | `field`                                                      |
| field       | `data-orientation`  | its `@orientation`                                           |
| field       | `data-invalid`      | `true` while `@invalid`                                      |
| field       | `data-disabled`     | `true` while `@disabled`                                     |
| field       | `data-test-jn`      | `field`                                                      |
| content     | `class`             | `jn-field-content group/field-content`                       |
| content     | `data-slot`         | `field-content`                                              |
| content     | `data-test-jn-part` | `content`                                                    |
| label       | `class`             | `jn-label jn-field-label group/field-label peer/field-label` |
| label       | `data-slot`         | `field-label`                                                |
| label       | `data-test-jn`      | `label`                                                      |
| title       | `class`             | `jn-field-title`                                             |
| title       | `data-slot`         | `field-label`, as upstream's                                 |
| title       | `data-test-jn-part` | `title`                                                      |
| description | `class`             | `jn-field-description`                                       |
| description | `data-slot`         | `field-description`                                          |
| description | `data-test-jn-part` | `description`                                                |
| separator   | `class`             | `jn-field-separator`                                         |
| separator   | `data-slot`         | `field-separator`                                            |
| separator   | `data-content`      | `true` when it has a block, else `false`                     |
| separator   | `data-test-jn-part` | `separator`                                                  |
| error       | `role`              | `alert`                                                      |
| error       | `class`             | `jn-field-error`                                             |
| error       | `data-slot`         | `field-error`                                                |
| error       | `data-test-jn-part` | `error`                                                      |

A separator's line is a decorative [Separator](/components/separator.md) with the class
`jn-field-separator-line`, and its text a `<span class="jn-field-separator-content"
data-slot="field-separator-content">`. A list of errors is a `<ul class="jn-field-error-list">`.

## Keyboard interactions

Field adds no keys of its own: Tab moves through its controls, and each control keeps its own
keyboard pattern. A press on a `FieldLabel` focuses or toggles the control it is `for`, and a
press anywhere on a choice card chooses it.

## Accessibility

- `FieldSet` and `FieldLegend` keep related controls grouped for keyboard and assistive tech
  users.
- `Field` outputs `role="group"` so nested controls inherit labeling from `FieldLabel` and
  `FieldLegend` when combined.
- Apply `FieldSeparator` sparingly to ensure screen readers encounter clear section
  boundaries.
- `FieldError` has `role="alert"`, so an error is announced as it appears.
- In a choice card, the control's label holds the whole field. Browsers name the control from
  it, but axe can't see a name through the field's `role="group"`, so Joinery's choice-card
  examples also give each control `aria-labelledby`, pointing at its card's `FieldTitle`.
- Sera's field labels come out `leading-snug`, where upstream's are `leading-relaxed`: a field
  label is a Label too, and Joinery's style sheets put the label's line height after the field
  label's, so Joinery restores the field label's, which is `leading-snug` in the other seven
  styles.

## Testing

`FieldHarness`, `FieldSetHarness` and `FieldGroupHarness` from `@ember-joinery/test-support`
read a field, a field set and a field group; find the control inside with `find()`:

```ts
import { FieldHarness, InputHarness } from '@ember-joinery/test-support'

const email = new FieldHarness('email') // <Field @name="email">
assert.strictEqual(email.label, 'Email')
assert.strictEqual(email.error, 'Enter a valid email address.')
assert.true(email.isInvalid)
await email.find(InputHarness).fillIn('ada@example.com')
```

A `FieldLabel` is a Label, so `LabelHarness` drives it.

### FieldHarness

| Member         | What it is                                                                                   |
| -------------- | -------------------------------------------------------------------------------------------- |
| `label`        | Its label's text: its `FieldLabel`, `FieldTitle` or `<label>`, or the `FieldLabel` around it |
| `labelElement` | That label's element, or `null`                                                              |
| `control`      | The control its `FieldLabel` labels, or `null`                                               |
| `description`  | Its descriptions' text, joined                                                               |
| `descriptions` | Each description's text                                                                      |
| `error`        | The error it shows, or `''`                                                                  |
| `errors`       | Each error it shows (one, or each item of a list)                                            |
| `errorElement` | Its `FieldError`, while one shows, or `null`                                                 |
| `isInvalid`    | `data-invalid="true"`                                                                        |
| `isDisabled`   | `data-disabled="true"`                                                                       |
| `orientation`  | `vertical`, `horizontal` or `responsive`                                                     |
| `content`      | Its `FieldContent`, or `null`                                                                |
| `title`        | Its `FieldTitle`'s text, or `''`                                                             |
| `text`         | All the text it shows                                                                        |

### FieldSetHarness

| Member          | What it is                                                 |
| --------------- | ---------------------------------------------------------- |
| `legend`        | Its legend's text, or `''`                                 |
| `legendVariant` | `legend` or `label`, or `null` without a legend            |
| `description`   | Its own descriptions' text, joined (not its fields')       |
| `fields`        | A `FieldHarness` for each field in it                      |
| `isDisabled`    | Whether it is disabled, which disables every control in it |
| `text`          | All the text it shows                                      |

### FieldGroupHarness

| Member       | What it is                                   |
| ------------ | -------------------------------------------- |
| `fields`     | A `FieldHarness` for each field in it        |
| `fieldSets`  | A `FieldSetHarness` for each field set in it |
| `separators` | Each separator's text, `''` for a plain line |

## Upstream

shadcn/ui's [Field](https://ui.shadcn.com/docs/components/radix/field), from
`apps/v4/registry/bases/radix/ui/field.tsx` at shadcn-ui/ui@8ab2771, in the Nova style.
