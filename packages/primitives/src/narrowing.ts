import { isFunction, isObject, isString } from '@sindresorhus/is'
/**
 * Type guards and the small types the other utilities share. They are ember-primitives'
 * `narrowing` and `type-utils`, plus the guards from its `utils`.
 */

/** Anything `new` makes an instance of: a class, whatever its constructor takes. */
export type Newable<T extends object = object> = new (...args: any[]) => T

/** Whether `value` is a string. Narrows it, where `typeof` in a template can't. */
export { isString }

/**
 * Whether `value` is an object of any kind, not `null`: what `typeof value === 'object'` means
 * once `null` is ruled out. A function is not one. It is ember-primitives' `isNonNullableObject`,
 * from its `utils`.
 */
export function isNonNullableObject(value: unknown): value is object {
  return isObject(value) && !isFunction(value)
}

/** Whether `value` is a DOM element (from any window: an iframe's elements count). */
export function isElement(value: unknown): value is Element {
  if (value instanceof Element) return true
  return (
    isObject(value) &&
    !isFunction(value) &&
    (value as Partial<Node>).nodeType === 1 &&
    isFunction((value as Partial<Element>).getAttribute)
  )
}

/**
 * Whether `value` is a class, to call with `new`, rather than a function to call. A class's
 * prototype points back at it; an arrow function has no prototype. (A plain `function` has
 * one too, and counts as a class.)
 */
export function isNewable<T extends object = object>(value: unknown): value is Newable<T> {
  return isFunction(value) && value.prototype?.constructor === value
}
