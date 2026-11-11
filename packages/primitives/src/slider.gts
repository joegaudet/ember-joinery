import Component from '@glimmer/component'
import type { TOC } from '@ember/component/template-only'
import { hash } from '@ember/helper'
import { on } from '@ember/modifier'
import { registerDestructor } from '@ember/destroyable'
import Modifier, { modifier } from 'ember-modifier'
import type { WithBoundArgs } from '@glint/template'
import { As, type TagName } from './as.gts'
import { ControllableState } from './controllable-state.ts'
import { getDirection, type Direction } from './direction.gts'
import { ignoreROError } from './resize-observer.ts'

/** Which way a slider runs: left to right (right to left in RTL text), or bottom to top. */
export type SliderOrientation = 'horizontal' | 'vertical'

/**
 * A slider's value: an array, one number per thumb (`[25, 75]` is a range), as Radix's, or a
 * number for one thumb, as ember-primitives' also takes. `@onValueChange` hears the same shape.
 */
export type SliderValue = number | number[]

/** Names a thumb (its `aria-label`), given its index and how many thumbs there are. */
export type SliderThumbLabel = (index: number, count: number) => string | undefined

const PAGE_KEYS = ['PageUp', 'PageDown']
const ARROW_KEYS = ['ArrowUp', 'ArrowDown', 'ArrowLeft', 'ArrowRight']
/** The keys that step back, by where the values start: Radix's `BACK_KEYS`. */
const BACK_KEYS: Record<'from-left' | 'from-right' | 'from-bottom' | 'from-top', string[]> = {
  'from-left': ['Home', 'PageDown', 'ArrowDown', 'ArrowLeft'],
  'from-right': ['Home', 'PageDown', 'ArrowDown', 'ArrowRight'],
  'from-bottom': ['Home', 'PageDown', 'ArrowDown', 'ArrowLeft'],
  'from-top': ['Home', 'PageDown', 'ArrowUp', 'ArrowLeft'],
}

function clamp(value: number, min: number, max: number): number {
  return Math.min(max, Math.max(min, value))
}

function getDecimalCount(value: number): number {
  return (String(value).split('.')[1] ?? '').length
}

function roundValue(value: number, decimalCount: number): number {
  const rounder = Math.pow(10, decimalCount)
  return Math.round(value * rounder) / rounder
}

/** Where a value sits between `min` and `max`, from 0 to 100. */
export function sliderPercent(value: number, min: number, max: number): number {
  if (max === min) return 0
  return clamp((100 / (max - min)) * (value - min), 0, 100)
}

/** The values with one replaced, sorted: Radix lets thumbs pass each other. */
function nextSortedValues(values: readonly number[], value: number, index: number): number[] {
  const next = [...values]
  next[index] = value
  return next.sort((a, b) => a - b)
}

function hasMinStepsBetween(values: readonly number[], minSteps: number): boolean {
  if (minSteps <= 0) return true
  const gaps = values.slice(0, -1).map((value, index) => values[index + 1]! - value)
  return Math.min(...gaps) >= minSteps
}

/** The index of the value nearest `value`; the first of two as near. */
function closestIndex(values: readonly number[], value: number): number {
  if (values.length <= 1) return 0
  const distances = values.map(other => Math.abs(other - value))
  return distances.indexOf(Math.min(...distances))
}

function linearScale(input: [number, number], output: [number, number]) {
  return (value: number): number => {
    if (input[0] === input[1] || output[0] === output[1]) return output[0]
    const ratio = (output[1] - output[0]) / (input[1] - input[0])
    return output[0] + ratio * (value - input[0])
  }
}

/** The tick values a `@step` array names: finite, unique, sorted; `null` for a number. */
function ticksOf(step: number | readonly number[] | undefined): number[] | null {
  if (!Array.isArray(step)) return null
  const ticks = [...new Set(step.filter(value => Number.isFinite(value)))].sort((a, b) => a - b)
  return ticks.length ? ticks : null
}

/**
 * A thumb's default name: `Value` for a slider's only thumb (as ember-primitives'), `Minimum` and
 * `Maximum` for a range, and `Value 2 of 3` past two (as Radix's). Pass `@getThumbLabel` for
 * other words, or another language.
 */
export function defaultSliderThumbLabel(index: number, count: number): string {
  if (count > 2) return `Value ${index + 1} of ${count}`
  if (count === 2) return index === 0 ? 'Minimum' : 'Maximum'
  return 'Value'
}

/** What a slider reads from its arguments. */
export interface SliderArgs {
  value?: SliderValue
  defaultValue?: SliderValue
  onValueChange?: (value: never) => void
  onValueCommit?: (value: never) => void
  min?: number
  max?: number
  step?: number | number[]
  minStepsBetweenThumbs?: number
  orientation?: SliderOrientation
  disabled?: boolean
  inverted?: boolean
  dir?: Direction
  getThumbLabel?: SliderThumbLabel
}

/** One thumb, as a slider yields it in `thumbs`: stable across changes, so `#each` keeps its DOM. */
export interface SliderThumbState {
  /** Which value it moves. */
  readonly index: number
  /** Its value. */
  readonly value: number
  /** Where it sits along the track, from 0 to 100. */
  readonly percent: number
}

/**
 * Which edge a part is placed from: the start of the line (`inset-inline-start`, so right to
 * left flips it with no script), its end when inverted, or the bottom (top when inverted).
 */
type Edge = 'inset-inline-start' | 'inset-inline-end' | 'bottom' | 'top'
const EDGES: Edge[] = ['inset-inline-start', 'inset-inline-end', 'bottom', 'top']

/**
 * A slider's state and behaviour, shared by its parts: Radix's slider, kept in Radix's terms.
 * With a `@step` array, it works on the ticks' indexes (`internal` values), evenly spaced, as
 * ember-primitives' does, and reports the ticks themselves.
 */
export class SliderStore {
  readonly #args: () => SliderArgs
  readonly state: ControllableState<SliderValue>
  readonly #thumbElements = new Map<number, HTMLElement>()
  readonly #thumbStates: SliderThumbState[] = []
  /** The value the keys and the pointer move: the thumb focused or pressed last. */
  #indexToChange = 0
  /** The pointer sliding a thumb, and the values before it started. */
  #sliding: { pointerId: number; target: Element; before: number[]; rect?: DOMRect } | undefined

  constructor(args: () => SliderArgs) {
    this.#args = args
    this.state = new ControllableState<SliderValue>({
      name: 'value',
      value: () => this.#args().value,
      defaultValue: () => this.#args().defaultValue ?? [this.min],
      onChange: () => this.#args().onValueChange as ((value: SliderValue) => void) | undefined,
      fallback: [],
    })
  }

  // ----- Settings ---------------------------------------------------------------------------

  /** The step array's values, sorted, or `null` when `@step` is a number. */
  get tickValues(): number[] | null {
    return ticksOf(this.#args().step)
  }

  /** The lowest value: `@min` (default 0), or the first tick. */
  get min(): number {
    return this.tickValues?.[0] ?? this.#args().min ?? 0
  }

  /** The highest value: `@max` (default 100), or the last tick. */
  get max(): number {
    return this.tickValues?.at(-1) ?? this.#args().max ?? 100
  }

  /** The step: `@step` (default 1); with ticks, 1 (from one tick to the next). */
  get step(): number {
    const step = this.#args().step
    return typeof step === 'number' && step > 0 ? step : 1
  }

  get orientation(): SliderOrientation {
    return this.#args().orientation ?? 'horizontal'
  }

  get isDisabled(): boolean {
    return this.#args().disabled ?? false
  }

  get isInverted(): boolean {
    return this.#args().inverted ?? false
  }

  get internalMin(): number {
    return this.tickValues ? 0 : this.min
  }

  get internalMax(): number {
    const ticks = this.tickValues
    return ticks ? ticks.length - 1 : this.max
  }

  get internalStep(): number {
    return this.tickValues ? 1 : this.step
  }

  // ----- Values -----------------------------------------------------------------------------

  /** The values, one per thumb, as the caller sees them. */
  get values(): number[] {
    const value = this.state.value
    return Array.isArray(value) ? value : [value]
  }

  /** The values on the internal scale: the nearest tick's index, with ticks. */
  get internalValues(): number[] {
    const ticks = this.tickValues
    if (!ticks) return this.values
    return this.values.map(value => closestIndex(ticks, value))
  }

  /** Each thumb's state, one per value, the same objects every time. */
  get thumbs(): SliderThumbState[] {
    const count = this.values.length
    const states = this.#thumbStates
    if (states.length > count) states.length = count
    while (states.length < count) states.push(this.#thumbState(states.length))
    return states
  }

  #thumbState(index: number): SliderThumbState {
    const value = () => this.values[index] ?? this.min
    const percent = () => this.percentAt(index)
    return {
      index,
      get value() {
        return value()
      },
      get percent() {
        return percent()
      },
    }
  }

  /** The value at a thumb, or `undefined` past the last. */
  valueAt = (index: number): number | undefined => this.values[index]

  /** Where a thumb sits along the track, from 0 to 100. */
  percentAt = (index: number): number => {
    const value = this.internalValues[index]
    if (value === undefined) return 0
    return sliderPercent(value, this.internalMin, this.internalMax)
  }

  /** A thumb's `aria-label`. */
  labelAt = (index: number): string | undefined => {
    const label = this.#args().getThumbLabel ?? defaultSliderThumbLabel
    return label(index, this.values.length)
  }

  /** Where the range starts and ends along the track, from 0 to 100. */
  get rangeOffsets(): { start: number; end: number } {
    const percents = this.internalValues.map(value =>
      sliderPercent(value, this.internalMin, this.internalMax),
    )
    return {
      start: percents.length > 1 ? Math.min(...percents) : 0,
      end: 100 - Math.max(...percents, 0),
    }
  }

  /** The edge the values start from, and the one they end at. */
  get edges(): { start: Edge; end: Edge } {
    const inverted = this.isInverted
    if (this.orientation === 'vertical') {
      return inverted ? { start: 'top', end: 'bottom' } : { start: 'bottom', end: 'top' }
    }
    return inverted
      ? { start: 'inset-inline-end', end: 'inset-inline-start' }
      : { start: 'inset-inline-start', end: 'inset-inline-end' }
  }

  /** Values on the internal scale, in the caller's terms and shape. */
  #output(internal: number[]): SliderValue {
    const ticks = this.tickValues
    const values = ticks
      ? internal.map(index => ticks[clamp(Math.round(index), 0, ticks.length - 1)]!)
      : internal
    return Array.isArray(this.state.value) ? values : (values[0] ?? this.min)
  }

  /**
   * Moves the thumb at `index` to `value` (internal), as Radix's `updateValues`: snapped to the
   * step, kept within bounds and `@minStepsBetweenThumbs` apart, and sorted, so a thumb dragged
   * past another swaps with it. Focus follows the value it moved.
   */
  update(value: number, index: number, { commit = false } = {}): void {
    const min = this.internalMin
    const max = this.internalMax
    const step = this.internalStep
    const snapped = roundValue(Math.round((value - min) / step) * step + min, getDecimalCount(step))
    const next = clamp(snapped, min, max)
    const previous = this.internalValues
    const values = nextSortedValues(previous, next, index)
    const minSteps = (this.#args().minStepsBetweenThumbs ?? 0) * step
    if (!hasMinStepsBetween(values, minSteps)) return
    this.#indexToChange = values.indexOf(next)
    if (String(values) === String(previous)) return
    this.state.set(this.#output(values))
    this.#thumbElements.get(this.#indexToChange)?.focus()
    if (commit) this.#commit(values)
  }

  #commit(internal: number[]): void {
    const onCommit = this.#args().onValueCommit as ((value: SliderValue) => void) | undefined
    onCommit?.(this.#output(internal))
  }

  // ----- Thumbs -----------------------------------------------------------------------------

  /** @internal Keeps each thumb's element, to focus it. */
  thumbElement = modifier((element: HTMLElement, [index]: [number]) => {
    this.#thumbElements.set(index, element)
    return () => {
      if (this.#thumbElements.get(index) === element) this.#thumbElements.delete(index)
    }
  })

  /** @internal A thumb took focus: the keys move it now. */
  focusThumb = (index: number): void => {
    this.#indexToChange = index
  }

  #thumbIndexOf(target: EventTarget | null): number | undefined {
    if (!(target instanceof Node)) return undefined
    for (const [index, element] of this.#thumbElements) {
      if (element.contains(target)) return index
    }
    return undefined
  }

  // ----- The pointer ------------------------------------------------------------------------

  /** The value under the pointer, from the root's box, as Radix's `getValueFromPointer`. */
  #valueFromPointer(event: PointerEvent, root: HTMLElement): number {
    const sliding = this.#sliding
    const rect = sliding?.rect ?? root.getBoundingClientRect()
    if (sliding) sliding.rect = rect
    const min = this.internalMin
    const max = this.internalMax
    if (this.orientation === 'vertical') {
      const fromBottom = !this.isInverted
      const scale = linearScale([0, rect.height], fromBottom ? [max, min] : [min, max])
      return scale(event.clientY - rect.top)
    }
    const ltr = getDirection(root, this.#args().dir) === 'ltr'
    const fromLeft = ltr !== this.isInverted
    const scale = linearScale([0, rect.width], fromLeft ? [min, max] : [max, min])
    return scale(event.clientX - rect.left)
  }

  /** @internal */
  onPointerDown = (event: PointerEvent): void => {
    if (this.isDisabled || event.defaultPrevented) return
    const root = event.currentTarget as HTMLElement
    const target = event.target as Element
    try {
      target.setPointerCapture(event.pointerId)
    } catch {
      // A pointer the browser doesn't know (a synthetic event) can't be captured.
    }
    event.preventDefault()
    this.#sliding = { pointerId: event.pointerId, target, before: this.internalValues }
    const thumb = this.#thumbIndexOf(target)
    if (thumb !== undefined) {
      this.#thumbElements.get(thumb)?.focus()
      return
    }
    const value = this.#valueFromPointer(event, root)
    this.update(value, closestIndex(this.internalValues, value))
  }

  /** @internal */
  onPointerMove = (event: PointerEvent): void => {
    if (this.#sliding?.pointerId !== event.pointerId) return
    const value = this.#valueFromPointer(event, event.currentTarget as HTMLElement)
    this.update(value, this.#indexToChange)
  }

  /** @internal */
  onPointerUp = (event: PointerEvent): void => {
    const sliding = this.#sliding
    if (sliding?.pointerId !== event.pointerId) return
    this.#sliding = undefined
    try {
      if (sliding.target.hasPointerCapture(event.pointerId)) {
        sliding.target.releasePointerCapture(event.pointerId)
      }
    } catch {
      // As above: nothing was captured.
    }
    const index = this.#indexToChange
    const values = this.internalValues
    if (values[index] !== sliding.before[index]) this.#commit(values)
  }

  // ----- The keys ---------------------------------------------------------------------------

  /** @internal Home, End, the arrows and Page Up and Down, as Radix's slider takes them. */
  onKeyDown = (event: KeyboardEvent): void => {
    if (event.defaultPrevented) return
    const { key } = event
    const disabled = this.isDisabled
    if (key === 'Home') {
      if (!disabled) this.update(this.internalMin, 0, { commit: true })
    } else if (key === 'End') {
      if (!disabled) this.update(this.internalMax, this.values.length - 1, { commit: true })
    } else if (PAGE_KEYS.includes(key) || ARROW_KEYS.includes(key)) {
      if (!disabled) this.#step(event)
    } else {
      return
    }
    event.preventDefault()
  }

  #step(event: KeyboardEvent): void {
    const root = event.currentTarget as HTMLElement
    let from: keyof typeof BACK_KEYS
    if (this.orientation === 'vertical') {
      from = this.isInverted ? 'from-top' : 'from-bottom'
    } else {
      const ltr = getDirection(root, this.#args().dir) === 'ltr'
      from = ltr !== this.isInverted ? 'from-left' : 'from-right'
    }
    const direction = BACK_KEYS[from].includes(event.key) ? -1 : 1
    const isSkip =
      PAGE_KEYS.includes(event.key) || (event.shiftKey && ARROW_KEYS.includes(event.key))
    const index = this.#indexToChange
    const value = this.internalValues[index]
    if (value === undefined) return
    const step = this.internalStep * (isSkip ? 10 : 1) * direction
    this.update(value + step, index, { commit: true })
  }
}

// ----- Placing the parts --------------------------------------------------------------------

/** Sets one edge (and clears the others) through the CSSOM, which a strict CSP allows. */
function place(element: HTMLElement, values: Partial<Record<Edge, string>>): void {
  for (const edge of EDGES) {
    const value = values[edge]
    if (value === undefined) element.style.removeProperty(edge)
    else element.style.setProperty(edge, value)
  }
}

interface RangePositionSignature {
  Element: HTMLElement
  Args: { Named: { start: number; end: number; startEdge: Edge; endEdge: Edge } }
}

/** Stretches the range between its offsets, as Radix's `SliderRange` style does. */
const rangePosition = modifier<RangePositionSignature>(
  (element, _, { start, end, startEdge, endEdge }) => {
    place(element, { [startEdge]: `${start}%`, [endEdge]: `${end}%` })
  },
)

interface ThumbPositionSignature {
  Element: HTMLElement
  Args: { Named: { percent: number; edge: Edge; vertical: boolean } }
}

/**
 * A thumb's length along the track: its layout size (a transformed ancestor, such as a scaled
 * preview, doesn't change it), as the `ResizeObserver` reports it after.
 */
function measure(element: HTMLElement, vertical: boolean): number {
  return vertical ? element.offsetHeight : element.offsetWidth
}

/**
 * Places a thumb at its value, kept inside the track: its start edge at `percent` of the
 * length, less that share of its own size, so it touches each end at the min and max. That is
 * where Radix's `getThumbInBoundsOffset` puts it, with a logical edge in place of `left` or
 * `right`, so right to left needs no script. The thumb's size is measured, and watched.
 */
class ThumbPosition extends Modifier<ThumbPositionSignature> {
  #element: HTMLElement | undefined
  #size = 0
  #vertical = false
  #percent = 0
  #edge: Edge = 'inset-inline-start'

  override modify(
    element: HTMLElement,
    _: [],
    { percent, edge, vertical }: ThumbPositionSignature['Args']['Named'],
  ): void {
    this.#percent = percent
    this.#edge = edge
    this.#vertical = vertical
    if (!this.#element) {
      this.#element = element
      element.style.setProperty('position', 'absolute')
      this.#size = measure(element, vertical)
      ignoreROError()
      const observer = new ResizeObserver(([entry]) => {
        const box = entry?.borderBoxSize?.[0]
        if (!box) return
        const size = this.#vertical ? box.blockSize : box.inlineSize
        if (size === this.#size) return
        this.#size = size
        this.#place()
      })
      observer.observe(element, { box: 'border-box' })
      registerDestructor(this, () => observer.disconnect())
    } else {
      this.#size = measure(element, vertical)
    }
    this.#place()
  }

  #place(): void {
    const element = this.#element
    if (!element) return
    const offset = (this.#percent / 100) * this.#size
    place(element, { [this.#edge]: `calc(${this.#percent}% - ${offset}px)` })
  }
}

interface BubbleValueSignature {
  Element: HTMLInputElement
  Args: { Named: { value: number | undefined } }
}

/**
 * Keeps a thumb's hidden form input at its value, and tells the form when it changes with a
 * bubbling `input` event, as Radix's `SliderBubbleInput` does.
 */
class BubbleValue extends Modifier<BubbleValueSignature> {
  #value: string | undefined

  override modify(element: HTMLInputElement, _: [], { value }: { value: number | undefined }) {
    const next = value === undefined ? '' : String(value)
    const previous = this.#value
    this.#value = next
    element.value = next
    if (previous !== undefined && previous !== next) {
      element.dispatchEvent(new Event('input', { bubbles: true }))
    }
  }
}

// ----- The parts ----------------------------------------------------------------------------

export interface SliderTrackSignature {
  Args: {
    /** The tag to render. Default `span`. */
    as?: TagName
    /** @internal Bound by the slider. */
    store: SliderStore
  }
  /** The range, usually. */
  Blocks: { default: [] }
  Element: HTMLElement
}

/** The rail the thumbs move along: Radix's `Slider.Track`. */
export const SliderTrack: TOC<SliderTrackSignature> = <template>
  <As
    @as={{@as}}
    @tag="span"
    data-orientation={{@store.orientation}}
    data-disabled={{if @store.isDisabled ""}}
    data-test-jn-part="track"
    ...attributes
  >{{yield}}</As>
</template>

export interface SliderRangeSignature {
  Args: {
    /** The tag to render. Default `span`. */
    as?: TagName
    /** @internal Bound by the slider. */
    store: SliderStore
  }
  Element: HTMLElement
}

/**
 * The filled part of the track: Radix's `Slider.Range`, from the start to the thumb, or
 * between the outermost thumbs. It places itself (position it `absolute` in your CSS).
 */
export const SliderRange: TOC<SliderRangeSignature> = <template>
  {{#let @store.rangeOffsets @store.edges as |offsets edges|}}
    <As
      @as={{@as}}
      @tag="span"
      data-orientation={{@store.orientation}}
      data-disabled={{if @store.isDisabled ""}}
      data-test-jn-part="range"
      ...attributes
      {{rangePosition start=offsets.start end=offsets.end startEdge=edges.start endEdge=edges.end}}
    />
  {{/let}}
</template>

export interface SliderThumbSignature {
  Args: {
    /** Which value it moves, from 0. Default 0. Render one for each of `s.thumbs`. */
    index?: number
    /** The tag to render. Default `span`. */
    as?: TagName
    /** Its form field name, when the slider's `@fieldName` isn't the one. */
    fieldName?: string
    /** @internal Bound by the slider. */
    store: SliderStore
    /** @internal Bound by the slider. */
    sliderFieldName?: string
    /** @internal Bound by the slider. */
    form?: string
  }
  /** What the thumb shows inside it, if anything: a tooltip with its value, say. */
  Blocks: { default: [] }
  /** The `role="slider"` element: it takes the focus, the keys and the ARIA. */
  Element: HTMLElement
}

/**
 * A thumb: Radix's `Slider.Thumb`, a `role="slider"` element in the tab order with the value in
 * ARIA, inside a span that places it. With a field name, a hidden input beside it puts the value
 * in its form.
 */
export class SliderThumb extends Component<SliderThumbSignature> {
  get index(): number {
    return this.args.index ?? 0
  }

  get value(): number | undefined {
    return this.args.store.valueAt(this.index)
  }

  get fieldName(): string | undefined {
    const name = this.args.fieldName ?? this.args.sliderFieldName
    if (!name) return undefined
    return this.args.fieldName || this.args.store.values.length <= 1 ? name : `${name}[]`
  }

  onFocus = (): void => this.args.store.focusThumb(this.index)

  <template>
    {{#let @store.edges as |edges|}}
      <span
        {{ThumbPosition
          percent=(@store.percentAt this.index)
          edge=edges.start
          vertical=(isVertical @store.orientation)
        }}
      >
        <As
          @as={{@as}}
          @tag="span"
          role="slider"
          aria-label={{@store.labelAt this.index}}
          aria-valuemin={{@store.min}}
          aria-valuenow={{this.value}}
          aria-valuemax={{@store.max}}
          aria-orientation={{@store.orientation}}
          data-orientation={{@store.orientation}}
          data-disabled={{if @store.isDisabled ""}}
          tabindex={{if @store.isDisabled undefined "0"}}
          hidden={{isMissing this.value}}
          data-test-jn-part="thumb"
          data-test-jn-value="{{this.index}}"
          ...attributes
          {{@store.thumbElement this.index}}
          {{on "focus" this.onFocus}}
        >{{yield}}</As>
        {{#if this.fieldName}}
          <input
            type="hidden"
            name={{this.fieldName}}
            form={{@form}}
            {{BubbleValue value=this.value}}
          />
        {{/if}}
      </span>
    {{/let}}
  </template>
}

function isVertical(orientation: SliderOrientation): boolean {
  return orientation === 'vertical'
}

function isMissing(value: number | undefined): boolean {
  return value === undefined
}

/** What `<Slider>` yields. */
export interface SliderYield {
  /** The rail: `<s.Track><s.Range /></s.Track>`. */
  Track: WithBoundArgs<typeof SliderTrack, 'store'>
  /** The filled part of the track. */
  Range: WithBoundArgs<typeof SliderRange, 'store'>
  /** A thumb: `<s.Thumb @index={{thumb.index}} />` for each of `thumbs`. */
  Thumb: WithBoundArgs<typeof SliderThumb, 'store' | 'sliderFieldName' | 'form'>
  /** One per value, the same objects as they change, for `{{#each s.thumbs as |thumb|}}`. */
  thumbs: SliderThumbState[]
  /** The values, as numbers, one per thumb. */
  values: number[]
  /** The step array's values, sorted, or `null` when `@step` is a number. */
  tickValues: number[] | null
  /** The lowest value. */
  min: number
  /** The highest value. */
  max: number
  /** The step (1 with ticks: one tick to the next). */
  step: number
  orientation: SliderOrientation
  isDisabled: boolean
}

export interface SliderSignature<T extends SliderValue = number[]> {
  Args: {
    /** The controlled value: one number per thumb (`[25, 75]`), or a number for one thumb. */
    value?: T
    /** The first value, when uncontrolled. Default `[min]`. */
    defaultValue?: T
    /** Called with each new value, in the shape it was given, as it slides and steps. */
    onValueChange?: (value: T) => void
    /** Called with the value when a slide ends, or a key has moved it. */
    onValueCommit?: (value: T) => void
    /** The lowest value. Default 0. */
    min?: number
    /** The highest value. Default 100. */
    max?: number
    /**
     * How far each step moves. Default 1. An array of values makes the slider snap to them
     * (ticks, as ember-primitives' `@step` array), evenly spaced along the track.
     */
    step?: number | number[]
    /** The fewest steps thumbs keep between them. Default 0: they can meet, and pass. */
    minStepsBetweenThumbs?: number
    /** Default `horizontal`. */
    orientation?: SliderOrientation
    /** Whether it can't be moved. */
    disabled?: boolean
    /** Run the values the other way: from the end of the line, or from the top. */
    inverted?: boolean
    /** The text direction; by default the document's, from the nearest `dir`. */
    dir?: Direction
    /**
     * Names each thumb (its `aria-label`). Default `defaultSliderThumbLabel`: `Value`, or
     * `Minimum` and `Maximum`, or `Value 2 of 3`.
     */
    getThumbLabel?: SliderThumbLabel
    /**
     * The form field each thumb's value submits as (Radix's `name`; `name[]` for several
     * thumbs). Without it, nothing is submitted.
     */
    fieldName?: string
    /** The `id` of the form the values belong to, when the slider isn't inside it. */
    form?: string
    /** The tag to render. Default `span`. */
    as?: TagName
    /** Its name, for `SliderHarness` (`data-test-jn-name`). */
    name?: string
  }
  Blocks: { default: [SliderYield] }
  Element: HTMLElement
}

/**
 * A control for choosing a value, or a range, from within bounds: Radix's `Slider`, headless,
 * which also covers ember-primitives' (range and multiple thumbs, discrete values, vertical).
 * It yields its parts, which you render and style:
 *
 *   <Slider @defaultValue={{array 25 75}} @step={{5}} as |s|>
 *     <s.Track><s.Range /></s.Track>
 *     {{#each s.thumbs as |thumb|}}
 *       <s.Thumb @index={{thumb.index}} />
 *     {{/each}}
 *   </Slider>
 *
 * Each thumb is a `role="slider"` element in the tab order: the arrows step it, Shift with an
 * arrow and Page Up and Down step ten times as far, and Home and End go to the bounds. Pressing
 * the track moves the nearest thumb there, and dragging slides it. The range and the thumbs
 * place themselves with logical edges, so right to left flips them, and the keys follow.
 */
export class Slider<T extends SliderValue = number[]> extends Component<SliderSignature<T>> {
  store = new SliderStore(() => this.args as SliderArgs)

  <template>
    <As
      @as={{@as}}
      @tag="span"
      dir={{@dir}}
      aria-disabled={{if this.store.isDisabled "true"}}
      data-disabled={{if this.store.isDisabled ""}}
      data-orientation={{this.store.orientation}}
      data-test-jn="slider"
      data-test-jn-name={{@name}}
      ...attributes
      {{on "pointerdown" this.store.onPointerDown}}
      {{on "pointermove" this.store.onPointerMove}}
      {{on "pointerup" this.store.onPointerUp}}
      {{on "pointercancel" this.store.onPointerUp}}
      {{on "keydown" this.store.onKeyDown}}
    >
      {{yield
        (hash
          Track=(component SliderTrack store=this.store)
          Range=(component SliderRange store=this.store)
          Thumb=(component SliderThumb store=this.store sliderFieldName=@fieldName form=@form)
          thumbs=this.store.thumbs
          values=this.store.values
          tickValues=this.store.tickValues
          min=this.store.min
          max=this.store.max
          step=this.store.internalStep
          orientation=this.store.orientation
          isDisabled=this.store.isDisabled
        )
      }}
    </As>
  </template>
}

export default Slider
