import Component from '@glimmer/component'
import type { ComponentLike } from '@glint/template'
import {
  PromiseState,
  unwrapModule,
  type LoadError,
  type LoadState,
} from './-private/promise-state.ts'
import { isNewable } from './narrowing.ts'

export type { LoadError, LoadState }

export interface LoadSignature<Expected = { Args: any }> {
  Blocks: {
    /** While the promise is pending. Nothing renders here for a value that isn't a promise. */
    loading: []
    /** If the function threw or the promise rejected: `{ reason, original }`. */
    error: [error: LoadError]
    /**
     * Once loaded, with what was loaded: `<:success as |Loaded|><Loaded @id={{1}} /></:success>`.
     * Without this block, the loaded component renders on its own, with no arguments.
     */
    success?: [component: ComponentLike<Expected>]
  }
}

/** What `load` takes: a component (or a module whose default export is one), or a way to get it. */
export type LoadSource = unknown | Promise<unknown> | (() => unknown) | (() => Promise<unknown>)

/**
 * A component that loads another, for splitting a bundle by hand: it shows its `<:loading>`
 * block while an `import()` (or any promise) is pending, `<:error>` if it fails, and the
 * loaded component once it is there.
 *
 *   const Chart = load(() => import('./revenue-chart.gts'))
 *
 *   <template>
 *     <Chart>
 *       <:loading>Loading the chart…</:loading>
 *       <:error as |error|>The chart didn't load: {{error.reason}}</:error>
 *       <:success as |RevenueChart|><RevenueChart @year={{2026}} /></:success>
 *     </Chart>
 *   </template>
 *
 * It takes a component, a promise of one, or a function returning either, and an imported
 * module stands for its default export. A function is called the first time the component
 * renders, and only then; the result is kept, so later renders show it at once. Tests wait
 * for the promise. It is ember-primitives' `load`, which is reactiveweb's `getPromiseState` in
 * a component.
 *
 * @param source the component, or a promise or function that gives it
 */
export function load<Expected = { Args: any }>(
  source: LoadSource,
): ComponentLike<LoadSignature<Expected>> {
  let state: PromiseState<ComponentLike> | undefined
  // A class component is a function, but it is the value itself, not a way to get it.
  const input = isNewable(source) ? () => source : source
  const stateOf = () => (state ??= new PromiseState<ComponentLike>(input, unwrapModule as never))

  class Load extends Component<LoadSignature<Expected>> {
    get state(): LoadState<ComponentLike> {
      return stateOf()
    }

    /** What the `<:success>` block gets: the loaded component, with the signature asked for. */
    get loaded(): ComponentLike<Expected> {
      return this.state.resolved as unknown as ComponentLike<Expected>
    }

    <template>
      {{#if this.state.isLoading}}
        {{yield to="loading"}}
      {{else if this.state.error}}
        {{yield this.state.error to="error"}}
      {{else if this.state.resolved}}
        {{#if (has-block "success")}}
          {{yield this.loaded to="success"}}
        {{else}}
          <this.state.resolved />
        {{/if}}
      {{/if}}
    </template>
  }

  return Load
}
