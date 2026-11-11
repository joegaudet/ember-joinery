import { InputHarness, NumberHarness } from '@ember-formwright/test-support'

/**
 * A field whose control is Joinery's Input or Textarea: `input`, `text`, `email`, `password`,
 * `search`, `tel`, `url`, `color`, `date`, `datetime`, `time` and `textarea`. It is
 * Formwright's `InputHarness` (`fillIn(text)`, `value`), which drives any native control.
 */
export class InputFieldHarness extends InputHarness {
  static override controls = [
    'input',
    'text',
    'email',
    'password',
    'search',
    'tel',
    'url',
    'color',
    'date',
    'datetime',
    'time',
    'textarea',
  ]

  /** The control's placeholder, or `undefined`. */
  get placeholder(): string | undefined {
    return this.control.getAttribute('placeholder') ?? undefined
  }
}

/** A `number` field: Formwright's `NumberHarness` (`fillIn(n)`, `value: number | null`). */
export class NumberFieldHarness extends NumberHarness {
  static override controls = ['number']
}
