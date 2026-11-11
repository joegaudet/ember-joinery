# Field Layout

`JoineryFieldLayout` is a Formwright field layout that sets each field out as shadcn's
[Field](/components/field.md): a `Field` (`role="group"`, `data-slot="field"`,
`data-orientation`, `data-invalid`, `data-disabled`) around a `FieldLabel`, the control, a
`FieldDescription` (the field's `@hint`) and a `FieldError` (its errors, while it has any). A
group control (`radio`, `checkbox-group`, `toggle-group`) is a `FieldSet` under a `FieldLegend`.

Formwright's parts keep their own ids, `aria-*` and `data-test-fw-*` attributes, so Formwright's
harnesses read the field as they always do; the layout adds Joinery's classes, `data-slot`s and
`data-test-jn-*` to them.

## Orientation

Each control has the orientation upstream's examples give it: a checkbox before its label, a
switch and a toggle after their label and hint (in a `FieldContent`), and the rest stacked. A
form's or a field's `@layout` picks another:

| `@layout`            | Sets each field                                                         |
| -------------------- | ----------------------------------------------------------------------- |
| `joinery`            | in its control's orientation (the default, after `setupJoineryForms()`) |
| `joinery-vertical`   | stacked                                                                 |
| `joinery-horizontal` | its label, hint and errors in a `FieldContent`, beside the control      |
| `joinery-responsive` | stacked until its `FieldGroup` is 28rem wide, then side by side         |

`@layout` on a `<Form>` holds for its fields and its nested forms, and on an `<f.Field>` for that
field. For a field's own options, give the layout component them:

```gts
import { JoineryFieldLayout } from '@ember-joinery/formwright'

<f.Field
  @for="tasks"
  @control="checkbox-group"
  @label="Tasks"
  @layout={{component JoineryFieldLayout legend="label"}}
/>
```

| Argument        | What it does                                                                                     |
| --------------- | ------------------------------------------------------------------------------------------------ |
| `@orientation`  | `vertical`, `horizontal` or `responsive`, as above                                               |
| `@controlFirst` | In a horizontal field, the control before its label (a checkbox's default) or after (the rest's) |
| `@legend`       | A group's legend, as FieldLegend's `@variant`: `legend` (the default) or `label`                 |
| `@labelClass`   | Classes for the label or legend, as upstream gives a checkbox's label `font-normal`              |

The [Select](/formwright/forms.md#select) example is responsive, the [Switch](/formwright/forms.md#switch)
example horizontal, and the [Checkbox](/formwright/forms.md#checkbox) example's group has a
`label` legend.

## Your own layout

A layout is a component that places the parts Formwright gives it (`@parts.Label`, `Hint`,
`Control`, `Errors`, `Group`) and reads the field's state (`@field.isInvalid`,
`@field.disabled`, `@field.controlName`). Joinery's part modifiers draw each in shadcn's anatomy,
and `asFieldErrors` makes the error region a `FieldError`:

```gts
import type { TOC } from '@ember/component/template-only'
import type { FieldLayoutSignature } from '@ember-formwright/ember'
import { asField, asFieldContent } from '@ember-joinery/ember'
import { asFieldErrors } from '@ember-joinery/formwright'

const EmailLayout: TOC<FieldLayoutSignature> = <template>
  <div {{asField orientation="horizontal" invalid=@field.isInvalid}}>
    <div {{asFieldContent}}>
      <@parts.Control as |control|>{{yield control}}</@parts.Control>
      {{#if @field.isInvalid}}
        <@parts.Errors {{asFieldErrors}} />
      {{/if}}
    </div>
  </div>
</template>
```

The [Array Fields](/formwright/forms.md#array-fields) example sets each address out with that
one. Render the errors only while the field is invalid, as `JoineryFieldLayout` does: an empty
region would take a place in the field, and move its description's spacing.

## How it fits

Formwright wraps each field in a `div.fw-field` and each control in a `div.fw-control-area`,
which upstream's Field has no such boxes for. Joinery's CSS (`formwright.css` in `joinery.css`)
takes both out of the box tree (`display: contents`, but for a control in a callout, which is a
popover) and restates the Field's rules for the elements directly inside it one wrapper down:
a vertical field stretches its control, a responsive one sizes it to its content once wide, a
checkbox beside a `FieldContent` comes down a pixel, and a `FieldSet` of checkboxes or radios
sets them closer. So a field looks as upstream's does in every style.

Formwright's inline and confirm modes (`@inline`, `@requireConfirm`) keep Formwright's own
markup for the value shown and the ✔ and ✘ buttons, which Joinery doesn't style. In an inline
form's callout (`@callout`), which is a popover, the controls with floating parts of their own
(Select, Combobox, Date Picker) need nothing of Formwright's `@callout`: their lists and calendar
open in the top layer above the callout, as popovers inside it, so picking in them leaves the
callout open.

## API Reference

| Export                                                                  | What it is                                                                          |
| ----------------------------------------------------------------------- | ----------------------------------------------------------------------------------- |
| `JoineryFieldLayout`                                                    | The layout, with the arguments above                                                |
| `VerticalFieldLayout`, `HorizontalFieldLayout`, `ResponsiveFieldLayout` | The layout in one orientation, whatever the control                                 |
| `registerJoineryLayouts()`                                              | Registers `joinery`, `joinery-vertical`, `joinery-horizontal`, `joinery-responsive` |
| `setupJoineryForms(options?)`                                           | Registers every control and layout, and makes `joinery` the default                 |
| `asFieldErrors`                                                         | Makes a layout's `@parts.Errors` shadcn's FieldError                                |

## Upstream

shadcn's [Field](https://ui.shadcn.com/docs/components/radix/field), as its form guides write it
by hand around each control.
