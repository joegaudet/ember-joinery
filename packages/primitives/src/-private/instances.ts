import { assert } from '@ember/debug'
import { associateDestroyableChild, isDestroyed, isDestroying } from '@ember/destroyable'
import { getOwner, setOwner } from '@ember/owner'
import type Owner from '@ember/owner'
import { isNewable } from '../narrowing.ts'

/** A class constructed with the owner, or a function that returns the instance. */
export type InstanceDefinition<T extends object> = (new (owner: Owner) => T) | (() => T)

const instances = new WeakMap<object, Map<InstanceDefinition<object>, object>>()

/**
 * The one instance of `definition` for `context`, made the first time it is asked for and
 * destroyed with `context`. `service()` keys it on the owner, `createStore()` on any context.
 * The class is constructed with `owner`, and the instance gets that owner.
 */
export function instanceFor<T extends object>(
  context: object,
  owner: Owner,
  definition: InstanceDefinition<T>,
  caller: string,
): T {
  let byDefinition = instances.get(context)
  if (!byDefinition) instances.set(context, (byDefinition = new Map()))
  let instance = byDefinition.get(definition) as T | undefined
  if (!instance) {
    assert(
      `Joinery: ${caller} was asked for an instance after its ${context === owner ? 'owner' : 'context'} was destroyed`,
      !isDestroying(context) && !isDestroyed(context),
    )
    instance = isNewable<T>(definition) ? new definition(owner) : (definition as () => T)()
    if (getOwner(instance) === undefined) setOwner(instance, owner)
    associateDestroyableChild(context, instance)
    byDefinition.set(definition, instance)
  }
  return instance
}
