/**
 * Makes each method on a table-core prototype (a row's, cell's, column's or header's) come back
 * bound to the instance it is read from, the first time it is read there.
 *
 * table-core v9 shares one prototype per kind, and its methods read `this`. Ember's templates
 * call a function without the object it came from (`{{(row.getIsSelected)}}`,
 * `@onCheckedChange={{row.toggleSelected}}`), so an unbound method would lose its row. The
 * bound copy is kept on the instance, not enumerable, so table-core's copies of a row (the
 * sorted row model clones rows through their own enumerable properties) bind their own.
 */
function bindMethods(prototype: object): void {
  for (const key of Object.keys(prototype)) {
    const descriptor = Object.getOwnPropertyDescriptor(prototype, key)
    const method: unknown = descriptor?.value
    if (typeof method !== 'function') continue
    Object.defineProperty(prototype, key, {
      configurable: true,
      enumerable: descriptor!.enumerable ?? true,
      get(this: object) {
        if (this === prototype) return method
        const bound = (...args: unknown[]) =>
          (method as (...a: unknown[]) => unknown).apply(this, args)
        Object.defineProperty(this, key, { value: bound, configurable: true, writable: true })
        return bound
      },
      set(this: object, value: unknown) {
        Object.defineProperty(this, key, {
          value,
          configurable: true,
          enumerable: true,
          writable: true,
        })
      },
    })
  }
}

/**
 * A table feature, registered after every other, that binds the prototype methods the others
 * assigned (see `bindMethods`). The table's own methods are closures already.
 */
export const boundMethodsFeature = {
  assignRowPrototype: bindMethods,
  assignCellPrototype: bindMethods,
  assignColumnPrototype: bindMethods,
  assignHeaderPrototype: bindMethods,
}
