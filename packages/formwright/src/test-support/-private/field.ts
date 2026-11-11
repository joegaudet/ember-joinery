import type { FieldHarness } from '@ember-formwright/test-support'

/** The element `selector` finds in a field, or a Formwright-style error naming what's missing. */
export function required<T extends Element>(
  field: FieldHarness,
  selector: string,
  description: string,
): T {
  const element = field.element.querySelector<T>(selector)
  if (!element) throw new Error(`Formwright harness: no ${description} in field "${field.path}"`)
  return element
}

/** A field's option elements (`data-test-fw-option`), in order. */
export function optionElements(field: FieldHarness): HTMLElement[] {
  return [...field.element.querySelectorAll<HTMLElement>('[data-test-fw-option]')]
}

/** The option element with this key. */
export function optionElement(field: FieldHarness, key: string): HTMLElement {
  return required(field, `[data-test-fw-option="${CSS.escape(key)}"]`, `option "${key}"`)
}

/** Whether an option is on: `aria-checked` (checkbox, radio) or `aria-pressed` (toggle). */
export function isOn(element: Element): boolean {
  return (
    element.getAttribute('aria-checked') === 'true' ||
    element.getAttribute('aria-pressed') === 'true'
  )
}
