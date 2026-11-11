import Component from '@glimmer/component'
import type { ControlSignature } from '@ember-formwright/ember'
import { Icon, type IconNode, type RatingSize } from '@ember-joinery/ember'
import { Rating, defaultRatingItemLabel, ratingPercent } from '@ember-joinery/primitives/rating'
import { VisuallyHidden } from '@ember-joinery/primitives/visually-hidden'
import { Star } from 'lucide'
import { toNumber } from '../-private/options.ts'

export interface RatingControlSignature {
  Args: ControlSignature<number | null>['Args'] & {
    /** Its stars' size, as Rating's `@size`: `sm` 16px, `default` 20px, `lg` 24px. */
    size?: RatingSize
    /** The star: a `lucide` icon. Default lucide's `Star`. */
    icon?: IconNode
    /** Each star's name for assistive technology. Default `1 star`, `2 stars`… */
    itemLabel?: (value: number) => string
  }
  /** The Rating's root, a `<fieldset>` of the stars' radios. */
  Element: HTMLFieldSetElement
}

/** Which half of a star an item draws, in a half rating (`@step={{0.5}}`), as Rating's do. */
function halfOf(value: number, step: number): 'start' | 'end' | undefined {
  if (step !== 0.5) return undefined
  return value % 1 === 0.5 ? 'start' : 'end'
}

/**
 * Joinery's Rating as a Formwright control, `@control="rating"`: stars from 1 to `@max` (5 by
 * default), in steps of `@step` (`0.5` for half stars). It stores the rating picked, or `null`
 * for none: picking the rating already picked clears it, as Rating's does. Each star is a
 * native radio, so the arrow keys move between them and the group is one tab stop.
 *
 * Its root, the Rating's `<fieldset role="radiogroup">`, takes the field's id and is named
 * after the field's label (`aria-label`), since a `<label>` can't name a fieldset: so the
 * stars are one named group, and the field needs no `FieldSet` of its own around it (which
 * would make it a second group, unnamed, inside the first). Each radio is described by the
 * field's hint and errors and is `aria-invalid` while the field is, since the radios are what
 * takes the focus. Read-only, the stars show the rating and take the focus but can't change it
 * (`aria-readonly`), as Rating's do.
 *
 * It renders Joinery's Rating markup on the primitive itself (the styled Rating's classes and
 * `data-slot`s, which a test holds to the styled one), since the styled Rating passes nothing
 * to its radios.
 */
export class RatingControl extends Component<RatingControlSignature> {
  get value(): number {
    const value = this.args.value
    return typeof value === 'number' && !Number.isNaN(value) ? value : 0
  }

  get step(): number {
    return toNumber(this.args.step) ?? 1
  }

  get icon(): IconNode {
    return this.args.icon ?? Star
  }

  get size(): RatingSize {
    return this.args.size ?? 'default'
  }

  /** Each radio's id: the root has the field's. */
  idFor = (index: number): string => `${this.args.id}-${index}`
  half = (value: number): 'start' | 'end' | undefined => halfOf(value, this.step)
  labelFor = (value: number): string => (this.args.itemLabel ?? defaultRatingItemLabel)(value)
  isSelected = (value: number, rating: number): boolean => value <= rating
  isChecked = (value: number, rating: number): boolean => value === rating
  percentFor = (value: number, rating: number): number => ratingPercent(value, rating, this.step)

  onValueChange = (value: number): void => {
    this.args.onChange(value === 0 ? null : value)
  }

  <template>
    <Rating
      @value={{this.value}}
      @onValueChange={{this.onValueChange}}
      @max={{toNumber @max}}
      @step={{this.step}}
      @readonly={{@readonly}}
      @disabled={{@disabled}}
      @formName={{@name}}
      id={{@id}}
      aria-label={{@label}}
      class="jn-rating"
      data-slot="rating"
      data-size={{this.size}}
      data-test-fw-control={{@type}}
      ...attributes
      as |r|
    >
      <div class="jn-rating-items" data-slot="rating-items" data-test-jn-part="items">
        {{#each r.values as |value index|}}
          {{! The primitive's Item, with what the field puts on its control on the radio. }}
          <span
            class="jn-rating-item"
            data-slot="rating-item"
            data-half={{this.half value}}
            data-number={{value}}
            data-selected={{this.isSelected value r.value}}
            data-percent-selected={{this.percentFor value r.value}}
            data-readonly={{r.isReadonly}}
            data-disabled={{@disabled}}
            data-test-jn-part="item"
            data-test-jn-value={{value}}
          >
            <label for={{this.idFor index}}>
              <VisuallyHidden>{{this.labelFor value}}</VisuallyHidden>
              <span aria-hidden="true"><Icon @icon={{this.icon}} class="jn-rating-icon" /></span>
            </label>
            <input
              id={{this.idFor index}}
              type="radio"
              name={{r.name}}
              value={{value}}
              checked={{this.isChecked value r.value}}
              disabled={{@disabled}}
              aria-describedby={{@describedBy}}
              aria-invalid={{if @invalid "true"}}
              data-test-jn-part="input"
              data-test-fw-option={{value}}
            />
          </span>
        {{/each}}
      </div>
    </Rating>
  </template>
}
