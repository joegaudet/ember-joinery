import { Harness } from './harness.ts'
import { textOf } from './-private/checkable.ts'

/** The nearest field-family root an element is in: a field, field set or field group. */
function fieldOf(element: Element): Element | null {
  return element.closest('[data-test-jn="field"]')
}

/**
 * Drives a `<Field>` from `@ember-joinery/ember`: reads its label, description and error, and
 * its state, and finds the control inside it with `find()`.
 *
 *   const email = new FieldHarness('email') // <Field @name="email">
 *   assert.strictEqual(email.label, 'Email')
 *   assert.strictEqual(email.error, 'Enter a valid email address.')
 *   assert.true(email.isInvalid)
 *   await email.find(InputHarness).fillIn('ada@example.com')
 */
export class FieldHarness extends Harness {
  static override component = 'field'

  /** All the text it shows, whitespace collapsed. */
  get text(): string {
    return textOf(this.element)
  }

  /**
   * Its label: the `<FieldLabel>` or `<FieldTitle>` in it (both are `data-slot="field-label"`),
   * not one in a field inside it; else a plain `<Label>` or `<label>` in it; else the
   * `<FieldLabel>` around it, as in a choice card. `null` when it has none.
   */
  get labelElement(): HTMLElement | null {
    const root = this.element
    const own = (selector: string) =>
      [...root.querySelectorAll<HTMLElement>(selector)].find(element => fieldOf(element) === root)
    return (
      own('[data-slot="field-label"]') ??
      own('label') ??
      root.parentElement?.closest<HTMLElement>('[data-slot="field-label"]') ??
      null
    )
  }

  /** Its label's text, or `''` without one. */
  get label(): string {
    const label = this.labelElement
    return label ? textOf(label) : ''
  }

  /** The control its `<FieldLabel>` labels, as the browser works it out, or `null`. */
  get control(): HTMLElement | null {
    const label = this.labelElement
    return label instanceof HTMLLabelElement ? label.control : null
  }

  /** Each `<FieldDescription>`'s text, in order. */
  get descriptions(): string[] {
    return this.parts('description').map(textOf)
  }

  /** Its descriptions' text, joined with a space, or `''` without one. */
  get description(): string {
    return this.descriptions.join(' ')
  }

  /** Its `<FieldError>`, while one shows, or `null`. */
  get errorElement(): HTMLElement | null {
    return this.queryPart('error')
  }

  /** The error it shows, or `''` without one: a list of errors' text, joined with a space. */
  get error(): string {
    const error = this.errorElement
    return error ? textOf(error) : ''
  }

  /** Each error it shows: one, or each item of the list `@errors` renders for several. */
  get errors(): string[] {
    const error = this.errorElement
    if (!error) return []
    const items = [...error.querySelectorAll('li')]
    return items.length ? items.map(textOf) : [textOf(error)]
  }

  /** Whether it is in its error state (`data-invalid="true"`). */
  get isInvalid(): boolean {
    return this.element.getAttribute('data-invalid') === 'true'
  }

  /** Whether it shows as disabled (`data-disabled="true"`). */
  get isDisabled(): boolean {
    return this.element.getAttribute('data-disabled') === 'true'
  }

  /** `vertical`, `horizontal` or `responsive` (`data-orientation`). */
  get orientation(): string | null {
    return this.element.getAttribute('data-orientation')
  }

  /** Its `<FieldContent>`, or `null`. */
  get content(): HTMLElement | null {
    return this.queryPart('content')
  }

  /** Its `<FieldTitle>`'s text, or `''` without one. */
  get title(): string {
    const title = this.queryPart('title')
    return title ? textOf(title) : ''
  }
}

/**
 * Drives a `<FieldSet>` from `@ember-joinery/ember`: its legend and description, and the
 * fields in it.
 *
 *   const address = new FieldSetHarness('address') // <FieldSet @name="address">
 *   assert.strictEqual(address.legend, 'Address Information')
 *   assert.deepEqual(address.fields.map(field => field.label), ['Street Address', 'City'])
 */
export class FieldSetHarness extends Harness {
  static override component = 'field-set'

  /** All the text it shows, whitespace collapsed. */
  get text(): string {
    return textOf(this.element)
  }

  /** Its `<FieldLegend>`'s text, or `''` without one. */
  get legend(): string {
    const legend = this.queryPart('legend')
    return legend ? textOf(legend) : ''
  }

  /** Its legend's `@variant`: `legend` or `label`, or `null` without a legend. */
  get legendVariant(): string | null {
    return this.queryPart('legend')?.getAttribute('data-variant') ?? null
  }

  /** Its own `<FieldDescription>`s' text, joined with a space (not its fields'). */
  get description(): string {
    return this.parts('description').map(textOf).join(' ')
  }

  /** A harness for each field in it, in order, nested ones included. */
  get fields(): FieldHarness[] {
    return this.findAll(FieldHarness)
  }

  /** Whether it is disabled, which disables every control in it (`<fieldset disabled>`). */
  get isDisabled(): boolean {
    return this.element.matches(':disabled')
  }
}

/**
 * Drives a `<FieldGroup>` from `@ember-joinery/ember`: the fields in it and the text of its
 * separators.
 *
 *   const group = new FieldGroupHarness()
 *   assert.deepEqual(group.separators, ['Or continue with'])
 */
export class FieldGroupHarness extends Harness {
  static override component = 'field-group'

  /** A harness for each field in it, in order, nested ones included. */
  get fields(): FieldHarness[] {
    return this.findAll(FieldHarness)
  }

  /** A harness for each field set in it, in order. */
  get fieldSets(): FieldSetHarness[] {
    return this.findAll(FieldSetHarness)
  }

  /** Each `<FieldSeparator>`'s text, in order: `''` for a plain line. */
  get separators(): string[] {
    return this.parts('separator').map(textOf)
  }
}
