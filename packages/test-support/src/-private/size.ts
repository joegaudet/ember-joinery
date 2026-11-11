/**
 * An element's border box, in CSS pixels, as its styles lay it out: unlike
 * `getBoundingClientRect()`, a transform on the page (the test container's `scale(0.5)`)
 * doesn't change it, and unlike `offsetWidth`, it isn't rounded.
 */
export function borderBox(element: Element): { width: number; height: number } {
  const style = getComputedStyle(element)
  const px = (value: string) => Number.parseFloat(value) || 0
  let width = px(style.width)
  let height = px(style.height)
  if (style.boxSizing !== 'border-box') {
    width +=
      px(style.paddingLeft) +
      px(style.paddingRight) +
      px(style.borderLeftWidth) +
      px(style.borderRightWidth)
    height +=
      px(style.paddingTop) +
      px(style.paddingBottom) +
      px(style.borderTopWidth) +
      px(style.borderBottomWidth)
  }
  return { width, height }
}
