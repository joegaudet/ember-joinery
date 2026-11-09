import { getOwner } from '@ember/owner'
import type Owner from '@ember/owner'
import { instanceFor, type InstanceDefinition } from './-private/instances.ts'

/**
 * What `createStore` makes one of per context: a class, constructed with the context's owner,
 * or a function that returns the instance. The definition itself is the key, so share one
 * definition: two arrow functions that do the same thing are two keys.
 */
export type StoreDefinition<T extends object> = InstanceDefinition<T>

/**
 * Whether `value` is an owner. Only `lookup()` is required: the owner's other methods are
 * Ember's business, and any object with `lookup` can stand in for one.
 */
export function isOwner(value: unknown): value is Owner {
  return (
    typeof value === 'object' &&
    value !== null &&
    'lookup' in value &&
    typeof value.lookup === 'function'
  )
}

/**
 * The owner of `context`: the context itself when it is an owner, else its `getOwner()`, else
 * an `owner` property (a test's `this.owner`). `undefined` when there is none.
 */
export function findOwner(context: unknown): Owner | undefined {
  if (isOwner(context)) return context
  if (typeof context !== 'object' || context === null) return undefined
  const owner = getOwner(context)
  if (isOwner(owner)) return owner
  if ('owner' in context && isOwner(context.owner)) return context.owner
  return undefined
}

/**
 * One instance of a class per context, made the first time it is asked for and destroyed with
 * the context. Ask from a component, and each instance of the component gets its own; ask
 * from the owner, and the whole app shares one (that is `service`). Repeat calls return the
 * same instance, so a getter reads like a `@cached` one:
 *
 *   class Draft { @tracked text = '' }
 *
 *   class Editor extends Component {
 *     get draft() {
 *       return createStore(this, Draft) // one Draft per Editor
 *     }
 *   }
 *
 * The class is constructed with the context's owner, and the instance gets that owner, so
 * `@service` injections work in it (after its constructor). For cleanup,
 * `registerDestructor(this, …)` in the constructor runs when the context is destroyed. A
 * function in place of the class is called once per context, to construct the instance
 * yourself: `createStore(this, () => new Draft('Untitled'))`.
 *
 * It is ember-primitives' `createStore`. The context needs an owner (a component, route,
 * controller, service, helper or modifier all have one), which the class is constructed with.
 *
 * @param context what the instance belongs to: anything with an owner, or the owner itself
 * @param definition the class, or a function returning the instance
 */
export function createStore<T extends object>(context: object, definition: StoreDefinition<T>): T {
  const owner = findOwner(context)
  if (!owner) {
    throw new Error(
      `Joinery: createStore() found no owner on ${String(context)}. Pass a component, route, ` +
        'or anything else with an owner.',
    )
  }
  return instanceFor(context, owner, definition, 'createStore()')
}
