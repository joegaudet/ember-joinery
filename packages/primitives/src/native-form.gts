import type { TOC } from '@ember/component/template-only'
import { fn } from '@ember/helper'
import { on } from '@ember/modifier'
import { dataFrom, type NativeFormData, type NativeFormValue } from './-private/form-data.ts'

/**
 * A form's data, by field name: what `dataFromEvent` reads out of its `FormData`. A field's
 * value is a string, as a native form's are, but for what it converts, as form-data-utils
 * (which ember-primitives' Form uses) does: a number or range input's number, a date input's
 * `Date`, a checkbox's `true` or `false` without a `value`, a file input's `File` (or
 * `File[]`), several checkboxes' or a multiple select's array, and `null` for a field with
 * nothing chosen.
 */
export type { NativeFormData, NativeFormValue }

/** Which event `@onChange` heard: a field's `input`, or the form's `submit`. */
export type NativeFormEventType = 'input' | 'submit'

/**
 * Reads a form's data out of one of its events, as `<NativeForm>` does: the event's
 * `currentTarget` must be the `<form>`. A submit event's submitter is included, as `FormData`
 * includes it.
 *
 *   <form {{on "submit" this.save}}>…</form>
 *   save = (event: SubmitEvent) => { event.preventDefault(); this.send(dataFromEvent(event)) }
 */
export const dataFromEvent: typeof dataFrom = dataFrom

type OnChange = (data: NativeFormData, eventType: NativeFormEventType, event: Event) => void

function handleInput(onChange: OnChange, event: Event): void {
  onChange(dataFrom(event), 'input', event)
}

function handleSubmit(onChange: OnChange, event: SubmitEvent): void {
  event.preventDefault()
  onChange(dataFrom(event), 'submit', event)
}

export interface NativeFormSignature {
  Args: {
    /**
     * Called whenever a field changes (`input`), and when the form submits (`submit`, whose
     * default, the page load, is prevented), with the form's data, which event it was, and
     * the event itself. Give each control a `name`, as a native form needs.
     */
    onChange: OnChange
    /** Its name, for `NativeFormHarness` (`data-test-jn-name`). */
    name?: string
  }
  Blocks: {
    /** The form's controls. A `<button type="submit">` in it submits it. */
    default: []
  }
  Element: HTMLFormElement
}

/**
 * A native `<form>` that hands you its `FormData` as an object, whenever a field changes and
 * when it submits: ember-primitives' Form, renamed so it can't clash with Formwright's
 * `<Form>`. It is uncontrolled: its controls keep their own values, and only their first
 * values are yours to set.
 *
 *   <NativeForm @onChange={{this.update}}>
 *     <label>First Name <input name="firstName" value={{this.data.firstName}} /></label>
 *   </NativeForm>
 *
 * Every value it reads is a string, as `FormData`'s are, but for those `dataFromEvent`
 * converts (see `NativeFormData`).
 */
export const NativeForm: TOC<NativeFormSignature> = <template>
  <form
    data-test-jn="native-form"
    data-test-jn-name={{@name}}
    ...attributes
    {{on "input" (fn handleInput @onChange)}}
    {{on "submit" (fn handleSubmit @onChange)}}
  >
    {{yield}}
  </form>
</template>

export default NativeForm
