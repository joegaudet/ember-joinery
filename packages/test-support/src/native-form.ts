import { click, fillIn, select, settled } from '@ember/test-helpers'
import { Harness } from './harness.ts'

type Control = HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement

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
   * Submits it, as a press on its submit button does: the browser checks its constraints
   * first, and a form that fails them doesn't submit.
   */
  async submit(): Promise<void> {
    this.form.requestSubmit()
    await settled()
  }
}
