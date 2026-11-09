/**
 * The `data-test-jn-*` attributes every Joinery component renders. They are public API: the
 * harnesses find and scope components with them, and your own tests can too.
 *
 *   data-test-jn="<component>"   the root of a component instance (`dialog`, `button`…)
 *   data-test-jn-name="<@name>"  on the root, when the component was given `@name`
 *   data-test-jn-part="<part>"   a part of the component (`trigger`, `content`, `item`…)
 *   data-test-jn-owner="<id>"    on a portalled or top-layer part: the `id` of its root
 *   data-test-jn-value="<key>"   an option, item, tab or toggle, by its key
 *   data-test-jn-wrapper         on a root that wraps the caller's content (a scroller, a
 *                                layout): the parts inside it belong to the component around it
 */
export const attributes = {
  component: 'data-test-jn',
  name: 'data-test-jn-name',
  part: 'data-test-jn-part',
  owner: 'data-test-jn-owner',
  value: 'data-test-jn-value',
  wrapper: 'data-test-jn-wrapper',
} as const

/** A value made safe to put inside a double-quoted CSS attribute selector. */
function quote(value: string): string {
  return `"${value.replace(/["\\]/g, '\\$&').replace(/\n/g, '\\a ')}"`
}

function attribute(name: string, value?: string): string {
  return value === undefined ? `[${name}]` : `[${name}=${quote(value)}]`
}

/**
 * CSS selectors for the `data-test-jn-*` attributes. Each takes an optional value; without one
 * it matches any element that has the attribute.
 *
 *   selectors.component('dialog', 'edit-profile')
 *   // '[data-test-jn="dialog"][data-test-jn-name="edit-profile"]'
 *   selectors.part('trigger') // '[data-test-jn-part="trigger"]'
 */
export const selectors = {
  /** A component's root, by its kind (`data-test-jn`) and, optionally, its `@name`. */
  component(component?: string, name?: string): string {
    return (
      attribute(attributes.component, component) +
      (name === undefined ? '' : attribute(attributes.name, name))
    )
  },
  /** A component's root, by its `@name` (`data-test-jn-name`), whatever its kind. */
  name(name?: string): string {
    return attribute(attributes.name, name)
  },
  /** A part (`data-test-jn-part`). */
  part(part?: string): string {
    return attribute(attributes.part, part)
  },
  /** The portalled and top-layer parts of the root whose `id` this is (`data-test-jn-owner`). */
  owner(id?: string): string {
    return attribute(attributes.owner, id)
  },
  /** An option, item, tab or toggle, by its key (`data-test-jn-value`). */
  value(key?: string): string {
    return attribute(attributes.value, key)
  },
  /** The root of a component that wraps the caller's content (`data-test-jn-wrapper`). */
  wrapper(): string {
    return attribute(attributes.wrapper)
  },
}
