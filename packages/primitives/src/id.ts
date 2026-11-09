let counter = 0
const ids = new WeakMap<object, string>()

/**
 * An id that stays the same for an object's whole life, made the first time it is asked for:
 * `jn-1`, `jn-2`… on the page. Give a part's name to get an id derived from it, so one
 * component names all the parts its ARIA ties together (`aria-controls`, `aria-labelledby`):
 *
 *   idFor(this)              // 'jn-7', the root
 *   idFor(this, 'content')   // 'jn-7-content'
 *   idFor(this, 'title')     // 'jn-7-title'
 *
 * It works as a template helper too: `id={{idFor this "content"}}`. A caller's `@id` should
 * win: `this.args.id ?? idFor(this, 'content')`. For a one-off id with no object to keep it,
 * use Ember's built-in `uniqueId` from `@ember/helper`.
 */
export function idFor(object: object, part?: string): string {
  let id = ids.get(object)
  if (id === undefined) ids.set(object, (id = `jn-${(counter += 1)}`))
  return part === undefined ? id : `${id}-${part}`
}
