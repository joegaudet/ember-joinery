import { FieldHarness } from '@ember-formwright/test-support'
import { ComboboxHarness } from '@ember-joinery/test-support'

/**
 * A `combobox` field, Joinery's Combobox: `value` (the input's text), `typeIn(text)` to filter,
 * `select(label)` to choose, `clear()`.
 */
export class ComboboxFieldHarness extends FieldHarness {
  static override controls = ['combobox']

  /** Joinery's harness for the field's Combobox: its input, list and items. */
  get combobox(): ComboboxHarness {
    return new ComboboxHarness({ within: this.element })
  }

  /** What the input shows: the chosen option's label, or what was typed. */
  get value(): string {
    return this.combobox.inputValue
  }

  /** The labels of the items listed now (open it first, with `open()` or `typeIn()`). */
  get items(): string[] {
    return this.combobox.items
  }

  /** Opens the list. */
  async open(): Promise<void> {
    await this.combobox.open()
  }

  /** Types into the input, as a user does, which filters the list. */
  async typeIn(text: string): Promise<void> {
    await this.combobox.type(text)
  }

  /** Opens the list unless it is open, and chooses the item with this label. */
  async select(label: string): Promise<void> {
    await this.combobox.select(label)
  }

  /** Presses the clear button (`@showClear`). */
  async clear(): Promise<void> {
    await this.combobox.clear()
  }
}
