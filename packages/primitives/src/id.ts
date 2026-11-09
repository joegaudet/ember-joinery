let counter = 0

/**
 * A new id, unique on the page: `jn-1`, `jn-2`… Use it for the `id` that ties ARIA attributes
 * together (`aria-controls`, `aria-labelledby`). In a template, `{{#let (uniqueId) as |id|}}`.
 *
 * @param prefix what the id starts with. Default `jn`.
 */
export function uniqueId(prefix = 'jn'): string {
  counter += 1
  return `${prefix}-${counter}`
}

const ids = new WeakMap<object, string>()

/**
 * An id that stays the same for an object's whole life, made the first time it is asked for.
 * Give a part's name to get an id derived from it, so one component can name all its parts:
 *
 *   idFor(this)              // 'jn-7', the root
 *   idFor(this, 'content')   // 'jn-7-content'
 *   idFor(this, 'title')     // 'jn-7-title'
 *
 * A caller's `@id` should win: `this.args.id ?? idFor(this, 'content')`.
 */
export function idFor(object: object, part?: string): string {
  let id = ids.get(object)
  if (id === undefined) ids.set(object, (id = uniqueId()))
  return part === undefined ? id : `${id}-${part}`
}
