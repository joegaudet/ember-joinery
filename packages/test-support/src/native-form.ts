import { click, fillIn, focus, select, settled } from '@ember/test-helpers'
import { Harness } from './harness.ts'
import { pressKey } from './focus.ts'

type Control = HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement

/**
 * The input types in which Enter submits the form (HTML's "fields that block implicit
 * submission"): the single-line text and number fields, not checkboxes, radios or buttons.
 */
const SUBMITS_ON_ENTER = new Set([
  'text',
  'search',
  'url',
  'tel',
  'email',
  'password',
  'date',
  'month',
  'week',
  'time',
  'datetime-local',
  'number',
])

function submitsOnEnter(element: Element): element is HTMLInputElement {
  return element instanceof HTMLInputElement && SUBMITS_ON_ENTER.has(element.type)
}

/** A form's default button: its first submit button, as the browser picks it for Enter. */
function defaultButton(form: HTMLFormElement): HTMLButtonElement | HTMLInputElement | undefined {
  return [...form.elements].find(
    (element): element is HTMLButtonElement | HTMLInputElement =>
      (element instanceof HTMLButtonElement && element.type === 'submit') ||
      (element instanceof HTMLInputElement &&
        (element.type === 'submit' || element.type === 'image')),
  )
}

/**
 * Drives a `<NativeForm>` from `@ember-joinery/primitives/native-form`: fills in its fields by
 * their `name`, as a user does, and submits it.
 *
 *   const profile = new NativeFormHarness('profile') // <NativeForm @name="profile">
 *   await profile.fillIn('firstName', 'Ada')
 *   await profile.choose('universe', '616')
 *   await profile.submit()
 */
export class NativeFormHarness extends Harness {
  static override component = 'native-form'

  /** The `<form>`. */
  get form(): HTMLFormElement {
    return this.element as HTMLFormElement
  }

  /** Its data as the browser would submit it: `FormData`'s entries, the last of each name. */
  get entries(): Record<string, FormDataEntryValue> {
    return Object.fromEntries(new FormData(this.form))
  }

  /** The controls named `name`. Throws when there is none. */
  controls(name: string): Control[] {
    const found = [...this.form.elements].filter(
      (element): element is Control =>
        'name' in element && (element as Control).name === name && element.tagName !== 'BUTTON',
    )
    if (!found.length) throw new Error(`Joinery harness: ${this} has no control named "${name}"`)
    return found
  }

  /** Fills in the text field named `name`. */
  async fillIn(name: string, text: string): Promise<void> {
    await fillIn(this.controls(name)[0]!, text)
  }

  /** Picks the radio named `name` whose value is `value`. */
  async choose(name: string, value: string): Promise<void> {
    const radio = this.controls(name).find(control => control.value === value)
    if (!radio) throw new Error(`Joinery harness: ${this} has no "${name}" worth "${value}"`)
    await click(radio)
  }

  /** Clicks the checkbox named `name` (and, given one, whose value is `value`). */
  async toggle(name: string, value?: string): Promise<void> {
    const box = this.controls(name).find(control => value === undefined || control.value === value)
    if (!box) throw new Error(`Joinery harness: ${this} has no "${name}" worth "${value}"`)
    await click(box)
  }

  /** Selects `value` in the select named `name`. */
  async select(name: string, value: string | string[]): Promise<void> {
    await select(this.controls(name)[0]!, value)
  }

  /**
   * Presses Enter in the field named `name`, and does what the browser then does, which a
   * test's key events don't make it do (as with `tab()`): in a single-line field, unless the
   * keydown was cancelled, it submits the form. That is a click on the form's default button
   * (its first submit button), which does nothing while that button is disabled; without one,
   * the form submits when that field is the only one Enter submits from. In a textarea, a
   * select, a checkbox or a radio, Enter submits nothing.
   */
  async pressEnter(name: string): Promise<void> {
    const control = this.controls(name)[0]!
    await focus(control)
    const prevented = await pressKey('Enter')
    if (prevented || !submitsOnEnter(control)) return
    const button = defaultButton(this.form)
    if (button) {
      if (!button.disabled) await click(button)
      return
    }
    const fields = [...this.form.elements].filter(submitsOnEnter)
    if (fields.length === 1) await this.submit()
  }

  /**
   * Submits it, as a press on its submit button does: the browser checks its constraints
   * first, and a form that fails them doesn't submit.
   */
  async submit(): Promise<void> {
    this.form.requestSubmit()
    await settled()
  }
}
