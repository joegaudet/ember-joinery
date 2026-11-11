# Native Form

A native `<form>` that hands you its `FormData` as an object, whenever a field changes and when
it submits: ember-primitives' Form, renamed so it can't clash with Formwright's `<Form>`. There
is nothing to wire up on the inputs: give each a `name`, and its first value.

<Example @name="native-form-demo" @title="Native Form" />

## Usage

```gts
import { NativeForm } from '@ember-joinery/primitives/native-form'

<template>
  <NativeForm @onChange={{this.update}}>
    <label>First Name <input name="firstName" value={{this.data.firstName}} /></label>
    <button type="submit">Save</button>
  </NativeForm>
</template>
```

`@onChange` is called with the form's data, which event it was (`input` or `submit`), and the
event. A submit's default, the page load, is prevented. The form is uncontrolled: its controls
keep their own values.

Every value is a string, as a native form's are, but for those it converts, as form-data-utils
(which ember-primitives uses) does: a number or range input's number, a date input's `Date`, a
checkbox without a `value` as `true` or `false`, several checkboxes' or a multiple select's
array, a file input's `File` (or `File[]`), and `null` for a field with nothing chosen.
Joinery's Checkbox, Switch and Radio Group take part through their hidden inputs.

`dataFromEvent(event)` reads the same object out of an event of a form of your own (its
`currentTarget` must be the `<form>`).

## API

| Argument    | Type                               | Default | What it does                                            |
| ----------- | ---------------------------------- | ------- | ------------------------------------------------------- |
| `@onChange` | `(data, eventType, event) => void` |         | Called on each field's `input`, and on `submit`         |
| `@name`     | `string`                           |         | Its name, for `NativeFormHarness` (`data-test-jn-name`) |

It takes attributes on its `<form>`, which renders `data-test-jn="native-form"`.
`NativeFormData` and `NativeFormEventType` are its types.

## Keyboard interactions

| Key     | What it does                                                          |
| ------- | --------------------------------------------------------------------- |
| `Enter` | In a single-line field, submits the form (`@onChange` hears `submit`) |
| `Tab`   | Moves between its controls, as in any form                            |

Enter submits through the form's first submit button, which does nothing while it is disabled;
a form without one submits on Enter only when it has a single text field. In a textarea, Enter
is a new line. The browser does all of this, as in any native form.

## Accessibility

It is a native `<form>`, so it is as accessible as the controls you put in it: label each.

## Testing

`NativeFormHarness` from `@ember-joinery/test-support` fills in its fields by name and
submits it, as a user does:

```ts
import { NativeFormHarness } from '@ember-joinery/test-support'

const profile = new NativeFormHarness()
await profile.fillIn('firstName', 'Ada')
await profile.choose('universe', '616')
await profile.submit() // or, from a field: await profile.pressEnter('firstName')
```

| Member                 | What it is                                                     |
| ---------------------- | -------------------------------------------------------------- |
| `form`                 | The `<form>`                                                   |
| `entries`              | Its data as the browser would submit it                        |
| `controls(name)`       | The controls named `name`                                      |
| `fillIn(name, text)`   | Fills in a text field                                          |
| `choose(name, value)`  | Picks a radio                                                  |
| `toggle(name, value?)` | Clicks a checkbox                                              |
| `select(name, value)`  | Selects in a select                                            |
| `submit()`             | Submits it, checking its constraints first, as a submit button |
| `pressEnter(name)`     | Presses Enter in a field, submitting it as the browser does    |

## Upstream

ember-primitives' [Form](https://github.com/universal-ember/ember-primitives/blob/9584c783bae34e6f0b628ec09a1e1f3cbdb4107e/ember-primitives/src/components/form.gts) at
universal-ember/ember-primitives@9584c78 (0.64.2). `dataFromEvent` is ported from
form-data-utils' `dataFrom`, but for a named `<button>`, which counts only as a submitter.
