import { capabilities, setHelperManager } from '@ember/helper'
import type Owner from '@ember/owner'
import type { Registry } from '@ember/service'
import { instanceFor } from './-private/instances.ts'
import { PromiseState, type LoadState } from './-private/promise-state.ts'
import { findOwner } from './store.ts'

/**
 * What `service` makes one of per owner: a class, constructed with the owner, or a function
 * that returns the instance. The definition itself is the key, so share one definition.
 */
export type ServiceDefinition<T extends object> = (new (owner: Owner) => T) | (() => T)

/** The name of a service registered with the app (`app/services/<name>.ts`), `router` among them. */
export type ServiceName = keyof Registry & string

function ownerFor(context: object, caller: string): Owner {
  const owner = findOwner(context)
  if (!owner) throw new Error(`Joinery: ${caller} found no owner on ${String(context)}`)
  return owner
}

/** The service registered as `name`, as `@service` would inject it. */
function lookupService(owner: Owner, name: string): object {
  const instance = owner.lookup(`service:${name}`) as object | undefined
  if (!instance) {
    throw new Error(
      `Joinery: service("${name}") found no service registered as service:${name}. ` +
        'Pass a class instead for a service of your own that is not registered.',
    )
  }
  return instance
}

function instanceOrService<T extends object>(
  owner: Owner,
  definition: ServiceDefinition<T> | string,
): T {
  if (typeof definition === 'string') return lookupService(owner, definition) as T
  return instanceFor(owner, owner, definition, 'service()')
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
 * A name in place of the class looks up a service registered with the app, as `@service`
 * does, so a template can read one without a backing class: `(service "router")`. That is
 * ember-primitives' `service` helper; the class form is its `createService`.
 *
 * @param context anything with an owner, or the owner itself
 * @param definition the class, a function returning the instance, or a registered service's name
 */
export function service<Name extends ServiceName>(name: Name): Registry[Name] & object
export function service<T extends object>(definition: ServiceDefinition<T>): T
export function service<Name extends ServiceName>(
  context: object,
  name: Name,
): Registry[Name] & object
export function service<T extends object>(context: object, definition: ServiceDefinition<T>): T
export function service<T extends object>(
  ...args: [ServiceDefinition<T> | string] | [object, ServiceDefinition<T> | string]
): T {
  if (args.length !== 2) {
    throw new Error(
      'Joinery: in JavaScript, service() takes the context and the class: ' +
        'service(this, Toasts). (service Toasts) works in templates only.',
    )
  }
  const [context, definition] = args
  return instanceOrService(ownerFor(context, 'service()'), definition)
}

interface ServiceHelperArgs {
  positional: readonly unknown[]
}

interface ServiceHelperBucket {
  args: ServiceHelperArgs
  definition?: unknown
  value?: object
}

/** Lets templates call `(service Definition)`: the helper manager knows the owner. */
class ServiceHelperManager {
  capabilities = capabilities('3.23', { hasValue: true })

  readonly owner: Owner

  constructor(owner: Owner) {
    this.owner = owner
  }

  createHelper(_definition: unknown, args: ServiceHelperArgs): ServiceHelperBucket {
    return { args }
  }

  getValue(bucket: ServiceHelperBucket): object {
    const { positional } = bucket.args
    const [definition] = positional
    if (
      positional.length !== 1 ||
      (typeof definition !== 'function' && typeof definition !== 'string')
    ) {
      throw new Error(
        'Joinery: (service) takes one argument: the class or function to make an instance of, ' +
          "or a registered service's name",
      )
    }
    // Only a new argument asks again, so nothing the lookup reads can re-run it (as a template
    // tears down, say).
    if (bucket.value === undefined || bucket.definition !== definition) {
      bucket.value = instanceOrService(this.owner, definition as ServiceDefinition<object> | string)
      bucket.definition = definition
    }
    return bucket.value
  }
}

// The owner parameter is typed for 7.x; 6.12's types leave it untyped, so it is annotated here.
setHelperManager((owner: unknown) => new ServiceHelperManager(owner as Owner), service)

/** What an `asyncService` loader resolves with: the class (or function), or its module. */
export type AsyncServiceModule<T extends object> =
  ServiceDefinition<T> | { default: ServiceDefinition<T> }

/** Loads the class an `asyncService` makes its instance of: `() => import('./cart.ts')`. */
export type AsyncServiceLoader<T extends object> = () => Promise<AsyncServiceModule<T>>

/**
 * The state of an `asyncService`: loading, then the instance or why it failed (a `LoadError`,
 * as `@ember-joinery/primitives/load` names it).
 */
export type AsyncServiceState<T extends object> = LoadState<T>

const loading = new WeakMap<Owner, Map<AsyncServiceLoader<object>, PromiseState<object>>>()

function definitionOf<T extends object>(loaded: unknown): ServiceDefinition<T> {
  const definition =
    typeof loaded === 'function' ? loaded : (loaded as { default?: unknown } | null)?.default
  if (typeof definition === 'function') return definition as ServiceDefinition<T>
  throw new Error(
    'Joinery: an asyncService loader must resolve with a class, a function, or a module whose ' +
      'default export is one',
  )
}

/**
 * A service whose class loads on demand, for one that pulls in a large dependency. The loader
 * runs the first time any part of the app asks, and every caller with the same loader then
 * shares one instance per owner, as with `service`:
 *
 *   const loadEditor = () => import('./rich-text-editor.ts') // default export: the class
 *
 *   class Toolbar extends Component {
 *     get editor() {
 *       return asyncService(this, loadEditor)
 *     }
 *   }
 *
 *   {{#if this.editor.isLoading}}Loading…
 *   {{else if this.editor.error}}{{this.editor.error.reason}}
 *   {{else if this.editor.resolved}}<Bold @editor={{this.editor.resolved}} />{{/if}}
 *
 * It returns a reactive state, not the instance: `isLoading` while the class loads, then
 * `resolved` (the instance) or `error` (`{ reason, original }`). The loader resolves with the
 * class, a function returning the instance, or a module whose default export is either. The
 * loader itself is the key, so share one function between callers. It is ember-primitives'
 * `createAsyncService`, except that each owner (each test) gets its own instance.
 *
 * @param context anything with an owner, or the owner itself
 * @param loader resolves with the class, or its module
 */
export function asyncService<T extends object>(
  context: object,
  loader: AsyncServiceLoader<T>,
): AsyncServiceState<T> {
  const owner = ownerFor(context, 'asyncService()')
  let byLoader = loading.get(owner)
  if (!byLoader) loading.set(owner, (byLoader = new Map()))
  let state = byLoader.get(loader as AsyncServiceLoader<object>) as PromiseState<T> | undefined
  if (!state) {
    state = new PromiseState<T>(loader, loaded =>
      instanceFor(owner, owner, definitionOf<T>(loaded), 'asyncService()'),
    )
    byLoader.set(loader as AsyncServiceLoader<object>, state as PromiseState<object>)
  }
  return state
}
