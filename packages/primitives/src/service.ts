import { assert } from '@ember/debug'
import { associateDestroyableChild, isDestroyed, isDestroying } from '@ember/destroyable'
import { capabilities, setHelperManager } from '@ember/helper'
import { getOwner, setOwner } from '@ember/owner'
import type Owner from '@ember/owner'

/**
 * What `service` makes one of per owner: a class, constructed with the owner, or a function
 * that returns the instance. The definition itself is the key, so share one definition.
 */
export type ServiceDefinition<T extends object> = (new (owner: Owner) => T) | (() => T)

const instances = new WeakMap<Owner, Map<ServiceDefinition<object>, object>>()

function isClass<T extends object>(
  definition: ServiceDefinition<T>,
): definition is new (owner: Owner) => T {
  return definition.prototype?.constructor === definition
}

function ownerOf(context: object): Owner | undefined {
  if ('lookup' in context && typeof context.lookup === 'function') return context as Owner
  return getOwner(context)
}

function instanceFor<T extends object>(owner: Owner, definition: ServiceDefinition<T>): T {
  let byDefinition = instances.get(owner)
  if (!byDefinition) instances.set(owner, (byDefinition = new Map()))
  let instance = byDefinition.get(definition) as T | undefined
  if (!instance) {
    assert(
      'Joinery: service() was asked for an instance after its owner was destroyed',
      !isDestroying(owner) && !isDestroyed(owner),
    )
    instance = isClass(definition) ? new definition(owner) : definition()
    setOwner(instance, owner)
    associateDestroyableChild(owner, instance)
    byDefinition.set(definition, instance)
  }
  return instance
}

/**
 * One instance of a class per owner (per app instance, and so per test), made the first time
 * it is asked for and destroyed with its owner. It is for state that a whole app shares but
 * that tests must not: a toaster's queue, the color scheme. Unlike `@service`, nothing is
 * registered by name, and a module that never asks for the class never loads it.
 *
 * In JavaScript, pass anything with an owner (a component, a route) and the class:
 *
 *   class Toasts { @tracked queue = [] }
 *
 *   class Toaster extends Component {
 *     get toasts() { return service(this, Toasts) }
 *   }
 *
 * In a template, pass the class alone:
 *
 *   {{#let (service Toasts) as |toasts|}}…{{/let}}
 *
 * The class is constructed with the owner, and the instance gets that owner, so `@service`
 * injections work in it (after its constructor). For cleanup, `registerDestructor(this, …)`
 * in the constructor runs when the owner is destroyed. A function in place of the class is
 * called once per owner, to construct the instance yourself: `service(this, makeToasts)`.
 *
 * @param context anything with an owner, or the owner itself
 * @param definition the class, or a function returning the instance
 */
export function service<T extends object>(definition: ServiceDefinition<T>): T
export function service<T extends object>(context: object, definition: ServiceDefinition<T>): T
export function service<T extends object>(
  ...args: [ServiceDefinition<T>] | [object, ServiceDefinition<T>]
): T {
  if (args.length !== 2) {
    throw new Error(
      'Joinery: in JavaScript, service() takes the context and the class: ' +
        'service(this, Toasts). (service Toasts) works in templates only.',
    )
  }
  const [context, definition] = args
  const owner = ownerOf(context)
  if (!owner) throw new Error(`Joinery: service() found no owner on ${String(context)}`)
  return instanceFor(owner, definition)
}

interface ServiceHelperArgs {
  positional: readonly unknown[]
}

/** Lets templates call `(service Definition)`: the helper manager knows the owner. */
class ServiceHelperManager {
  capabilities = capabilities('3.23', { hasValue: true })

  readonly owner: Owner

  constructor(owner: Owner) {
    this.owner = owner
  }

  createHelper(_definition: unknown, args: ServiceHelperArgs): ServiceHelperArgs {
    return args
  }

  getValue(args: ServiceHelperArgs): object {
    const [definition] = args.positional
    if (args.positional.length !== 1 || typeof definition !== 'function') {
      throw new Error(
        'Joinery: (service) takes one argument, the class or function to make an instance of',
      )
    }
    return instanceFor(this.owner, definition as ServiceDefinition<object>)
  }
}

setHelperManager(owner => new ServiceHelperManager(owner as Owner), service)
