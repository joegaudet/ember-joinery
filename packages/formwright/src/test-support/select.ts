import { FieldHarness } from '@ember-formwright/test-support'
import { SelectHarness } from '@ember-joinery/test-support'

/**
 * A `select` field, Joinery's Select, driven through Joinery's `SelectHarness` (`select`):
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
  get select(): SelectHarness {
    return new SelectHarness({ within: this.element })
  }

  /** The key of the option chosen, or `null` while none is. */
  get value(): string | null {
    return this.select.value || null
  }

  /** What the trigger shows: the chosen option's text, or the placeholder. */
  get text(): string {
    return this.select.valueText
  }

  /** Whether the list is open. */
  get isOpen(): boolean {
    return this.select.isOpen
  }

  /** The key of each option in the list (open it first, with `open()`). */
  get options(): string[] {
    return this.select.options
  }

  /** Opens the list, as a press on the trigger does. */
  async open(): Promise<void> {
    await this.select.open()
  }

  /** Opens the list and chooses the option with this key. */
  async choose(key: string): Promise<void> {
    await this.select.select(key)
  }
}
