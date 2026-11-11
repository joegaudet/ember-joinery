/**
 * Whether a part is showing: rendered, and laid out. `hidden` hides it only while no CSS gives
 * it another `display`, so this reads the computed `display` rather than the attribute: a part
 * that CSS lays out though it is `hidden` counts as showing.
 */
export function isShowing(element: HTMLElement | null): boolean {
  if (!element?.isConnected) return false
  return getComputedStyle(element).display !== 'none'
}
