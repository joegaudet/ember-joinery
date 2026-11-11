import { FieldHarness } from '@ember-formwright/test-support'
import { InputOTPHarness } from '@ember-joinery/test-support'

/** An `input-otp` field, Joinery's Input OTP: `value`, `fillIn(code)`, `typeIn(text)`, `paste(text)`. */
export class InputOTPFieldHarness extends FieldHarness {
  static override controls = ['input-otp']

  /** Joinery's harness for the field's Input OTP: its slots and keys. */
  get otp(): InputOTPHarness {
    return new InputOTPHarness({ within: this.element })
  }

  /** The code entered so far. */
  get value(): string {
    return this.otp.value
  }

  /** Whether every slot is filled. */
  get isComplete(): boolean {
    return this.otp.isComplete
  }

  /** Replaces the code, as Formwright's `fillIn` does an input's. */
  async fillIn(code: string): Promise<void> {
    await this.otp.fillIn(code)
  }

  /** Types characters one at a time, as a user does. */
  async typeIn(text: string): Promise<void> {
    await this.otp.typeIn(text)
  }

  /** Pastes text into it. */
  async paste(text: string): Promise<void> {
    await this.otp.paste(text)
  }
}
