# Label

Renders an accessible label associated with controls.

<Example @name="label-demo" @title="Label" />

For form fields, use the Field component, which includes a built-in label, description and
error handling. Field comes with the inputs.

## Installation

```bash
pnpm add @ember-joinery/ember
```

Import Joinery's CSS once (see [Installation](/getting-started/installation.md)), then the
component where you use it:

```gts
import { Label } from '@ember-joinery/ember'
```

## Usage

```gts
<Label for="email">Your email address</Label>
```

It renders a native `<label>`, so tie it to its control with `for` (React's `htmlFor`), or put
the control inside it. A click on the label then focuses or toggles the control.

## Label in Field

For form fields, use the Field component, which includes built-in `FieldLabel`,
`FieldDescription` and `FieldError` components. Field hasn't landed in Joinery yet; its page,
and upstream's example here (`field-demo`, which is mapped on Field's page), come with it.

## Disabled

The label dims when its control is disabled: mark the control with the `peer` class and put it
just before the label (`peer-disabled:opacity-50`), or give an ancestor marked `group` the
attribute `data-disabled="true"` (`group-data-[disabled=true]:opacity-50`). This example is
Joinery's own: its second label does the first, beside a native checkbox.

<Example @name="label-native" @title="Disabled" />

## RTL

The label and its control lay themselves out right to left inside any element with `dir="rtl"`
(see [Direction](/primitives/direction.md)).

<Example @name="label-rtl" @title="RTL" @dir="rtl" />

## API Reference

### Label

| Argument | Type     | Default | What it does                                       |
| -------- | -------- | ------- | -------------------------------------------------- |
| `@as`    | tag name | `label` | The tag to render                                  |
| `@name`  | `string` |         | Its name, for `LabelHarness` (`data-test-jn-name`) |

It yields its block and takes attributes, `for` among them. It is the primitives'
[`Label`](/primitives/label.md) with Joinery's styles: a double click on its text doesn't select
the text.

### The `asLabel` modifier

`{{asLabel name=…}}` makes any element or component a label, as upstream's `asChild` does: the
class, the attributes below and the double-click behaviour. On anything but a `<label>`, name
the control with `aria-labelledby` instead of `for`. `labelClasses()` and
`labelAttributes(options)` return the class and attributes, for code of your own.

### Data attributes

| Attribute           | Value       |
| ------------------- | ----------- |
| `class`             | `jn-label`  |
| `data-slot`         | `label`     |
| `data-test-jn`      | `label`     |
| `data-test-jn-name` | its `@name` |

## Keyboard interactions

A label takes no focus. Its control does, and the browser moves focus to the control when the
label is clicked.

## Accessibility

- A `<label>` tied to its control by `for` (or wrapping it) names the control, and makes the
  label a larger target for the pointer.
- One label names one control. For a group of controls, use a `<fieldset>` and `<legend>`, or
  Field's `FieldSet` when it lands.
- The label dims with a disabled control; the control's own `disabled` is what assistive
  technology reads.

## Testing

`LabelHarness` from `@ember-joinery/test-support` finds a label (`data-test-jn="label"`):

```ts
import { LabelHarness } from '@ember-joinery/test-support'

const email = new LabelHarness('email') // <Label @name="email">
assert.strictEqual(email.text, 'Your email address')
await email.click() // focuses the input it names
```

| Member              | What it is                                                              |
| ------------------- | ----------------------------------------------------------------------- |
| `text`              | The text it shows                                                       |
| `control`           | The control it labels (its `for` element, or the one inside), or `null` |
| `isControlDisabled` | Whether that control is disabled                                        |
| `click()`           | Clicks it, which the browser passes to the control                      |

## Upstream

shadcn/ui's [Label](https://ui.shadcn.com/docs/components/radix/label), from
`apps/v4/registry/bases/radix/ui/label.tsx` at shadcn-ui/ui@8ab2771, in the Nova style, on
Radix's `Label`.
