import { click } from '@ember/test-helpers'
import { FieldHarness } from '@ember-formwright/test-support'
import { RadioGroupHarness, ToggleGroupHarness } from '@ember-joinery/test-support'
import { isOn, optionElement, optionElements } from './-private/field.ts'

/** A field of choices, each a `data-test-fw-option` element that reads on or off through ARIA. */
abstract class ChoicesFieldHarness extends FieldHarness {
  /** The key of each option, in order. */
  get options(): string[] {
    return optionElements(this).map(option => option.getAttribute('data-test-fw-option')!)
  }

  /** The keys of the options on, in order. */
  protected get keysOn(): string[] {
    return optionElements(this)
      .filter(isOn)
      .map(option => option.getAttribute('data-test-fw-option')!)
  }

  /**
   * Whether the option with this key can't be chosen, read as assistive technology reads it: a
   * native `disabled` (a button's, or its fieldset's), or `aria-disabled="true"`.
   */
  isOptionDisabled(key: string): boolean {
    const option = optionElement(this, key)
    return option.matches(':disabled') || option.getAttribute('aria-disabled') === 'true'
  }

  /** A press on the option with this key. */
  protected async press(key: string): Promise<void> {
    await click(optionElement(this, key))
  }
}

/**
 * A `checkbox-group` field, Joinery's Checkboxes: `value` (the keys checked), `select(keys)`
 * (exactly those), `toggle(key)`.
 */
export class CheckboxGroupFieldHarness extends ChoicesFieldHarness {
  static override controls = ['checkbox-group']

  /** The keys of the options checked. */
  get value(): string[] {
    return this.keysOn
  }

  /** Checks exactly these keys, and unchecks the rest. */
  async select(keys: string[]): Promise<void> {
    const wanted = new Set(keys)
    for (const option of optionElements(this)) {
      const key = option.getAttribute('data-test-fw-option')!
      if (isOn(option) !== wanted.has(key)) await click(option)
    }
  }

  /** Checks or unchecks one option. */
  async toggle(key: string): Promise<void> {
    await this.press(key)
  }
}

/** A `radio` field, Joinery's Radio Group: `value`, `select(key)`, `options`. */
export class RadioGroupFieldHarness extends ChoicesFieldHarness {
  static override controls = ['radio']

  /** Joinery's harness for the field's Radio Group, for its keyboard (`press('ArrowDown')`). */
  get radioGroup(): RadioGroupHarness {
    return new RadioGroupHarness({ within: this.element })
  }

  /** The key of the option chosen, or `null`. */
  get value(): string | null {
    return this.keysOn[0] ?? null
  }

  /** Chooses the option with this key. */
  async select(key: string): Promise<void> {
    await this.press(key)
  }
}

/**
 * A `toggle-group` field, Joinery's Toggle Group: `value` (the keys pressed), `toggle(key)`,
 * `select(keys)`.
 */
export class ToggleGroupFieldHarness extends ChoicesFieldHarness {
  static override controls = ['toggle-group']

  /** Joinery's harness for the field's Toggle Group, for its keyboard. */
  get toggleGroup(): ToggleGroupHarness {
    return new ToggleGroupHarness({ within: this.element })
  }

  /** The keys of the options pressed, in order. */
  get value(): string[] {
    return this.keysOn
  }

  /** Presses one option: on becomes off, and off on (in a single group, it replaces the one on). */
  async toggle(key: string): Promise<void> {
    await this.press(key)
  }

  /** Presses options until exactly these keys are on. */
  async select(keys: string[]): Promise<void> {
    const wanted = new Set(keys)
    for (const option of optionElements(this)) {
      const key = option.getAttribute('data-test-fw-option')!
      if (isOn(option) !== wanted.has(key)) await click(option)
    }
  }
}
