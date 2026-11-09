import { getRootElement } from '@ember/test-helpers'
import { attributes, selectors } from './selectors.ts'
import {
  HarnessError,
  NotFoundError,
  componentOf,
  describeElement,
  findWithin,
  type Scope,
} from './-private/tree.ts'

/** Which instance of a component a harness drives. */
export interface HarnessOptions {
  /** The component's `@name`, rendered as `data-test-jn-name`. Default: the class's `static named`. */
  name?: string
  /** Which match to drive when several match, counting from 0. Default: 0, the first. */
  index?: number
  /**
   * Where to look: a harness (its component, and every part it owns wherever that is
   * rendered) or an element. Default: the test's root element.
   */
  within?: Harness | Element
}

/** How `@child`, `child()`, `find()` and `findAll()` pick an instance: a name or options. */
export type ChildOptions = string | Pick<HarnessOptions, 'name' | 'index'>

/** A harness class, as `@child`, `find()` and `findAll()` take it. */
export type HarnessClass<T extends Harness = Harness> = (new (
  options?: string | HarnessOptions,
) => T) &
  Pick<typeof Harness, 'component' | 'named'>

function normalize(options: string | HarnessOptions | undefined): HarnessOptions {
  return typeof options === 'string' ? { name: options } : (options ?? {})
}

function kinds(component: string | readonly string[] | undefined): readonly string[] {
  return typeof component === 'string' ? [component] : (component ?? [])
}

/**
 * The base of every Joinery harness. A harness drives one instance of a component: it finds the
 * instance's root by `data-test-jn` (and `data-test-jn-name`, when given a name) every time you
 * read it, so one harness stays valid across re-renders, and it reaches the component's parts
 * through `data-test-jn-part`, following `data-test-jn-owner` into the top layer and portals.
 *
 *   class DisclosureHarness extends Harness {
 *     static component = 'disclosure' // the data-test-jn value it drives
 *     get trigger() { return this.part('trigger') }
 *     get isOpen() { return this.trigger.getAttribute('aria-expanded') === 'true' }
 *     async toggle() { await click(this.trigger) }
 *   }
 *
 *   new DisclosureHarness()            // the first disclosure in the test
 *   new DisclosureHarness('faq')       // <Disclosure @name="faq">
 *   new DisclosureHarness({ name: 'faq', within: card, index: 1 })
 *
 * Page objects extend a harness and declare the components inside it with `@child`.
 */
export class Harness {
  /**
   * The `data-test-jn` value of the component this harness drives, or several values when it
   * drives more than one. A harness pointed at another component fails with a message that
   * says so. Leave it unset to drive any component.
   */
  static component?: string | readonly string[]

  /** The `@name` this class finds when it isn't given one, as in `static named = 'edit-profile'`. */
  static named?: string

  readonly #name: string | undefined
  readonly #index: number
  readonly #within: Harness | Element | undefined
  readonly #children = new Map<HarnessClass<Harness>, Map<string, Harness>>()

  /**
   * @param options the component's `@name`, or the name, index and scope to find it by. With
   *   neither, the first instance of the component in the test.
   */
  constructor(options?: string | HarnessOptions) {
    const { name, index = 0, within } = normalize(options)
    this.#name = name ?? (this.constructor as typeof Harness).named
    this.#index = index
    this.#within = within
  }

  /**
   * Every instance of this component in the test, one harness each, in document order. Each
   * finds its instance by position, live, like any harness.
   *
   *   const [first, second] = ButtonHarness.findAll()
   */
  static findAll<T extends Harness>(this: HarnessClass<T>, options?: ChildOptions): T[] {
    const name = normalize(options).name
    const count = new this({ name }).#matches().length
    return Array.from({ length: count }, (_, index) => new this({ name, index }))
  }

  /** The component's root element, looked up on every read. Throws when it isn't rendered. */
  get element(): HTMLElement {
    const matches = this.#matches()
    const element = matches[this.#index]
    if (!element) {
      const count = matches.length
      throw new NotFoundError(`no ${this} found${count ? ` (there are only ${count})` : ''}`)
    }
    return element as HTMLElement
  }

  /** Whether the component is rendered now. Unlike `element`, it doesn't throw. */
  get exists(): boolean {
    try {
      return Boolean(this.element)
    } catch (error) {
      if (error instanceof NotFoundError) return false
      throw error
    }
  }

  /**
   * This component's parts named `part`, in document order: the elements with
   * `data-test-jn-part="<part>"` that belong to this instance, whether they are inside its
   * root or owned by it (`data-test-jn-owner`) and rendered elsewhere. Parts of a component
   * nested inside this one belong to that component and aren't included.
   */
  parts<E extends Element = HTMLElement>(part: string): E[] {
    const root = this.element
    return findWithin(root, selectors.part(part)).filter(
      element => componentOf(element) === root,
    ) as E[]
  }

  /**
   * One part of this component: the first part named `part`, or, given a value, the one whose
   * `data-test-jn-value` is that value. Throws when there is none.
   */
  part<E extends Element = HTMLElement>(part: string, value?: string): E {
    const element = this.queryPart<E>(part, value)
    if (!element) {
      const which = value === undefined ? `"${part}" part` : `"${part}" part "${value}"`
      throw new NotFoundError(`no ${which} found in ${this}`)
    }
    return element
  }

  /** Like `part()`, but returns `null` when there is no such part. */
  queryPart<E extends Element = HTMLElement>(part: string, value?: string): E | null {
    const parts = this.parts<E>(part)
    if (value === undefined) return parts[0] ?? null
    return parts.find(element => element.getAttribute(attributes.value) === value) ?? null
  }

  /** The `data-test-jn-value` of each of this component's parts named `part`, in order. */
  values(part: string): string[] {
    return this.parts(part)
      .map(element => element.getAttribute(attributes.value))
      .filter((value): value is string => value !== null)
  }

  /**
   * The harness for a component inside this one, created on first use and kept: the same
   * name and class always give back the same object. `@child` declarations use this.
   */
  child<T extends Harness>(Type: HarnessClass<T>, options?: ChildOptions): T {
    const { name, index } = normalize(options)
    let byKey = this.#children.get(Type)
    if (!byKey) this.#children.set(Type, (byKey = new Map()))
    const key = `${index ?? 0}:${name ?? ''}`
    let harness = byKey.get(key)
    if (!harness) byKey.set(key, (harness = new Type({ name, index, within: this })))
    return harness as T
  }

  /** A one-off harness for a component inside this one. Each call makes a new harness. */
  find<T extends Harness>(Type: HarnessClass<T>, options?: ChildOptions): T {
    return new Type({ ...normalize(options), within: this })
  }

  /** A harness for every instance of a component inside this one, in document order. */
  findAll<T extends Harness>(Type: HarnessClass<T>, options?: ChildOptions): T[] {
    const name = normalize(options).name
    const count = new Type({ name, within: this }).#matches().length
    return Array.from({ length: count }, (_, index) => new Type({ name, index, within: this }))
  }

  /** What this harness drives, as error messages put it: `dialog "edit-profile" in card`. */
  toString(): string {
    const component = kinds((this.constructor as typeof Harness).component)
    let description = component.length ? component.join(' or ') : 'component'
    if (this.#name !== undefined) description += ` "${this.#name}"`
    if (this.#index > 0) description += ` #${this.#index + 1}`
    const within = this.#within
    if (within instanceof Harness) description += ` in ${within}`
    else if (within) description += ` in ${describeElement(within)}`
    return description
  }

  /** Where this harness looks: its parent's root, the element it was given, or the test root. */
  #scope(): Scope {
    const within = this.#within
    if (within instanceof Harness) return within.element
    return within ?? getRootElement()
  }

  /** The roots in scope that this harness could drive, in document order. */
  #matches(): Element[] {
    const scope = this.#scope()
    const component = kinds((this.constructor as typeof Harness).component)
    const drives = (element: Element) =>
      !component.length || component.includes(element.getAttribute(attributes.component)!)

    if (this.#name === undefined) {
      const selector = component.length
        ? component.map(kind => selectors.component(kind)).join(', ')
        : selectors.component()
      return findWithin(scope, selector)
    }

    const named = findWithin(scope, selectors.component(undefined, this.#name))
    const matches = named.filter(drives)
    const [other] = named
    if (!matches.length && other) {
      throw new HarnessError(
        `the component named "${this.#name}" is a "${other.getAttribute(attributes.component)}"; ` +
          `this harness drives ${component.map(kind => `"${kind}"`).join(' or ')}`,
      )
    }
    return matches
  }
}
