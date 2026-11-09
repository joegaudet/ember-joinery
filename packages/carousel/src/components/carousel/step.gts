import type { TOC } from '@ember/component/template-only'
import { get } from '@ember/helper'
import { on } from '@ember/modifier'
import { ChevronLeft, ChevronRight } from 'lucide'
import { part, type PartModifier } from '@ember-joinery/primitives/part'
import { VisuallyHidden } from '@ember-joinery/primitives/visually-hidden'
import Button, {
  buttonAttributes,
  buttonClasses,
  type ButtonSize,
  type ButtonVariant,
} from '@ember-joinery/ember/components/button'
import Icon, { type IconNode } from '@ember-joinery/ember/components/icon'
import type { CarouselOrientation, CarouselState } from './state.ts'

/** Which way a step button goes: to the previous slide, or the next. */
export type CarouselStep = 'previous' | 'next'

/** A step button's look: what both `<c.Previous>` and the `c.previous` modifier take. */
export interface CarouselStepOptions {
  /** Default `outline`, as upstream's. */
  variant?: ButtonVariant
  /** Default `icon-sm`, as upstream's. */
  size?: ButtonSize
  /** The button's name, for `ButtonHarness` (`data-test-jn-name`). */
  name?: string
}

/**
 * The classes a step button renders: a Button's (`outline`, `icon-sm` by default), then
 * upstream's `cn-carousel-previous` or `cn-carousel-next`, renamed `jn-`.
 */
export function stepClasses(step: CarouselStep, options: CarouselStepOptions = {}): string {
  const { variant = 'outline', size = 'icon-sm' } = options
  return `${buttonClasses({ variant, size })} jn-carousel-${step}`
}

/**
 * The attributes a step button renders: a Button's, with upstream's `data-slot`, the
 * orientation its rules key on, the content it controls, and `disabled` when there is nowhere
 * to go.
 */
export function stepAttributes(
  step: CarouselStep,
  options: CarouselStepOptions,
  state: { orientation: CarouselOrientation; contentId: string; canScroll: boolean },
): Record<string, string | boolean | undefined> {
  const { variant = 'outline', size = 'icon-sm', name } = options
  return {
    ...buttonAttributes({ variant, size, name }),
    'data-slot': `carousel-${step}`,
    'data-orientation': state.orientation,
    'data-test-jn-part': step,
    'aria-controls': state.contentId,
    disabled: !state.canScroll,
  }
}

/** A step button's state, read from the carousel's. */
function stateOf(carousel: CarouselState, step: CarouselStep) {
  return {
    orientation: carousel.orientation,
    contentId: carousel.contentId,
    canScroll: step === 'previous' ? carousel.canScrollPrev : carousel.canScrollNext,
  }
}

/**
 * A step button as a modifier, for a `<button>` (or button component) of your own, with the
 * same classes and attributes as `<c.Previous>` or `<c.Next>`, and a click that steps.
 */
export function stepModifier(
  carousel: CarouselState,
  step: CarouselStep,
): PartModifier<HTMLElement, CarouselStepOptions> {
  return part<HTMLElement, CarouselStepOptions>(options => ({
    class: stepClasses(step, options),
    attributes: stepAttributes(step, options, stateOf(carousel, step)),
    on: { click: step === 'previous' ? carousel.scrollPrev : carousel.scrollNext },
  }))
}

export interface CarouselStepSignature {
  Args: CarouselStepOptions & {
    /** The arrow: one from `lucide`. Default lucide's `chevron-left` or `chevron-right`. */
    icon?: IconNode
    /** Its name for assistive technology, visually hidden. Default `Previous slide` or `Next slide`. */
    label?: string
    /** @internal Bound by `<Carousel>`. */
    carousel: CarouselState
  }
  /** A `<button>` (a Button, which could be a link; the carousel's never is). */
  Element: HTMLButtonElement | HTMLAnchorElement
}

const attributesOf = (
  carousel: CarouselState,
  step: CarouselStep,
  variant: ButtonVariant | undefined,
  size: ButtonSize | undefined,
) => stepAttributes(step, { variant, size }, stateOf(carousel, step))

/**
 * The previous slide's button, yielded as `c.Previous`: an outline icon Button, outside the
 * slides at their start (above them, vertically), disabled when there is no slide before.
 */
export const CarouselPrevious: TOC<CarouselStepSignature> = <template>
  {{#let (attributesOf @carousel "previous" @variant @size) as |a|}}
    <Button
      @variant={{if @variant @variant "outline"}}
      @size={{if @size @size "icon-sm"}}
      @name={{@name}}
      type="button"
      class="jn-carousel-previous"
      data-slot={{get a "data-slot"}}
      data-orientation={{get a "data-orientation"}}
      data-test-jn-part={{get a "data-test-jn-part"}}
      aria-controls={{get a "aria-controls"}}
      disabled={{get a "disabled"}}
      ...attributes
      {{on "click" @carousel.scrollPrev}}
    >
      <Icon @icon={{if @icon @icon ChevronLeft}} class="jn-rtl-flip" />
      <VisuallyHidden>{{if @label @label "Previous slide"}}</VisuallyHidden>
    </Button>
  {{/let}}
</template>

/**
 * The next slide's button, yielded as `c.Next`: an outline icon Button, outside the slides at
 * their end (below them, vertically), disabled when there is no slide after.
 */
export const CarouselNext: TOC<CarouselStepSignature> = <template>
  {{#let (attributesOf @carousel "next" @variant @size) as |a|}}
    <Button
      @variant={{if @variant @variant "outline"}}
      @size={{if @size @size "icon-sm"}}
      @name={{@name}}
      type="button"
      class="jn-carousel-next"
      data-slot={{get a "data-slot"}}
      data-orientation={{get a "data-orientation"}}
      data-test-jn-part={{get a "data-test-jn-part"}}
      aria-controls={{get a "aria-controls"}}
      disabled={{get a "disabled"}}
      ...attributes
      {{on "click" @carousel.scrollNext}}
    >
      <Icon @icon={{if @icon @icon ChevronRight}} class="jn-rtl-flip" />
      <VisuallyHidden>{{if @label @label "Next slide"}}</VisuallyHidden>
    </Button>
  {{/let}}
</template>
