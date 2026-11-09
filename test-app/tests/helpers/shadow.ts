/** Finishes an element's transitions and animations, so its styles read as they end. */
export function finishTransitions(element: Element): CSSStyleDeclaration {
  for (const animation of element.getAnimations()) {
    // A running caret blinks forever; finishing an infinite animation throws.
    if (animation.effect?.getTiming().iterations !== Infinity) animation.finish()
  }
  return getComputedStyle(element)
}

/**
 * How far an element's box shadow reaches, in pixels, once its transitions have run: the
 * largest blur or spread among its coloured layers. A ring (`ring-3`) is a 3px spread.
 * Tailwind writes a shadow as several layers, the unused ones transparent or 0px, so an element
 * with none computes to a list of those rather than `none`; this reads 0 for it.
 */
export function shadowReach(element: Element): number {
  const shadow = finishTransitions(element).boxShadow
  if (shadow === 'none') return 0
  const layers = shadow.split(/,(?![^(]*\))/).filter(layer => !layer.includes('rgba(0, 0, 0, 0)'))
  const lengths = layers.flatMap(layer =>
    [...layer.matchAll(/(-?[\d.]+)px/g)].map(match => Math.abs(Number(match[1]))),
  )
  return Math.max(0, ...lengths)
}
