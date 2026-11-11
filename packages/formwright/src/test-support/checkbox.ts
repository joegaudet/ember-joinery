import { FieldHarness } from '@ember-formwright/test-support'
import { CheckboxHarness, SwitchHarness, ToggleHarness } from '@ember-joinery/test-support'

/** A `checkbox` field, Joinery's Checkbox: `value`, `check()`, `uncheck()`, `toggle()`. */
export class CheckboxFieldHarness extends FieldHarness {
  static override controls = ['checkbox']

  /** Joinery's harness for the field's Checkbox. */
  get checkbox(): CheckboxHarness {
    return new CheckboxHarness({ within: this.element })
  }

  /** Whether it is checked (`aria-checked`). */
  get value(): boolean {
    return this.checkbox.isChecked
  }

  async check(): Promise<void> {
    await this.checkbox.check()
  }

  async uncheck(): Promise<void> {
    await this.checkbox.uncheck()
  }

  async toggle(): Promise<void> {
    await this.checkbox.toggle()
  }
}

/** A `switch` field, Joinery's Switch: `value`, `check()`, `uncheck()`, `toggle()`. */
export class SwitchFieldHarness extends FieldHarness {
  static override controls = ['switch']

  /** Joinery's harness for the field's Switch. */
  get switch(): SwitchHarness {
    return new SwitchHarness({ within: this.element })
  }

  /** Whether it is on (`aria-checked`). */
  get value(): boolean {
    return this.switch.isChecked
  }

  async check(): Promise<void> {
    await this.switch.check()
  }

  async uncheck(): Promise<void> {
    await this.switch.uncheck()
  }

  async toggle(): Promise<void> {
    await this.switch.toggle()
  }
}

/** A `toggle` field, Joinery's Toggle: `value` (pressed), `toggle()`. */
export class ToggleFieldHarness extends FieldHarness {
  static override controls = ['toggle']

  /** Joinery's harness for the field's Toggle. */
  get toggleButton(): ToggleHarness {
    return new ToggleHarness({ within: this.element })
  }

  /** Whether it is pressed (`aria-pressed`). */
  get value(): boolean {
    return this.toggleButton.isPressed
  }

  async toggle(): Promise<void> {
    await this.toggleButton.toggle()
  }
}
