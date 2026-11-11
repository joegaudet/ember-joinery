import Component from '@glimmer/component'
import { hash } from '@ember/helper'
import { Star } from 'lucide'
import { Rating as RatingPrimitive, type RatingSummary } from '@ember-joinery/primitives/rating'
import { VisuallyHidden } from '@ember-joinery/primitives/visually-hidden'
import Icon, { type IconNode } from './icon.gts'

/** How big its stars are: `sm` 16px, `default` 20px, `lg` 24px. */
export type RatingSize = 'sm' | 'default' | 'lg'

/** Which half of a star an item draws, in a half rating (`@step={{0.5}}`). */
function halfOf(value: number, step: number): 'start' | 'end' | undefined {
  if (step !== 0.5) return undefined
  return value % 1 === 0.5 ? 'start' : 'end'
}

export interface RatingSignature {
  Args: {
    /** The controlled rating. `0` is none. */
    value?: number
    /** The first rating, when uncontrolled. Default `0`. */
    defaultValue?: number
    /** Called with each rating the user picks, or `0` when they pick the one already picked. */
    onValueChange?: (value: number) => void
    /** The highest rating. Default `5`. */
    max?: number
    /** What each star adds. Default `1`; `0.5` makes each half a star its own, for half ratings. */
    step?: number
    /** Whether it shows its rating but can't be changed. */
    readonly?: boolean
    /** Whether it is a control at all. Default `true`; `false` only shows `@value`. */
    interactive?: boolean
    /** Whether it is disabled. */
    disabled?: boolean
    /** Default `default`: 20px stars. */
    size?: RatingSize
    /** The star: a `lucide` icon. Default lucide's `Star`. */
    icon?: IconNode
    /** Each star's name for assistive technology. Default `1 star`, `2 stars`… */
    itemLabel?: (value: number) => string
    /** What a display-only rating says for assistive technology. Default `Rated 3 out of 5`. */
    summary?: (state: RatingSummary) => string
    /** The form field it submits as, in a form. */
    formName?: string
    /** Its name, for `RatingHarness` (`data-test-jn-name`). */
    name?: string
  }
  Blocks: {
    /**
     * Its label: a `<legend>` that names it. A display-only rating shows it instead of its
     * summary (`{{state.value}} of {{state.total}}`).
     */
    label: [state: RatingSummary]
  }
  Element: HTMLFieldSetElement
}

/**
 * A star rating: ember-primitives' Rating, drawn in shadcn's terms (shadcn/ui has none of its
 * own). Its stars are lucide's `Star`, outlined in `--muted-foreground` and filled with
 * `--primary` up to the rating; hovering one previews it. Each star is a native radio, so the
 * keyboard works as in any radio group, and picking the current rating clears it.
 *
 *   <Rating @defaultValue={{4}} @step={{0.5}} @onValueChange={{this.rate}}>
 *     <:label>Rate this recipe</:label>
 *   </Rating>
 *
 * Without a label block, name it with `aria-label`.
 */
export default class Rating extends Component<RatingSignature> {
  get size(): RatingSize {
    return this.args.size ?? 'default'
  }

  get icon(): IconNode {
    return this.args.icon ?? Star
  }

  get step(): number {
    return this.args.step ?? 1
  }

  half = (value: number): 'start' | 'end' | undefined => halfOf(value, this.step)

  <template>
    <RatingPrimitive
      @value={{@value}}
      @defaultValue={{@defaultValue}}
      @onValueChange={{@onValueChange}}
      @max={{@max}}
      @step={{@step}}
      @readonly={{@readonly}}
      @interactive={{@interactive}}
      @disabled={{@disabled}}
      @itemLabel={{@itemLabel}}
      @summary={{@summary}}
      @formName={{@formName}}
      @name={{@name}}
      class="jn-rating"
      data-slot="rating"
      data-size={{this.size}}
      ...attributes
      as |r|
    >
      {{#if (has-block "label")}}
        {{#if r.needsSummary}}
          <span class="jn-rating-label" data-slot="rating-label" data-test-jn-part="label">{{yield
              (hash value=r.value total=r.total)
              to="label"
            }}</span>
        {{else}}
          <legend class="jn-rating-label" data-slot="rating-label" data-test-jn-part="label">{{yield
              (hash value=r.value total=r.total)
              to="label"
            }}</legend>
        {{/if}}
      {{else if r.needsSummary}}
        <VisuallyHidden data-test-jn-part="summary">{{r.summary}}</VisuallyHidden>
      {{/if}}
      <div class="jn-rating-items" data-slot="rating-items" data-test-jn-part="items">
        {{#each r.values as |value|}}
          <r.Item
            @value={{value}}
            class="jn-rating-item"
            data-slot="rating-item"
            data-half={{this.half value}}
          >
            <Icon @icon={{this.icon}} class="jn-rating-icon" />
          </r.Item>
        {{/each}}
      </div>
    </RatingPrimitive>
  </template>
}
