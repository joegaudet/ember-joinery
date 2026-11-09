import Component from '@glimmer/component'
import type { TagName } from '@ember-joinery/primitives/as'
import type { Direction } from '@ember-joinery/primitives/direction'
import {
  Slider as SliderPrimitive,
  type SliderOrientation,
  type SliderThumbLabel,
  type SliderValue,
} from '@ember-joinery/primitives/slider'

export interface SliderSignature<T extends SliderValue = number[]> {
  Args: {
    /** The controlled value: one number per thumb (`[25, 75]` is a range). */
    value?: T
    /** The first value, when uncontrolled. Default `[min]`. */
    defaultValue?: T
    /** Called with each new value as it slides and steps. */
    onValueChange?: (value: T) => void
    /** Called with the value when a slide ends, or a key has moved it. */
    onValueCommit?: (value: T) => void
    /** The lowest value. Default 0. */
    min?: number
    /** The highest value. Default 100. */
    max?: number
    /** How far each step moves. Default 1. An array makes it snap to those values. */
    step?: number | number[]
    /** The fewest steps thumbs keep between them. Default 0. */
    minStepsBetweenThumbs?: number
    /** Default `horizontal`. A vertical slider is at least 10rem tall. */
    orientation?: SliderOrientation
    /** Whether it can't be moved. */
    disabled?: boolean
    /** Run the values the other way: from the end of the line, or from the top. */
    inverted?: boolean
    /** The text direction; by default the document's, from the nearest `dir`. */
    dir?: Direction
    /** Names each thumb. Default `Value`, or `Minimum` and `Maximum`, or `Value 2 of 3`. */
    getThumbLabel?: SliderThumbLabel
    /** The form field the values submit as (`name[]` for several thumbs). */
    fieldName?: string
    /** The `id` of the form the values belong to, when the slider isn't inside it. */
    form?: string
    /** The tag to render. Default `span`. */
    as?: TagName
    /** Its name, for `SliderHarness` (`data-test-jn-name`). */
    name?: string
  }
  /** The root `<span>`: size it with a class (`w-full max-w-xs`, `h-40` when vertical). */
  Element: HTMLElement
}

/**
 * An input where the user selects a value from within a given range: shadcn's Slider, on the
 * primitives' `Slider`. Give it an array, one number per thumb:
 *
 *   <Slider @defaultValue={{array 75}} @max={{100}} @step={{1}} class="w-full max-w-xs" />
 *   <Slider @value={{this.range}} @onValueChange={{this.setRange}} />
 *
 * It renders upstream's track, range and one thumb per value. Each thumb is a `role="slider"`
 * in the tab order, which the arrow keys, Page Up and Down, Home and End move.
 */
export default class Slider<T extends SliderValue = number[]> extends Component<
  SliderSignature<T>
> {
  <template>
    <SliderPrimitive
      @value={{@value}}
      @defaultValue={{@defaultValue}}
      @onValueChange={{@onValueChange}}
      @onValueCommit={{@onValueCommit}}
      @min={{@min}}
      @max={{@max}}
      @step={{@step}}
      @minStepsBetweenThumbs={{@minStepsBetweenThumbs}}
      @orientation={{@orientation}}
      @disabled={{@disabled}}
      @inverted={{@inverted}}
      @dir={{@dir}}
      @getThumbLabel={{@getThumbLabel}}
      @fieldName={{@fieldName}}
      @form={{@form}}
      @as={{@as}}
      @name={{@name}}
      class="jn-slider"
      data-slot="slider"
      ...attributes
      as |s|
    >
      <s.Track class="jn-slider-track" data-slot="slider-track">
        <s.Range class="jn-slider-range" data-slot="slider-range" />
      </s.Track>
      {{#each s.thumbs as |thumb|}}
        <s.Thumb @index={{thumb.index}} class="jn-slider-thumb" data-slot="slider-thumb" />
      {{/each}}
    </SliderPrimitive>
  </template>
}
