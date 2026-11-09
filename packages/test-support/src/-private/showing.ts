/** Whether a part is showing: rendered, and neither `hidden` nor `display: none`. */
export function isShowing(element: HTMLElement | null): boolean {
  if (!element || element.hidden) return false
  return getComputedStyle(element).display !== 'none'
}
