import type { TOC } from '@ember/component/template-only'
import { htmlSafe, type SafeString } from '@ember/template'
import {
  Progress as ProgressPrimitive,
  type ProgressValueLabel,
} from '@ember-joinery/primitives/progress'

export interface ProgressSignature {
  Args: {
    /**
     * How far along it is, from 0 to `@max`; a value outside that range is clamped into it.
     * Leave it out (or pass `null`) while there's no telling: the bar is then indeterminate,
     * and shows empty, as upstream's.
     */
    value?: number | null
    /** The value it completes at. Default 100. */
    max?: number
    /** Names the value for assistive technology (`aria-valuetext`). Default `66%`. */
    getValueLabel?: ProgressValueLabel
    /** The progress bar's name, for its harness (`data-test-jn-name`). */
    name?: string
  }
  Element: HTMLDivElement
}

/**
 * Where the indicator sits: moved back by what's left to do, as upstream's
 * `translateX(-${100 - value}%)`, of the max (upstream's counts in hundredths, whatever its
 * max). A number Joinery computes, so it is safe to bind as a style.
 */
function indicatorStyle(percent: number): SafeString {
  return htmlSafe(`transform: translateX(-${100 - percent}%)`)
}

/**
 * Displays an indicator showing the completion progress of a task, typically displayed as a
 * progress bar: shadcn's Progress, on the primitives' `Progress`. A thin rounded track in
 * `--muted`, filled in `--primary` from the left. Give it a name (`aria-label`, or
 * `aria-labelledby` naming its label), and size it with a class (`w-[60%]`) or your own CSS.
 *
 *   <Progress @value={{this.uploaded}} aria-label="Upload" />
 *
 * Like upstream's, it fills from the left in both directions; mirror it right to left with
 * `rtl:rotate-180` (or `rotate: 180deg` in a `[dir="rtl"]` rule of your own).
 */
const Progress: TOC<ProgressSignature> = <template>
  <ProgressPrimitive
    @value={{@value}}
    @max={{@max}}
    @getValueLabel={{@getValueLabel}}
    @name={{@name}}
    class="jn-progress"
    data-slot="progress"
    ...attributes
    as |p|
  >
    <p.Indicator
      class="jn-progress-indicator"
      data-slot="progress-indicator"
      style={{indicatorStyle p.percent}}
    />
  </ProgressPrimitive>
</template>

export default Progress
