import { FieldHarness } from '@ember-formwright/test-support'
import { SelectHarness } from '@ember-joinery/test-support'

/**
 * A `select` field, Joinery's Select, driven through Joinery's `SelectHarness`
 * (`selectHarness`). It reads and acts as Formwright's own `SelectHarness` does (`select(key)`,
 * `value`, `options`), so a test that drove Formwright's native select drives Joinery's with
 * the harness swapped:
 *
 *   class LanguageForm extends FormHarness {
 *     @field(SelectFieldHarness) declare language: SelectFieldHarness
 *   }
 *
 *   await form.language.select('en')
 *   assert.strictEqual(form.language.value, 'en')
 *   assert.strictEqual(form.language.text, 'English')
 */
export class SelectFieldHarness extends FieldHarness {
  static override controls = ['select']

  /** Joinery's harness for the field's Select: its trigger, list and options. */
  get selectHarness(): SelectHarness {
    return new SelectHarness({ within: this.element })
  }

  /** The key of the option chosen, or `null` while none is. */
  get value(): string | null {
    return this.selectHarness.value || null
  }

  /** What the trigger shows: the chosen option's text, or the placeholder. */
  get text(): string {
    return this.selectHarness.valueText
  }

  /** Whether the list is open. */
  get isOpen(): boolean {
    return this.selectHarness.isOpen
  }

  /** The key of each option in the list (open it first, with `open()`). */
  get options(): string[] {
    return this.selectHarness.options
  }

  /** Opens the list, as a press on the trigger does. */
  async open(): Promise<void> {
    await this.selectHarness.open()
  }

  /** Opens the list and chooses the option with this key, as Formwright's `select(key)`. */
  async select(key: string): Promise<void> {
    await this.selectHarness.select(key)
  }
}
