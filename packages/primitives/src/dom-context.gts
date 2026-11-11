/* global HTMLElementTagNameMap -- a DOM type, which ESLint's browser globals don't list */
import Component from '@glimmer/component'
import { cached } from '@glimmer/tracking'
import type Owner from '@ember/owner'
import { isElement, type Newable } from './narrowing.ts'
import { createStore } from './store.ts'

/**
 * Each provider's node (its element, or its marker text node) → the key consumers ask for, and
 * how to read its data.
 *
 * The lookup walks the DOM up from a consumer, rather than sending an event down, so reading
 * the data stays synchronous and fine-grained reactive. (The web components community's
 * context protocol is event based, which opts out of that.)
 */
const PROVIDERS = new WeakMap<Node, [key: unknown, read: () => unknown]>()

export interface ProvideSignature<Data extends object> {
  /** There is none to give attributes to: the provider's element is its own. */
  Element: null
  Args: {
    /**
     * What the subtree gets. A class or function is made into one instance for this provider,
     * with the provider's owner and lifetime (`createStore`); anything else is given as is.
     */
    data: Data | (() => Data) | Newable<Data>
    /**
     * What consumers ask for, when it isn't `@data` itself: say `@data` is an instance, and
     * consumers ask by its class. Compared by identity. A string works but leaves `<Consume>`'s
     * data untyped; a class or object gives it the type.
     */
    key?: string | object
    /**
     * The provider's own element, around the subtree: a tag (default `div`, with
     * `display: contents`, so it doesn't affect layout), or `false` for none. With `false` the
     * provider marks its place with an empty text node, which also lets siblings that come
     * after it (not only its descendants) find it.
     */
    element?: keyof HTMLElementTagNameMap | false
  }
  Blocks: {
    /** The subtree that can consume the data. */
    default: []
  }
}

/**
 * Provides data to everything rendered inside it, found by `<Consume>` through the DOM, as
 * React's context is found through the component tree:
 *
 *   class Theme { @tracked accent = 'violet' }
 *
 *   <Provide @data={{Theme}}>
 *     …
 *     <Consume @key={{Theme}} as |theme|>{{theme.data.accent}}</Consume>
 *   </Provide>
 *
 * It is ember-primitives' `Provide`.
 */
export class Provide<Data extends object> extends Component<ProvideSignature<Data>> {
  readonly node: Text | HTMLElement

  constructor(owner: Owner, args: ProvideSignature<Data>['Args']) {
    super(owner, args)
    const element = args.element
    if (element !== undefined && element !== false && typeof element !== 'string') {
      throw new Error("Joinery: <Provide>'s @element is a tag name or false")
    }
    if (element === false) {
      this.node = document.createTextNode('')
    } else {
      this.node = document.createElement(element || 'div')
      this.node.style.display = 'contents'
    }
    PROVIDERS.set(this.node, [args.key ?? args.data, () => this.data])
  }

  get data(): Data {
    if (!('data' in this.args)) throw new Error('Joinery: <Provide> needs @data')
    const data = this.args.data
    // A class or a function: one instance per provider.
    if (typeof data === 'function') return createStore<Data>(this, data as () => Data)
    return data
  }

  <template>
    {{#if (isElement this.node)}}
      {{this.node}}
      {{#in-element this.node insertBefore=null}}
        {{yield}}
      {{/in-element}}
    {{else}}
      {{this.node}}
      {{yield}}
    {{/if}}
  </template>
}

/**
 * The provider of `key` nearest above `start` in the DOM: each node's earlier siblings are
 * checked (a text-node provider sits beside what it provides), then its parent's, up to the
 * document.
 */
function findProvider(start: Node, key: unknown): (() => unknown) | undefined {
  let level: Node | null = start
  while (level) {
    for (let node: Node | null = level; node; node = node.previousSibling) {
      const provider = PROVIDERS.get(node)
      if (provider && provider[0] === key) return provider[1]
    }
    level = level.parentElement
  }
  return undefined
}

/** What `<Consume @key={{Key}}>` gives: the instance for a class or function, else the value. */
export type DataForKey<Key> = Key extends string
  ? unknown
  : Key extends Newable<infer T>
    ? T
    : Key extends () => infer T
      ? T
      : Key

export interface ConsumeSignature<Key extends object | string> {
  Args: {
    /** The `@key` (or `@data`) of the provider to read. */
    key: Key
  }
  Blocks: {
    /** `context.data` is the nearest provider's data; reading it is reactive. */
    default: [context: { readonly data: DataForKey<Key> }]
  }
}

/**
 * Reads the data of the nearest `<Provide>` above it with the same key: `context.data`. It
 * throws if there is none. It is ember-primitives' `Consume`.
 */
export class Consume<Key extends object | string> extends Component<ConsumeSignature<Key>> {
  readonly node = document.createTextNode('')

  @cached
  get context(): { readonly data: DataForKey<Key> } {
    const node = this.node
    const key = () => this.args.key
    return {
      get data(): DataForKey<Key> {
        const read = findProvider(node, key())
        if (!read) {
          throw new Error(
            `Joinery: <Consume> found no <Provide> above it for the key ${String(key())}`,
          )
        }
        return read() as DataForKey<Key>
      },
    }
  }

  <template>
    {{this.node}}
    {{yield this.context}}
  </template>
}
