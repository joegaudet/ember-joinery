/*
 * The parts a polar chart (RadarChart, RadialBarChart) yields: its grid, its angle and radius
 * axes, its series (Radar, RadialBar), their labels, and the radius axis's Label. Each renders
 * nothing where it is written; it registers with the chart, which reads its arguments and draws
 * it in recharts' layers. The tooltip and legend are the cartesian charts' own parts.
 */
import Component from '@glimmer/component'
import { hash } from '@ember/helper'
import type Owner from '@ember/owner'
import type { ComponentLike, WithBoundArgs } from '@glint/template'
import { Registry } from './registry.ts'
import type { DataKey, DomainBound } from './cartesian.ts'
import type { DotArgs } from './parts.gts'
import type { PolarPosition, PolarTick, PolarViewBox } from './polar-geometry.ts'

/** What a polar part needs of its chart: somewhere to register. */
export interface PolarRegistrar {
  register(part: PolarPart): void
  unregister(part: PolarPart): void
}

/** Every part a polar chart reads, besides the tooltip and legend. */
export type PolarPart = PolarGrid | PolarAngleAxis | PolarRadiusAxis | Radar | RadialBar

interface PolarPartArgs {
  /** The chart it belongs to; the chart's yield passes it. */
  chart: PolarRegistrar
}

/** A part that registers with its chart while it is rendered. */
abstract class Part<S extends { Args: PolarPartArgs }> extends Component<S> {
  abstract readonly kind: string

  constructor(owner: Owner, args: S['Args']) {
    super(owner, args)
    args.chart.register(this as unknown as PolarPart)
  }

  override willDestroy(): void {
    super.willDestroy()
    this.args.chart.unregister(this as unknown as PolarPart)
  }
}

// ---------------------------------------------------------------------------------------------
// Grid

export interface PolarGridSignature {
  Args: PolarPartArgs & {
    /** `polygon` (default): rings through the angle axis's ticks. `circle`: round rings. */
    gridType?: 'polygon' | 'circle'
    /** Whether to draw the spokes, from the centre out at each angle. Default true. */
    radialLines?: boolean
    /** The rings' radii. Default the radius axis's ticks. */
    polarRadius?: readonly number[]
    /** The spokes' angles, in degrees. Default the angle axis's ticks. */
    polarAngles?: readonly number[]
    /** The lines' colour. Default `#ccc`, which the chart's CSS turns into `--border`. */
    stroke?: string
    strokeWidth?: number | string
    strokeDasharray?: string
    /** Fills the outermost ring (drawn behind the others). */
    fill?: string
    fillOpacity?: number | string
    /**
     * Classes for every ring and spoke, as recharts puts a grid's `className` on each:
     * `fill-(--color-desktop) opacity-20` fills each ring.
     */
    class?: string
  }
}

/** The grid behind a polar chart: recharts' `PolarGrid`. */
export class PolarGrid extends Part<PolarGridSignature> {
  readonly kind = 'polar-grid'

  <template></template>
}

// ---------------------------------------------------------------------------------------------
// Axes

/** The arguments both polar axes share with recharts'. */
export interface PolarAxisArgs extends PolarPartArgs {
  /** The key (or function) of each row's value on this axis. A category axis without one numbers the rows. */
  dataKey?: DataKey
  /** `category` or `number`. Default the chart's: categories around a radar, numbers out from its centre. */
  type?: 'category' | 'number'
  /** The value range, as `[min, max]`: numbers, `auto`, `dataMin`, `dataMax` or functions. */
  domain?: readonly [DomainBound, DomainBound]
  /** Whether nice ticks may be fractions. Default false. */
  allowDecimals?: boolean
  /** How many ticks a number axis aims for. */
  tickCount?: number
  /** The ticks to draw, instead of computed ones. */
  ticks?: readonly unknown[]
  /** Runs the axis the other way. */
  reversed?: boolean
  /** `auto` (by chart and type), or a scale: `linear`, `band` or `point`. */
  scale?: 'auto' | 'linear' | 'band' | 'point'
  /** Lays the axis out but doesn't draw it. */
  hide?: boolean
  /** Whether to draw the axis line. Default true. */
  axisLine?: boolean
  /** Formats each tick's label. */
  tickFormatter?: (value: never, index: number) => unknown
  /**
   * The axis line's colour, which the labels take as their fill. The angle axis has none by
   * default (its line isn't drawn, and its labels are grey); the radius axis's is `#ccc`.
   */
  stroke?: string
  /** Classes for the axis's group. */
  class?: string
}

/** What an angle axis's custom `@tick` component is handed: where the label goes, and its tick. */
export interface PolarAngleAxisTickArgs {
  /** Where the label goes: the end of the tick line. */
  x: number
  y: number
  /** `start`, `middle` or `end`: which way the label runs from the point. */
  textAnchor: 'start' | 'middle' | 'end'
  /** `start` (below), `middle` or `end` (above): where it sits against the point. */
  verticalAnchor: 'start' | 'middle' | 'end'
  /** The tick's index: its row, on a category axis. */
  index: number
  /** The tick: its `value`, its `coordinate` (an angle) and `index`. */
  payload: PolarTick
  /** The label's text, as `@tickFormatter` gives it (the raw value is `payload.value`). */
  value: string
  /** The label's fill: the axis's `@stroke`, if it has one. */
  fill?: string
  /** `none`, as recharts passes its tick text. */
  stroke: string
  /** The chart's centre, and the ring the axis is drawn on. */
  cx: number
  cy: number
  radius: number
}

export interface PolarAngleAxisSignature {
  Args: PolarAxisArgs & {
    /** The labels: true (default), false for none, or a component that draws each. */
    tick?: boolean | ComponentLike<{ Args: PolarAngleAxisTickArgs; Element: SVGElement }>
    /** Whether to draw the tick marks. Default true. */
    tickLine?: boolean
    /** The tick marks' length. Default 8. */
    tickSize?: number
    /** `outer` (default): marks and labels outside the ring. `inner`: inside it. */
    orientation?: 'outer' | 'inner'
    /** The axis line's shape: `polygon` (default) through the ticks, or a `circle`. */
    axisLineType?: 'polygon' | 'circle'
  }
}

/** The axis around a polar chart: recharts' `PolarAngleAxis`. */
export class PolarAngleAxis extends Part<PolarAngleAxisSignature> {
  readonly kind = 'angle-axis'

  <template></template>
}

/** What a `Label`'s `@content` is handed, as recharts hands its `content` function. */
export interface PolarLabelContentSignature {
  Args: {
    /** The ring the label sits in: the chart's centre (`cx`, `cy`), the axis's radii and angle. */
    viewBox: PolarViewBox
    /** The label's `@value`. */
    value?: unknown
    /** The label's `@offset`. */
    offset: number
    /** The label's `@position`. */
    position: PolarPosition
  }
  Element: Element
}

export interface RadiusAxisLabelSignature {
  Args: {
    /** The axis it belongs to; the axis's yield passes it. */
    axis: {
      registerLabel(label: RadiusAxisLabel): void
      unregisterLabel(label: RadiusAxisLabel): void
    }
    /** The text to show. */
    value?: string | number
    /**
     * Draws the label instead: a component handed `@viewBox` (its centre at `cx`, `cy`), as
     * recharts' `content` function is handed it, for a total in the middle of a radial chart.
     */
    content?: ComponentLike<PolarLabelContentSignature>
    /** Where `@value` sits against the axis's ring. Default `middle`, as recharts'. */
    position?: PolarPosition
    /** The space between the label and its anchor. Default 5. */
    offset?: number
    /** Classes for the text. */
    class?: string
    /** The text's fill. Default grey (`#808080`). */
    fill?: string
    fontSize?: number | string
  }
}

/** A label for the radius axis, such as a total in the middle of the chart: recharts' `Label`. */
export class RadiusAxisLabel extends Component<RadiusAxisLabelSignature> {
  constructor(owner: Owner, args: RadiusAxisLabelSignature['Args']) {
    super(owner, args)
    args.axis.registerLabel(this)
  }

  override willDestroy(): void {
    super.willDestroy()
    this.args.axis.unregisterLabel(this)
  }

  <template></template>
}

export interface PolarRadiusAxisParts {
  /** A label against the axis's ring, or one you draw (`@content`): recharts' `Label`. */
  Label: WithBoundArgs<typeof RadiusAxisLabel, 'axis'>
}

export interface PolarRadiusAxisSignature {
  Args: PolarAxisArgs & {
    /** The angle the axis runs out at, in degrees. Default 0 (3 o'clock). */
    angle?: number
    /** Which side of the axis its labels sit: `right` (default), `left` or `middle`. */
    orientation?: 'left' | 'right' | 'middle'
    /** Whether to draw the labels. Default true. */
    tick?: boolean
    /** Taken as upstream's examples pass it: recharts draws no tick marks on a radius axis. */
    tickLine?: boolean
  }
  Blocks: { default: [PolarRadiusAxisParts] }
}

/** The axis out from a polar chart's centre: recharts' `PolarRadiusAxis`. */
export class PolarRadiusAxis extends Part<PolarRadiusAxisSignature> {
  readonly kind = 'radius-axis'
  readonly labels = new Registry<RadiusAxisLabel>()

  registerLabel = (label: RadiusAxisLabel): void => this.labels.add(label)
  unregisterLabel = (label: RadiusAxisLabel): void => this.labels.remove(label)

  <template>{{yield (hash Label=(component RadiusAxisLabel axis=this))}}</template>
}

// ---------------------------------------------------------------------------------------------
// Series

/** A radar's dots: false (default) for none, true, their attributes, or a component. */
export type RadarDotOption =
  | boolean
  | {
      r?: number
      fill?: string
      fillOpacity?: number | string
      stroke?: string
      strokeWidth?: number | string
      class?: string
    }
  | ComponentLike<{ Args: DotArgs; Element: Element }>

/** The arguments both polar series share. */
export interface PolarSeriesArgs extends PolarPartArgs {
  /** The key (or function) of each row's value. */
  dataKey: DataKey
  /** The series' name in the tooltip and legend. Default: its data key. */
  name?: string
  /** Lays the series out but doesn't draw it. */
  hide?: boolean
  /** The legend's icon type; `none` leaves the series out of the legend. */
  legendType?: string
  /** `none` leaves the series out of the tooltip. */
  tooltipType?: string
  fill?: string
  fillOpacity?: number | string
  stroke?: string
  strokeWidth?: number | string
  /** Classes for the series' group. */
  class?: string
}

export interface RadarSignature {
  Args: PolarSeriesArgs & {
    /** A dot at each point. Default none. */
    dot?: RadarDotOption
    /** The dot at the active row, while the tooltip shows. Default true. */
    activeDot?: RadarDotOption
    /** Joins the outline over missing values. */
    connectNulls?: boolean
  }
}

/** A polygon through each row's value: recharts' `Radar`. */
export class Radar extends Part<RadarSignature> {
  readonly kind = 'radar'

  <template></template>
}

/** What a radial bar's `@background` takes: true for recharts' track, or its attributes. */
export type RadialBarBackground = boolean | { fill?: string; class?: string }

export interface PolarLabelListSignature {
  Args: {
    /** The bar it labels; the bar's yield passes it. */
    series: {
      registerLabel(label: PolarLabelList): void
      unregisterLabel(label: PolarLabelList): void
    }
    /** The key of each label's value in the row. Default: the bar's own value. */
    dataKey?: DataKey
    /**
     * Where each label sits against its bar: along it (`insideStart`, `insideEnd`, `end`), or
     * at a point (`outside`, `middle`, `center`…). Default `middle`, the middle of the bar.
     */
    position?: PolarPosition
    /** The space between a label and its anchor: degrees along a bar. Default 5. */
    offset?: number
    /** Formats each label's value. */
    formatter?: (value: never) => unknown
    fill?: string
    fontSize?: number | string
    /** Classes for each label's `<text>`, such as `fill-white capitalize`. */
    class?: string
  }
}

/** A label on each bar of a radial bar series: recharts' `LabelList` in a polar chart. */
export class PolarLabelList extends Component<PolarLabelListSignature> {
  constructor(owner: Owner, args: PolarLabelListSignature['Args']) {
    super(owner, args)
    args.series.registerLabel(this)
  }

  override willDestroy(): void {
    super.willDestroy()
    this.args.series.unregisterLabel(this)
  }

  <template></template>
}

export interface RadialBarParts {
  /** A label on each bar: recharts' `LabelList`. */
  LabelList: WithBoundArgs<typeof PolarLabelList, 'series'>
}

export interface RadialBarSignature {
  Args: PolarSeriesArgs & {
    /** Bars with the same stack id stack on each other. */
    stackId?: string | number
    /** The corners' radius: a number, or a percentage of the bar's width. Default 0. */
    cornerRadius?: number | string
    /** Rounds the corners even where the bar is too short for them. */
    forceCornerRadius?: boolean
    /** Puts the rounded corners outside the bar's ends. */
    cornerIsExternal?: boolean
    /** A track behind each bar, round the whole chart: true, or its attributes. Default none. */
    background?: RadialBarBackground
    /** The least angle a bar is drawn with, so a small value still shows. */
    minPointSize?: number
    /** The bar's width, instead of an equal share of the band. */
    barSize?: number
    maxBarSize?: number
  }
  Blocks: { default: [RadialBarParts] }
}

/** A bar round the chart for each row: recharts' `RadialBar`. */
export class RadialBar extends Part<RadialBarSignature> {
  readonly kind = 'radial-bar'
  readonly labels = new Registry<PolarLabelList>()

  registerLabel = (label: PolarLabelList): void => this.labels.add(label)
  unregisterLabel = (label: PolarLabelList): void => this.labels.remove(label)

  <template>{{yield (hash LabelList=(component PolarLabelList series=this))}}</template>
}
