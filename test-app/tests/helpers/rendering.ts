/** An element's classes (sorted) and its other attributes, for comparing two renderings. */
export interface Rendering {
  classes: string[]
  attributes: Record<string, string>
}

/**
 * What an element renders, for a test that checks a part's component and its modifier render
 * the same thing. `data-case`, a test's own marker, is left out.
 *
 * So is what Ember itself adds before 7.1: there `As` renders a part through a classic
 * component (Ember 6.12 has no built-in `element` helper), which gives it the class
 * `ember-view` and an id `ember<N>`. A part's own id is still compared.
 */
export function rendering(element: Element): Rendering {
  const attributes: Record<string, string> = {}
  for (const { name, value } of element.attributes) {
    if (name === 'class' || name === 'data-case') continue
    if (name === 'id' && /^ember\d+$/.test(value)) continue
    attributes[name] = value
  }
  const classes = [...element.classList].filter(name => name !== 'ember-view').sort()
  return { classes, attributes }
}
