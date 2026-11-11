import Component from '@glimmer/component'
import type { TOC } from '@ember/component/template-only'
import { cached } from '@glimmer/tracking'
import { hash } from '@ember/helper'
import { on } from '@ember/modifier'
import type { ComponentLike, WithBoundArgs } from '@glint/template'
import { ControllableState } from './controllable-state.ts'
import { idFor } from './id.ts'
import { VisuallyHidden } from './visually-hidden.gts'
import { format, translate } from './i18n.ts'
import { messages } from './messages.ts'

/** What a component given as a rating's `@icon` receives, for each item. */
export interface RatingIconSignature {
  Element: HTMLElement
  Args: {
    /** Whether the rating reaches this item. */
    isSelected: boolean
    /** The item's value: 1, 2, 3… (or 0.5, 1, 1.5… with `@step={{0.5}}`). */
    value: number
    /** How much of the item the rating fills, from 0 to 100. */
    percentSelected: number
    /** Whether the rating can't be changed. */
    readonly: boolean
  }
}

/** An item's icon: a string (default `★`), or a component that draws it. */
export type RatingIcon = string | ComponentLike<RatingIconSignature>

/** What a rating's `<:label>` block, and its summary, are given. */
export interface RatingSummary {
  /** The current rating. */
  value: number
  /** How many items it has. */
  total: number
}

/** A number without the floating-point dust of adding steps (`0.1 + 0.2`). */
function tidy(value: number): number {
  return Math.round(value * 1e6) / 1e6
}

/** The value each item stands for: `step`, `2 × step`… up to `max`. */
export function ratingValues(max: number, step: number): number[] {
  if (!(step > 0) || !(max > 0)) return []
  const values: number[] = []
  for (let index = 1; tidy(index * step) <= max; index++) values.push(tidy(index * step))
  return values
}

/** How much of the item that stands for `item` a rating of `value` fills, from 0 to 100. */
export function ratingPercent(item: number, value: number, step: number): number {
  const filled = (value - (item - step)) / step
  return Math.round(Math.min(1, Math.max(0, filled)) * 100)
}

function isString(value: unknown): value is string {
  return typeof value === 'string'
}

function lte(a: number, b: number): boolean {
  return a <= b
}

/** The English default for an item's name: `1 star`, `2 stars`, `2.5 stars`. */
export function defaultRatingItemLabel(value: number): string {
  return format(messages.ratingItem, { count: value })
}

/** The English default for a display-only rating's summary: `Rated 3 out of 5`. */
export function defaultRatingSummary({ value, total }: RatingSummary): string {
  return format(messages.ratingSummary, { value, total })
}

interface RatingItemSignature {
  Args: {
    /** The value choosing this item sets the rating to. */
    value: number
    /** @internal Bound by the rating. */
    rating: Rating
  }
  Blocks: {
    /** What the item shows, hidden from assistive technology: its icon. */
    default: [item: { isSelected: boolean; percentSelected: number; value: number }]
  }
  Element: HTMLSpanElement
}

/**
 * One item of a rating, yielded as `rating.Item`: a `<span>` holding a `<label>` (its name for
 * assistive technology, and what the block draws) and the native radio it labels.
 */
class RatingItem extends Component<RatingItemSignature> {
  get id(): string {
    return idFor(this, 'input')
  }

  get isSelected(): boolean {
    return lte(this.args.value, this.args.rating.value)
  }

  get isChecked(): boolean {
    return this.args.value === this.args.rating.value
  }

  get percentSelected(): number {
    return ratingPercent(this.args.value, this.args.rating.value, this.args.rating.step)
  }

  get label(): string {
    const { itemLabel } = this.args.rating.args
    const value = this.args.value
    return itemLabel ? itemLabel(value) : translate(this, messages.ratingItem, { count: value })
  }

  <template>
    <span
      data-number={{@value}}
      data-selected={{this.isSelected}}
      data-percent-selected={{this.percentSelected}}
      data-readonly={{@rating.isReadonly}}
      data-disabled={{@rating.args.disabled}}
      data-test-jn-part="item"
      data-test-jn-value={{@value}}
      ...attributes
    >
      <label for={{this.id}}>
        <VisuallyHidden>{{this.label}}</VisuallyHidden>
        <span aria-hidden="true">{{yield
            (hash isSelected=this.isSelected percentSelected=this.percentSelected value=@value)
          }}</span>
      </label>
      <input
        id={{this.id}}
        type="radio"
        name={{@rating.name}}
        value={{@value}}
        checked={{this.isChecked}}
        disabled={{@rating.args.disabled}}
        data-test-jn-part="input"
      />
    </span>
  </template>
}

interface RatingStarsSignature {
  Args: {
    /** What each item shows. Default: the rating's `@icon`. */
    icon?: RatingIcon
    /** @internal Bound by the rating. */
    rating: Rating
  }
  Element: HTMLDivElement
}

/** Every item of a rating, each with its icon, in a `<div>`: yielded as `rating.Stars`. */
class RatingStars extends Component<RatingStarsSignature> {
  get icon(): RatingIcon {
    return this.args.icon ?? this.args.rating.icon
  }

  /** The icon, when it is a string. */
  get text(): string | undefined {
    const { icon } = this
    return isString(icon) ? icon : undefined
  }

  /** The icon, when it is a component. */
  get Icon(): ComponentLike<RatingIconSignature> | undefined {
    const { icon } = this
    return isString(icon) ? undefined : icon
  }

  <template>
    <div data-test-jn-part="items" ...attributes>
      {{#each @rating.values as |value|}}
        <RatingItem @value={{value}} @rating={{@rating}} as |item|>
          {{#if this.Icon}}
            <this.Icon
              @value={{value}}
              @isSelected={{item.isSelected}}
              @percentSelected={{item.percentSelected}}
              @readonly={{@rating.isReadonly}}
            />
          {{else}}
            {{this.text}}
          {{/if}}
        </RatingItem>
      {{/each}}
    </div>
  </template>
}

interface RatingRangeSignature {
  Args: {
    /** @internal Bound by the rating. */
    rating: Rating
  }
  Element: HTMLInputElement
}

/**
 * A range input for the same rating, yielded as `rating.Range`: the way to pick a value
 * between the items' (a `step` of its own, such as `0.25`). Name it with `aria-label`.
 */
const RatingRange: TOC<RatingRangeSignature> = <template>
  <input
    min="0"
    step={{@rating.step}}
    data-test-jn-part="range"
    ...attributes
    name={{@rating.name}}
    type="range"
    max={{@rating.max}}
    value={{@rating.value}}
    disabled={{@rating.args.disabled}}
    {{on "change" @rating.handleChange}}
  />
</template>

export interface RatingSignature {
  Args: {
    /** The controlled rating. `0` is none. */
    value?: number
    /** The first rating, when uncontrolled. Default `0`. */
    defaultValue?: number
    /**
     * Called with each rating the user picks: the item's value, or `0` when they pick the
     * one already picked, which clears it.
     */
    onValueChange?: (value: number) => void
    /** The highest rating. Default `5`. */
    max?: number
    /**
     * What each item adds to the rating. Default `1`; `0.5` makes an item of each half, for
     * half ratings.
     */
    step?: number
    /** Whether the rating shows but can't be changed (`aria-readonly`). */
    readonly?: boolean
    /**
     * Whether it is a control at all. Default `true`. With `false` it only shows `@value`,
     * which it summarises for assistive technology: "Rated 3 out of 5".
     */
    interactive?: boolean
    /** Whether it is disabled: a `<fieldset disabled>`, which disables every item. */
    disabled?: boolean
    /** What each item shows: a string (default `★`), or a component given `RatingIconSignature`. */
    icon?: RatingIcon
    /** Each item's name for assistive technology. Default `1 star`, `2 stars`… */
    itemLabel?: (value: number) => string
    /** What a display-only rating says. Default `Rated 3 out of 5`. */
    summary?: (state: RatingSummary) => string
    /** The form field the rating submits as, in a form: the radios' `name`. Default: one of its own. */
    formName?: string
    /** Its name, for `RatingHarness` (`data-test-jn-name`). Its form field is `@formName`. */
    name?: string
  }
  Blocks: {
    /**
     * Lay it out yourself. Without a block, it renders its `<:label>` (as a `<legend>`), or its
     * summary, then its items.
     */
    default: [
      rating: {
        /** The current rating. */
        value: number
        /** The highest rating. */
        max: number
        /** How many items it has. */
        total: number
        /** Each item's value. */
        values: number[]
        /** The radios' `name`. */
        name: string
        /** Whether it can't be changed: `@readonly`, or not `@interactive`. */
        isReadonly: boolean
        /** Whether it can be changed. */
        isChangeable: boolean
        /** Whether it is display-only, so it should say its rating for assistive technology. */
        needsSummary: boolean
        /** Its summary, as `@summary` words it. */
        summary: string
        /** Every item with its icon: `<rating.Stars @icon={{MyStar}} />`. */
        Stars: WithBoundArgs<typeof RatingStars, 'rating'>
        /** One item: `<rating.Item @value={{2}} as |item|>…</rating.Item>`. */
        Item: WithBoundArgs<typeof RatingItem, 'rating'>
        /** A range input for finer values: `<rating.Range step="0.25" aria-label="Rating" />`. */
        Range: WithBoundArgs<typeof RatingRange, 'rating'>
      },
    ]
    /** Its label: a `<legend>` that names the group, or, display-only, its visible summary. */
    label: [state: RatingSummary]
  }
  /** A `<fieldset role="radiogroup">`: the items are native radios. */
  Element: HTMLFieldSetElement
}

/**
 * A rating, such as stars out of five: ember-primitives' Rating, headless. It is a
 * `<fieldset role="radiogroup">` of native radios, one per item, so the keyboard works as in any
 * radio group: Tab reaches it, the arrow keys move and pick, and Space picks. Picking the item
 * already picked clears the rating. `@step={{0.5}}` gives an item to each half, for half
 * ratings. Its value is controlled or not, as Radix's are:
 *
 *   <Rating @defaultValue={{3}} @onValueChange={{this.rate}}>
 *     <:label>Rate this recipe</:label>
 *   </Rating>
 *
 * It has no styles: style it through its data attributes (`data-selected` on each item), or use
 * `@ember-joinery/ember`'s Rating.
 */
export class Rating extends Component<RatingSignature> {
  selection = new ControllableState<number>({
    name: 'value',
    value: () => this.args.value,
    defaultValue: () => this.args.defaultValue,
    onChange: () => this.args.onValueChange,
    fallback: 0,
  })

  get value(): number {
    return this.selection.value ?? 0
  }

  get step(): number {
    return this.args.step ?? 1
  }

  get max(): number {
    return this.args.max ?? 5
  }

  @cached
  get values(): number[] {
    return ratingValues(this.max, this.step)
  }

  get total(): number {
    return this.values.length
  }

  get name(): string {
    return this.args.formName ?? idFor(this, 'rating')
  }

  get icon(): RatingIcon {
    return this.args.icon ?? '★'
  }

  get isInteractive(): boolean {
    return this.args.interactive ?? true
  }

  get isChangeable(): boolean {
    return !this.args.readonly && this.isInteractive && !this.args.disabled
  }

  get isReadonly(): boolean {
    return Boolean(this.args.readonly) || !this.isInteractive
  }

  get needsSummary(): boolean {
    return !this.isInteractive
  }

  get state(): RatingSummary {
    return { value: this.value, total: this.total }
  }

  get summary(): string {
    const { summary } = this.args
    const { value, total } = this.state
    return summary ? summary(this.state) : translate(this, messages.ratingSummary, { value, total })
  }

  /** @internal Picks `value`, or clears the rating when it is the one already picked. */
  pick(value: number): void {
    if (!this.isChangeable) return
    this.selection.set(value === this.value ? 0 : value)
  }

  /** @internal Reads a picked value, ignoring what isn't a number. */
  pickFrom(text: string): void {
    const value = parseFloat(text)
    if (!Number.isNaN(value)) this.pick(value)
  }

  /**
   * The radios are native, so a click checks one before the rating knows. A controlled rating
   * keeps its value until its caller passes a new one, so its radios are put back to match it
   * at once; when the caller does pass one, rendering checks the new radio.
   */
  #sync(fieldset: HTMLFieldSetElement): void {
    for (const input of fieldset.querySelectorAll<HTMLInputElement>(
      'input[type="radio"][data-test-jn-part="input"]',
    )) {
      if (input.name === this.name) input.checked = parseFloat(input.value) === this.value
    }
  }

  /**
   * One listener on the group hears every radio's click (keyboard picks fire one too). A click
   * on another input inside it, such as `rating.Range`, is left alone. Readonly, the click is
   * cancelled, which puts the browser's checked radio back.
   */
  handleClick = (event: Event): void => {
    const target = event.target
    if (!(target instanceof HTMLInputElement) || target.type !== 'radio') return
    if (target.name !== this.name) return
    if (!this.isChangeable) {
      event.preventDefault()
      return
    }
    this.pickFrom(target.value)
    if (this.selection.isControlled) this.#sync(event.currentTarget as HTMLFieldSetElement)
  }

  /** The range input's change: range inputs fire no click from the keyboard. */
  handleChange = (event: Event): void => {
    const target = event.target
    if (!(target instanceof HTMLInputElement)) return
    if (!this.isChangeable) return
    const value = parseFloat(target.value)
    if (Number.isNaN(value) || value === this.value) return
    this.selection.set(value)
  }

  <template>
    <fieldset
      role="radiogroup"
      aria-readonly={{if this.isReadonly "true"}}
      disabled={{@disabled}}
      data-total={{this.total}}
      data-value={{this.value}}
      data-readonly={{this.isReadonly}}
      data-disabled={{@disabled}}
      data-test-jn="rating"
      data-test-jn-name={{@name}}
      ...attributes
      {{! Event delegation: the clicks come from the radios inside, each its own control. }}
      {{on "click" this.handleClick}}
    >
      {{#if (has-block)}}
        {{yield
          (hash
            value=this.value
            max=this.max
            total=this.total
            values=this.values
            name=this.name
            isReadonly=this.isReadonly
            isChangeable=this.isChangeable
            needsSummary=this.needsSummary
            summary=this.summary
            Stars=(component RatingStars rating=this)
            Item=(component RatingItem rating=this)
            Range=(component RatingRange rating=this)
          )
        }}
      {{else}}
        {{#if this.needsSummary}}
          {{#if (has-block "label")}}
            <span data-test-jn-part="label">{{yield this.state to="label"}}</span>
          {{else}}
            <VisuallyHidden data-test-jn-part="summary">{{this.summary}}</VisuallyHidden>
          {{/if}}
        {{else if (has-block "label")}}
          <legend data-test-jn-part="label">{{yield this.state to="label"}}</legend>
        {{/if}}
        <RatingStars @rating={{this}} />
      {{/if}}
    </fieldset>
  </template>
}

export default Rating
