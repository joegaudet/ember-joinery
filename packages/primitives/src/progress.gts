import Component from '@glimmer/component'
import { hash } from '@ember/helper'
import type { TOC } from '@ember/component/template-only'
import type { WithBoundArgs } from '@glint/template'

/**
 * Where a progress bar is, as Radix's `data-state`: `indeterminate` without a value, `complete`
 * at its max, and `loading` in between.
 */
export type ProgressState = 'indeterminate' | 'loading' | 'complete'

/** Names a value for assistive technology (`aria-valuetext`), as Radix's `getValueLabel`. */
export type ProgressValueLabel = (value: number, max: number) => string

/** A progress bar's value, resolved from its arguments. */
export interface ResolvedProgress {
  /** The value, clamped to `[0, max]`, or `null` when it is indeterminate. */
  value: number | null
  /** The max: `@max`, or 100 when that isn't a number above 0. */
  max: number
  /** How far along it is, from 0 to 100, rounded to two places (0 when indeterminate). */
  percent: number
  /** How far along it is, from 0 to 1 (0 when indeterminate). */
  decimal: number
  state: ProgressState
}

const DEFAULT_MAX = 100

/** `@max`, when it is a finite number above 0 (Radix's rule), else 100. */
function maxOf(max: number | null | undefined): number {
  return typeof max === 'number' && Number.isFinite(max) && max > 0 ? max : DEFAULT_MAX
}

/**
 * The value: `null` (indeterminate) when none is given, as Radix's; otherwise clamped to
 * `[0, max]`, and 0 when it isn't a finite number, as ember-primitives' is.
 */
function valueOf(value: number | null | undefined, max: number): number | null {
  if (value === null || value === undefined) return null
  if (typeof value !== 'number' || !Number.isFinite(value) || value < 0) return 0
  return Math.min(value, max)
}

/** Radix's `data-state` for a value and its max. */
export function progressState(value: number | null | undefined, max: number): ProgressState {
  if (value === null || value === undefined) return 'indeterminate'
  return value === max ? 'complete' : 'loading'
}

/** The value as a whole percentage, `33%`: Radix's and ember-primitives' default value label. */
export function defaultProgressLabel(value: number, max: number): string {
  return `${Math.round((value / max) * 100)}%`
}

/** What a progress bar renders for a value and a max, as `<Progress>` resolves them. */
export function resolveProgress(
  value: number | null | undefined,
  max: number | null | undefined,
): ResolvedProgress {
  const resolvedMax = maxOf(max)
  const resolved = valueOf(value, resolvedMax)
  const decimal = resolved === null ? 0 : resolved / resolvedMax
  return {
    value: resolved,
    max: resolvedMax,
    percent: Math.round(decimal * 100 * 100) / 100,
    decimal,
    state: progressState(resolved, resolvedMax),
  }
}

/** An attribute's value, or `undefined` to leave it off. */
function present(value: number | null): number | undefined {
  return value === null ? undefined : value
}

/** `data-percent`, left off with the value while the bar is indeterminate. */
function percentOf(progress: ResolvedProgress): number | undefined {
  return progress.value === null ? undefined : progress.percent
}

export interface ProgressIndicatorSignature {
  Args: {
    /** Set by `<Progress>`. */
    progress: ResolvedProgress
  }
  Blocks: { default: [] }
  Element: HTMLDivElement
}

/**
 * The bar inside a progress bar, as Radix's `Progress.Indicator` and ember-primitives'
 * `Indicator`: a `div` with the progress bar's state, for you to size or move with CSS
 * (`width: {{p.percent}}%`, or a transform, as the styled Progress does).
 */
export const ProgressIndicator: TOC<ProgressIndicatorSignature> = <template>
  <div
    data-state={{@progress.state}}
    data-value={{present @progress.value}}
    data-max={{@progress.max}}
    data-percent={{percentOf @progress}}
    data-test-jn-part="indicator"
    ...attributes
  >{{yield}}</div>
</template>

/** What `<Progress>` yields. */
export interface ProgressYield {
  /** The bar, with the progress bar's state on it. */
  Indicator: WithBoundArgs<typeof ProgressIndicator, 'progress'>
  /** The value, clamped to `[0, max]`, or `null` while it is indeterminate. */
  value: number | null
  /** The max. */
  max: number
  /** How far along it is, from 0 to 100, rounded to two places. */
  percent: number
  /** How far along it is, from 0 to 1. */
  decimal: number
  state: ProgressState
}

export interface ProgressSignature {
  Args: {
    /**
     * How far along it is, from 0 to `@max`. A value outside that range is clamped into it;
     * leave it out (or pass `null`) while there's no telling, and the bar is indeterminate.
     */
    value?: number | null
    /** The value it completes at. Default 100. */
    max?: number
    /**
     * Names the value for assistive technology (`aria-valuetext`). Default the whole
     * percentage, `33%`.
     */
    getValueLabel?: ProgressValueLabel
    /** Its name, for its harness (`data-test-jn-name`). */
    name?: string
  }
  Blocks: { default: [ProgressYield] }
  Element: HTMLDivElement
}

/**
 * Shows how far along a task is, as ember-primitives' and Radix's `Progress`: a `div` with the
 * `progressbar` role, its value in ARIA and data attributes, and an `Indicator` to draw. It has
 * no styles; the styled Progress is built on it.
 *
 *   <Progress @value={{this.uploaded}} aria-label="Upload" as |p|>
 *     <p.Indicator style="width: {{p.percent}}%" />
 *   </Progress>
 *
 * Give it a name: `aria-label`, or `aria-labelledby` naming its label (a `<label for>` doesn't
 * name a progress bar).
 */
export class Progress extends Component<ProgressSignature> {
  get progress(): ResolvedProgress {
    return resolveProgress(this.args.value, this.args.max)
  }

  get valueText(): string | undefined {
    const { value, max } = this.progress
    if (value === null) return undefined
    return (this.args.getValueLabel ?? defaultProgressLabel)(value, max)
  }

  <template>
    {{#let this.progress as |progress|}}
      <div
        role="progressbar"
        aria-valuemin="0"
        aria-valuemax={{progress.max}}
        aria-valuenow={{present progress.value}}
        aria-valuetext={{this.valueText}}
        data-state={{progress.state}}
        data-value={{present progress.value}}
        data-max={{progress.max}}
        data-min="0"
        data-percent={{percentOf progress}}
        data-test-jn="progress"
        data-test-jn-name={{@name}}
        ...attributes
      >
        {{yield
          (hash
            Indicator=(component ProgressIndicator progress=progress)
            value=progress.value
            max=progress.max
            percent=progress.percent
            decimal=progress.decimal
            state=progress.state
          )
        }}
      </div>
    {{/let}}
  </template>
}

export default Progress
