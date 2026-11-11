// What the floating parts' harnesses (popover, tooltip, hover card) read the same way: text,
// names and descriptions through ARIA, and where the anchoring put a part.

/** An element's text, whitespace collapsed. */
export function text(element: Element | null | undefined): string {
  return (element?.textContent ?? '').replace(/\s+/g, ' ').trim()
}

/** The text of the elements an `aria-labelledby` or `aria-describedby` names, joined. */
function referenced(element: Element, attribute: string): string | undefined {
  const ids = element.getAttribute(attribute)
  if (!ids) return undefined
  return ids
    .split(/\s+/)
    .map(id => element.ownerDocument.getElementById(id))
    .filter((found): found is HTMLElement => Boolean(found))
    .map(found => found.getAttribute('aria-label')?.trim() || text(found))
    .join(' ')
}

/** An element's accessible name: `aria-labelledby`'s text, else `aria-label`, else its text. */
export function accessibleName(element: Element): string {
  return (
    referenced(element, 'aria-labelledby') ??
    element.getAttribute('aria-label')?.trim() ??
    text(element)
  )
}

/** An element's accessible description: the text `aria-describedby` names, or `''`. */
export function accessibleDescription(element: Element): string {
  return referenced(element, 'aria-describedby') ?? ''
}

/** Whether an element is shown in the browser's top layer: an open popover. */
export function shownInTopLayer(element: Element | null | undefined): boolean {
  if (!element) return false
  try {
    return element.matches(':popover-open')
  } catch {
    return false
  }
}
