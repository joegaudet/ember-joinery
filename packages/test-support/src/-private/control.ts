/** A native form control a harness reads: an input, a textarea or a select. */
export type FormControl = HTMLInputElement | HTMLTextAreaElement | HTMLSelectElement

/** An element's text, whitespace collapsed. */
export function textOf(element: Element): string {
  return (element.textContent ?? '').replace(/\s+/g, ' ').trim()
}

/** The text of the elements an `aria-labelledby` or `aria-describedby` names, in order. */
function referenced(element: Element, attribute: string): string | undefined {
  const ids = element.getAttribute(attribute)
  if (!ids) return undefined
  return ids
    .split(/\s+/)
    .map(id => element.ownerDocument.getElementById(id))
    .filter((found): found is HTMLElement => Boolean(found))
    .map(textOf)
    .join(' ')
}

/** A `<label>`'s text, leaving out the controls inside it (a label can wrap its control). */
function labelText(label: HTMLLabelElement): string {
  const copy = label.cloneNode(true) as HTMLLabelElement
  for (const control of copy.querySelectorAll('input, select, textarea, button')) control.remove()
  return textOf(copy)
}

/**
 * A control's accessible name, as assistive technology reads it: the text of the elements its
 * `aria-labelledby` names, else its `aria-label`, else its `<label>`s' text (`for`, or one
 * around it), else its `title`, else its `placeholder`.
 */
export function controlLabel(control: FormControl): string {
  const labelledBy = referenced(control, 'aria-labelledby')
  if (labelledBy) return labelledBy
  const label = control.getAttribute('aria-label')?.trim()
  if (label) return label
  const labels = [...(control.labels ?? [])].map(labelText).filter(Boolean)
  if (labels.length) return labels.join(' ')
  const title = control.getAttribute('title')?.trim()
  if (title) return title
  return control.getAttribute('placeholder')?.trim() ?? ''
}

/** The text of the elements a control's `aria-describedby` names, or `''`. */
export function controlDescription(control: FormControl): string {
  return referenced(control, 'aria-describedby') ?? ''
}

/**
 * Whether a control is marked invalid: `aria-invalid` with any value but `false` (an empty
 * `aria-invalid` counts as false, as in ARIA).
 */
export function isMarkedInvalid(control: Element): boolean {
  const invalid = control.getAttribute('aria-invalid')
  return invalid !== null && invalid !== '' && invalid !== 'false'
}
