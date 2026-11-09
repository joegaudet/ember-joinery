/** An element's text, whitespace collapsed. */
export function textOf(element: Element): string {
  return (element.textContent ?? '').replace(/\s+/g, ' ').trim()
}

/** A label's text, without the text of the control it wraps (a choice card's own mark). */
function labelText(label: HTMLLabelElement, control: Element): string {
  if (!label.contains(control)) return textOf(label)
  const copy = label.cloneNode(true) as HTMLLabelElement
  const path: number[] = []
  for (let node: Element | null = control; node && node !== label; node = node.parentElement) {
    path.unshift([...node.parentElement!.children].indexOf(node))
  }
  let inCopy: Element = copy
  for (const index of path) inCopy = inCopy.children[index]!
  inCopy.remove()
  return textOf(copy)
}

/**
 * A control's accessible name, as assistive technology reads it: `aria-label`, else the text of
 * the elements `aria-labelledby` names, else its `<label>`s' text (one tied to it by `for`, or
 * one around it), else its own text.
 */
export function accessibleName(element: HTMLElement): string {
  const label = element.getAttribute('aria-label')
  if (label) return label.trim()
  const labelledBy = element.getAttribute('aria-labelledby')
  if (labelledBy) {
    return labelledBy
      .split(/\s+/)
      .map(id => element.ownerDocument.getElementById(id))
      .filter((found): found is HTMLElement => Boolean(found))
      .map(textOf)
      .join(' ')
  }
  const labels = (element as Partial<HTMLButtonElement>).labels
  if (labels && labels.length) {
    return [...labels]
      .map(found => labelText(found, element))
      .join(' ')
      .trim()
  }
  return textOf(element)
}

/** Whether a control can't be used: `disabled`, or `aria-disabled="true"`. */
export function isDisabled(element: HTMLElement): boolean {
  if ('disabled' in element && (element as HTMLButtonElement).disabled) return true
  return element.getAttribute('aria-disabled') === 'true'
}

/** Whether `aria-invalid` marks it as invalid: any value but `false` (an empty one is false). */
export function isInvalid(element: HTMLElement): boolean {
  const value = element.getAttribute('aria-invalid')
  return value !== null && value !== '' && value !== 'false'
}

/**
 * The hidden native input a checkbox, switch or radio renders beside itself in a form (Radix's
 * "bubble input"), which the form submits, or `null` outside a form.
 */
export function hiddenInputOf(element: HTMLElement): HTMLInputElement | null {
  const next = element.nextElementSibling
  return next instanceof HTMLInputElement && next.getAttribute('aria-hidden') === 'true'
    ? next
    : null
}
