/**
 * Type guards and the small types the other utilities share. They are ember-primitives'
 * `narrowing` and `type-utils`, plus the class check its `utils` keeps private.
 */

/** Anything `new` makes an instance of: a class, whatever its constructor takes. */
export type Newable<T extends object = object> = new (...args: any[]) => T

/** Whether `value` is a string. Narrows it, where `typeof` in a template can't. */
export function isString(value: unknown): value is string {
  return typeof value === 'string'
}

/** Whether `value` is a DOM element (from any window: an iframe's elements count). */
export function isElement(value: unknown): value is Element {
  if (value instanceof Element) return true
  return (
    typeof value === 'object' &&
    value !== null &&
    (value as Partial<Node>).nodeType === 1 &&
    typeof (value as Partial<Element>).getAttribute === 'function'
  )
}

/**
 * Whether `value` is a class, to call with `new`, rather than a function to call. A class's
 * prototype points back at it; an arrow function has no prototype. (A plain `function` has
 * one too, and counts as a class.)
 */
export function isNewable<T extends object = object>(value: unknown): value is Newable<T> {
  return typeof value === 'function' && value.prototype?.constructor === value
}
