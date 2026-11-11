# Forms

Build forms in Ember with Formwright and Zod, in Joinery's Field anatomy: upstream's
[React Hook Form](https://ui.shadcn.com/docs/forms/react-hook-form) guide, and its forms, on
Formwright.

Upstream builds most of its forms three times, once for each library (React Hook Form, TanStack
Form and Formisch). Those are the same form each time, so each is built once here, on
Formwright, and each example names the upstream ones it rebuilds. Its two Next.js forms, which
submit to a server action, are forms of their own (`form-next-demo` and `form-next-complex`),
and each has its own example here, under [Submitting](#submitting).

## Demo

We are going to build the following form. It has a simple text input and a textarea. On submit,
the form data is validated and any errors are displayed.

<div class="callout">

**Note:** Formwright's `<form>` has `novalidate`, so the browser's own validation stays out of
the way and the schema's errors show, as upstream's demo does on purpose. Add `required` and
the like to a control for the browser's validation too.

</div>

<Example @name="formwright-demo" @title="Bug Report" />

## Approach

The form uses Formwright for its state, validation and saving, and Joinery for its look:

- Formwright's `<Form>` holds the model and validates it; each `<f.Field>` edits one path of it.
- `setupJoineryForms()` makes each field's control a Joinery component and sets the field out in
  shadcn's Field anatomy, so there is no `<Controller>` and no `<Field>` to write by hand.
- Client-side validation with any [Standard Schema](https://standardschema.dev): Zod here.

## Anatomy

Here's a field, and what it renders:

```gts
<f.Field
  @for="title"
  @label="Bug Title"
  @placeholder="Login button not working on mobile"
  @hint="Provide a concise title for your bug report."
/>
```

```html
<div role="group" data-slot="field" data-orientation="vertical" data-invalid="true">
  <label data-slot="field-label" for="fw-1">Bug Title</label>
  <input data-slot="input" id="fw-1" aria-invalid="true" aria-describedby="fw-1-hint fw-1-errors" />
  <p data-slot="field-description" id="fw-1-hint">Provide a concise title for your bug report.</p>
  <div data-slot="field-error" role="alert" id="fw-1-errors">…</div>
</div>
```

The error is there only while the field is invalid, as upstream's `fieldState.invalid &&
<FieldError>` is. Formwright's own wrappers around the field and its control are still in the
DOM, with its `data-test-fw-*` attributes, but take no box (`display: contents`).

## Form

### Create a form schema

We'll start by defining the shape of our form using a Zod schema.

<div class="callout">

**Note:** Upstream's examples use zod 3; these use zod 4, which Formwright reads as a Standard
Schema. Any other Standard Schema library works too, or a function returning the errors.

</div>

```ts
import * as z from 'zod'

const formSchema = z.object({
  title: z
    .string()
    .min(5, 'Bug title must be at least 5 characters.')
    .max(32, 'Bug title must be at most 32 characters.'),
  description: z
    .string()
    .min(20, 'Description must be at least 20 characters.')
    .max(100, 'Description must be at most 100 characters.'),
})
```

### Set up the form

Next, give Formwright's `<Form>` the model it edits, the schema, and what to do on submit:

```gts
import Component from '@glimmer/component'
import { Form } from '@ember-formwright/ember'

export default class BugReportForm extends Component {
  model = { title: '', description: '' }

  onSubmit = (data: { title: string; description: string }) => {
    // Do something with the form values.
    console.log(data)
  }

  <template>
    <Form @model={{this.model}} @validator={{formSchema}} @onSubmit={{this.onSubmit}} as |f|>
      {{! Build the form here }}
    </Form>
  </template>
}
```

### Build the form

We can now build the form with `<f.Field>`, which renders the label, the control, the hint and
the errors. A field's block passes arguments to its control (`<field.Control @rows={{6}} />`),
or puts it in an [Input Group](/components/input-group.md) with a count beside it.

```gts
<FieldGroup>
  <f.Field @for="title" @label="Bug Title" @placeholder="Login button not working on mobile" />
  <f.Field @for="description" @control="textarea" @label="Description" as |field|>
    <InputGroup as |g|>
      <field.Control @group={{g}} @rows={{6}} class="min-h-24 resize-none" />
      <g.Addon @align="block-end">
        <g.Text class="tabular-nums">{{field.value.length}}/100 characters</g.Text>
      </g.Addon>
    </InputGroup>
  </f.Field>
</FieldGroup>
<f.Reset {{asButton variant="outline"}}>Reset</f.Reset>
<f.Submit {{asButton}}>Submit</f.Submit>
```

### Done

That's it. You now have a fully accessible form with client-side validation.

When you submit the form, `@onSubmit` is called with the model, once it is valid. If it isn't,
each field shows its errors, and focus moves to the first invalid control.

## Validation

### Client-side Validation

Formwright validates the model with the schema you give `@validator`: a Standard Schema (Zod,
Valibot, ArkType…), or a function from the model to its errors.

```ts
const validate = (model: { title: string }) => (model.title ? {} : { title: ['Enter a title.'] })
```

### When it validates

Formwright validates on submit, as React Hook Form's default `onSubmit` mode does. After a
failed submit it validates again on every change, so each error clears as it is fixed.
Formwright has no other modes; `@onChange` hears each change, to validate a field of your own
sooner.

## Displaying Errors

Each field shows its errors itself: the layout marks the field `data-invalid`, the control
`aria-invalid`, and renders a `FieldError` (`role="alert"`) under it, which the control's
`aria-describedby` names. One error is a line of text; several (Zod reports every rule a value
breaks) a list. Errors for a path no field shows, such as a list's own, are in `f.state.errors`.

## Working with Different Field Types

### Input

- An input is a field's default control, `@control="input"`, and `email`, `password`, `url` and
  the rest are each its own `type`.
- `@placeholder` and `@hint` go on the input and under it; `@autocomplete` on the field's
  control is the input's `autocomplete`.

<Example @name="formwright-input" @title="Input" />

```gts
<f.Field @for="username" @label="Username" @placeholder="shadcn" as |field|>
  <field.Control @autocomplete="username" />
</f.Field>
```

### Textarea

- A textarea is `@control="textarea"`; a class or `@rows` on the field's control go on it.

<Example @name="formwright-textarea" @title="Textarea" />

```gts
<f.Field @for="about" @control="textarea" @label="More about you" as |field|>
  <field.Control class="min-h-[120px]" />
</f.Field>
```

### Select

- A select is `@control="select"`, Joinery's [Select](/components/select.md), with the field's
  `@options` as its items (`@storeKey` stores each option's key).
- The control's block writes the items, as upstream's do, with the Select's parts.
- `@layout="joinery-responsive"` sets the label and hint beside it once the group is wide.

<Example @name="formwright-select" @title="Select" />

```gts
<f.Field
  @for="language"
  @control="select"
  @label="Spoken Language"
  @options={{spokenLanguages}}
  @storeKey={{true}}
  @layout="joinery-responsive"
  as |field|
>
  <field.Control class="min-w-[120px]" as |s|>
    <s.Item @value="auto">Auto</s.Item>
    <s.Separator />
    {{#each spokenLanguages as |language|}}
      <s.Item @value={{language.value}}>{{language.label}}</s.Item>
    {{/each}}
  </field.Control>
</f.Field>
```

### Checkbox

- One checkbox is `@control="checkbox"`, which stores `true` or `false`, before its label.
- A set of them is `@control="checkbox-group"`, which stores the options checked: a `FieldSet`
  under a legend, its checkboxes a `FieldGroup` with `data-slot="checkbox-group"`, as upstream
  says to write them.

<Example @name="formwright-checkbox" @title="Checkbox" />

```gts
<f.Field
  @for="tasks"
  @control="checkbox-group"
  @label="Tasks"
  @options={{tasks}}
  @storeKey={{true}}
  @layout={{component JoineryFieldLayout legend="label"}}
/>
```

### Radio Group

- A radio group is `@control="radio"`, Joinery's [Radio Group](/components/radio-group.md), in
  a `FieldSet` under a legend.
- `@variant="card"` on its control shows each choice as a card, with each option's description
  (`description`, or `@optionDescription`).

<Example @name="formwright-radiogroup" @title="Radio Group" />

```gts
<f.Field @for="plan" @control="radio" @label="Plan" @options={{plans}} @optionLabel="title" as |field|>
  <field.Control @variant="card" />
</f.Field>
```

### Switch

- A switch is `@control="switch"`, which stores `true` or `false`, after its label and hint.

<Example @name="formwright-switch" @title="Switch" />

```gts
<f.Field @for="twoFactor" @control="switch" @label="Multi-factor authentication" />
```

### Complex Forms

Here is an example of a more complex form with multiple fields and validation.

<Example @name="formwright-complex" @title="Complex Form" />

### Password

A password field with a strength meter, from upstream's registry (no docs page shows it). The
field's block reads its value as it is typed (`field.value`), for the meter and the list.

<Example @name="formwright-password" @title="Password" />

## Resetting the Form

`<f.Reset>` puts every field back to the value it rendered with, or was last saved with (a
model's `rollback()`, where it has one), and clears the errors.

```gts
<f.Reset {{asButton variant="outline"}}>Reset</f.Reset>
```

Upstream's `form.reset()` goes back to its `defaultValues` even after a submit; Formwright's goes
back to what was last saved, so after a submit it keeps what was submitted.

## Array Fields

A list's items are fields at their index (`emails.0.address`), which you add to and remove from
the model as it changes.

<Example @name="formwright-array" @title="Array Fields" />

### Array Field Structure

Wrap the items in a `FieldSet` with a `FieldLegend` and a `FieldDescription`, and render a
field for each, keyed by its index so each field keeps its path:

```gts
<FieldSet class="gap-4">
  <FieldLegend @variant="label">Email Addresses</FieldLegend>
  <FieldDescription>Add up to 5 email addresses where we can contact you.</FieldDescription>
  <FieldGroup class="gap-4">
    {{#each this.model.emails key="@index" as |_email index|}}
      <f.Field @for={{addressPath index}} @control="email" @layout={{EmailLayout}} />
    {{/each}}
  </FieldGroup>
</FieldSet>
```

Each address's field is set out by a [layout](/formwright/layout.md#your-own-layout) of the
example's own, its input and error in a `FieldContent`.

### Adding and Removing Items

Replace the model's list with one more or one fewer item, and `@didReset` puts it back on a
reset:

```ts
append = () => (this.model.emails = [...this.model.emails, { address: '' }])
remove = (index: number) => (this.model.emails = this.model.emails.filter((_, i) => i !== index))
```

### Array Validation

Use Zod's `array` to validate the list and each item; the list's own errors are the form's for
`emails`, in `f.state.errors.emails`.

```ts
const formSchema = z.object({
  emails: z
    .array(z.object({ address: z.string().email('Enter a valid email address.') }))
    .min(1, 'Add at least one email address.')
    .max(5, 'You can add up to 5 email addresses.'),
})
```

## Submitting

Upstream's Next.js forms (`form-next-demo`, `form-next-complex`) submit to a server action:
while it runs, the fields and the button are disabled and the button shows a Spinner, and once
it succeeds a toast says so. Formwright's `@onSubmit` can return a promise: the form waits for
it, `f.state.isSubmitting` is true meanwhile, and `f.Submit` is `aria-busy`. Here is
`form-next-demo`, the bug report submitted that way, which empties once it is saved:

<Example @name="formwright-next-demo" @title="Submitting" />

```gts
<f.Field @for="title" @label="Bug Title" @disabled={{f.state.isSubmitting}} />
<f.Submit {{asButton}} @disabled={{f.state.isSubmitting}}>
  {{#if f.state.isSubmitting}}<Spinner />{{/if}}
  Submit
</f.Submit>
```

Upstream's server checks the schema once the action runs; Formwright checks it before
`@onSubmit`, so an invalid form shows its errors at once and never starts saving.

### A Complex Form, Submitted

`form-next-complex` has the [complex form](#complex-forms)'s fields, but in a card of its own:
it has no header, its billing period starts as Monthly, the plan's legend is a section's
(FieldLegend's default variant), and its footer is one button at the end. While it saves, every
field is disabled; once it is saved, a `Preferences saved` toast says so, and the form keeps
what it saved.

<Example @name="formwright-next-complex" @title="Complex Form, submitted" />

```gts
onSubmit = async () => {
  await savePreferences()
  toast.success('Preferences saved', { description: 'Your subscription plan has been updated.' })
}
```

## Accessibility

- Each control is named by its field's label (`for` and `id`), and a group control's
  `FieldSet` by its legend. A slider's thumbs, which a `<label>` can't name, are named after it
  (`aria-label`).
- A field's hint and, while it is invalid, its errors describe its control
  (`aria-describedby`); the control is `aria-invalid`, and the errors are `role="alert"`, so
  they are announced as they appear. On a slider, each thumb is described and `aria-invalid`,
  as the thumbs are what takes the focus.
- After a failed submit, focus moves to the first invalid control.
- Upstream's array example leaves its inputs unlabelled; this one names them, `Email address 1`.
  Its toast's values scroll from the keyboard (`tabindex="0"`), which upstream's don't.
- A chosen choice card's description is upstream's `--muted-foreground` on the card's 5%
  `--primary` tint, about 4.3:1, under the 4.5:1 WCAG AA asks of its text. Joinery keeps
  upstream's colours; to meet AA, darken it in your CSS:

  ```css
  [data-slot='field-label']:has([aria-checked='true']) [data-slot='field-description'] {
    color: var(--foreground);
  }
  ```

## Testing

Each example's Test tab drives it with Formwright's `FormHarness` and Joinery's field harnesses
(see [Testing](/formwright/testing.md)).

## Upstream

[ui.shadcn.com/docs/forms](https://ui.shadcn.com/docs/forms), from
`apps/v4/content/docs/forms` and `apps/v4/registry/new-york-v4/examples/form-*` at
shadcn-ui/ui@8ab2771.

These examples aren't in the [parity](https://github.com/joegaudet/ember-joinery/blob/main/CONTRIBUTING.md#parity)
comparison yet. Upstream's form examples are new-york-v4 registry examples shown on the
`docs/forms` pages, and `upstream/inventory.json` and the parity reference app cover the
component pages' examples (`examples/radix`, in a radix style) and the charts gallery only, so
there is nothing to map them to. Comparing them needs both to take the `docs/forms` pages'
examples and their new-york-v4 style, as they do the charts, and the reference app to render
each library's (React Hook Form, TanStack Form, Formisch and Next.js's `<Form>`). The plan
records the gap, so it is closed before 1.0.
