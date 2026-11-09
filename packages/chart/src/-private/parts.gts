/*
 * The parts a cartesian chart yields: its axes, grid, series, tooltip and legend. Each renders
 * nothing where it is written; it registers with the chart, which reads its arguments and draws
 * it in recharts' layer order (grid, areas, bars, lines, axes, dots, labels).
 */
import Component from '@glimmer/component'
import { hash } from '@ember/helper'
import type Owner from '@ember/owner'
import type { ComponentLike } from '@glint/template'
import { Registry } from './registry.ts'
import type { CurveType } from './paths.ts'
import type { DataKey, DomainBound } from './cartesian.ts'
import type { TickInterval } from './tick-interval.ts'
import type {
  ChartLegendContentArgs,
  ChartTooltipContentArgs,
  LabelFormatter,
  ValueFormatter,
} from '../types.ts'

/** What a part needs of its chart: somewhere to register. */
export interface ChartRegistrar {
  register(part: ChartPart): void
  unregister(part: ChartPart): void
}

/** Every part a chart reads. */
export type ChartPart = XAxis | YAxis | CartesianGrid | Area | Line | Bar | ChartTooltip | ChartLegend

interface PartArgs {
  /** The chart it belongs to; the chart's yield passes it. */
  chart: ChartRegistrar
}

/** A part that registers with its chart while it is rendered. */
abstract class Part<S extends { Args: PartArgs }> extends Component<S> {
  abstract readonly kind: string

  constructor(owner: Owner, args: S['Args']) {
    super(owner, args)
    args.chart.register(this as unknown as ChartPart)
  }

  override willDestroy(): void {
    super.willDestroy()
    this.args.chart.unregister(this as unknown as ChartPart)
  }
}

// ---------------------------------------------------------------------------------------------
// Axes

/** The arguments an axis shares with recharts' `XAxis` and `YAxis`. */
export interface AxisArgs extends PartArgs {
  /** The key (or function) of each row's value on this axis. A category axis without one numbers the rows. */
  dataKey?: DataKey
  /** `category` (the x-axis's default) or `number` (the y-axis's). */
  type?: 'category' | 'number'
  /** Lays the axis out but doesn't draw it. */
  hide?: boolean
  /** Draws the axis inside the plot area instead of beside it. */
  mirror?: boolean
  /** Runs the axis the other way: right to left, or top to bottom. */
  reversed?: boolean
  /** The value range, as `[min, max]`: numbers, `auto`, `dataMin`, `dataMax` or functions. */
  domain?: readonly [DomainBound, DomainBound]
  /** Lets the domain cut the data off instead of growing to fit it. */
  allowDataOverflow?: boolean
  /** Whether nice ticks may be fractions. Default true. */
  allowDecimals?: boolean
  /** How many ticks a number axis aims for. Default 5. */
  tickCount?: number
  /** The ticks to draw, instead of computed ones. */
  ticks?: readonly unknown[]
  /** Whether to draw tick labels. Default true. */
  tick?: boolean
  /** Whether to draw the tick marks. Default true. */
  tickLine?: boolean
  /** Whether to draw the axis line. Default true. */
  axisLine?: boolean
  /** The tick marks' length. Default 6. */
  tickSize?: number
  /** The space between a tick mark and its label. Default 2. */
  tickMargin?: number
  /** The least space between two labels before one is dropped. Default 5. */
  minTickGap?: number
  /** Which ticks to keep when labels would overlap: recharts' `interval`. Default `preserveEnd`. */
  interval?: TickInterval
  /** Formats each tick's label. */
  tickFormatter?: (value: never, index: number) => unknown
  /** A unit appended to each label. */
  unit?: string
  /** The labels' rotation, in degrees. */
  angle?: number
  /** The axis line's and labels' colour. Default `#666` (the chart's CSS greys the labels). */
  stroke?: string
  /** `auto` (by chart and type), or a scale: `linear`, `band` or `point`. */
  scale?: 'auto' | 'linear' | 'band' | 'point'
}

export interface XAxisSignature {
  Args: AxisArgs & {
    /** The axis's height. Default 30. */
    height?: number
    /** `bottom` (default) or `top`. */
    orientation?: 'bottom' | 'top'
    /** Space before the first and after the last category, in pixels. */
    padding?: { left?: number; right?: number }
  }
}

/** The chart's x-axis: recharts' `XAxis`. */
export class XAxis extends Part<XAxisSignature> {
  readonly kind = 'xAxis'

  <template></template>
}

export interface YAxisSignature {
  Args: AxisArgs & {
    /** The axis's width. Default 60. */
    width?: number
    /** `left` (default) or `right`. */
    orientation?: 'left' | 'right'
    /** Space above the top and below the bottom value, in pixels. */
    padding?: { top?: number; bottom?: number }
  }
}

/** The chart's y-axis: recharts' `YAxis`. */
export class YAxis extends Part<YAxisSignature> {
  readonly kind = 'yAxis'

  <template></template>
}

// ---------------------------------------------------------------------------------------------
// Grid

export interface CartesianGridSignature {
  Args: PartArgs & {
    /** Whether to draw lines across, at the y-axis's ticks. Default true. */
    horizontal?: boolean
    /** Whether to draw lines down, at the x-axis's ticks. Default true. */
    vertical?: boolean
    /** The lines' colour. Default `#ccc`, which the chart's CSS turns into `--border`. */
    stroke?: string
    strokeDasharray?: string
    /** Recharts' `orientation`, passed through to the lines as an attribute. */
    orientation?: string
  }
}

/** Grid lines behind the chart: recharts' `CartesianGrid`. */
export class CartesianGrid extends Part<CartesianGridSignature> {
  readonly kind = 'grid'

  <template></template>
}

// ---------------------------------------------------------------------------------------------
// Series

/** What a series' dot (or active dot) component is handed. */
export interface DotArgs {
  cx: number
  cy: number
  r: number
  index: number
  value: unknown
  payload: Record<string, unknown>
  dataKey: DataKey
  stroke?: string
  strokeWidth?: number | string
  fill?: string
}

/** A dot's look: false for none, true for the default, its attributes, or a component. */
export type DotOption =
  | boolean
  | { r?: number; fill?: string; stroke?: string; strokeWidth?: number | string; class?: string }
  | ComponentLike<{ Args: DotArgs; Element: SVGElement }>

/** The arguments every series shares. */
export interface SeriesArgs extends PartArgs {
  /** The key (or function) of each row's value. */
  dataKey: DataKey
  /** The series' name in the tooltip and legend. Default: its data key. */
  name?: string
  /** Series with the same stack id stack on each other. */
  stackId?: string | number
  /** Lays the series out but doesn't draw it. */
  hide?: boolean
  /** The legend's icon type; `none` leaves the series out of the legend. */
  legendType?: string
  /** `none` leaves the series out of the tooltip. */
  tooltipType?: string
  /** A unit for its tooltip values. */
  unit?: string
}

/** What a series yields: its label list. */
export interface SeriesParts {
  /** Labels at each point (or bar): recharts' `LabelList`. */
  LabelList: ComponentLike<LabelListSignature>
}

abstract class Series<S extends { Args: SeriesArgs }> extends Part<S> {
  readonly labels = new Registry<LabelList>()

  registerLabel = (label: LabelList): void => this.labels.add(label)
  unregisterLabel = (label: LabelList): void => this.labels.remove(label)
}

export interface AreaSignature {
  Args: SeriesArgs & {
    /** How the line joins the points: `linear` (default), `natural`, `monotone`, `step`… */
    type?: CurveType
    fill?: string
    fillOpacity?: number | string
    stroke?: string
    strokeWidth?: number | string
    strokeDasharray?: string
    /** The dot at each point. Default none. */
    dot?: DotOption
    /** The dot at the active row, while the tooltip shows. Default true. */
    activeDot?: DotOption
    /** Joins the line over missing values. */
    connectNulls?: boolean
    /** Where the area starts: a number, `dataMin` or `dataMax`. Default the axis's 0. */
    baseValue?: number | 'dataMin' | 'dataMax'
  }
  Blocks: { default: [SeriesParts] }
}

/** A filled area under a line: recharts' `Area`. */
export class Area extends Series<AreaSignature> {
  readonly kind = 'area'

  <template>{{yield (hash LabelList=(component LabelList series=this))}}</template>
}

export interface LineSignature {
  Args: SeriesArgs & {
    /** How the line joins the points: `linear` (default), `natural`, `monotone`, `step`… */
    type?: CurveType
    stroke?: string
    strokeWidth?: number | string
    strokeDasharray?: string
    /** The default dot's fill. Default `#fff`. */
    fill?: string
    /** The dot at each point. Default true. */
    dot?: DotOption
    /** The dot at the active row, while the tooltip shows. Default true. */
    activeDot?: DotOption
    /** Joins the line over missing values. */
    connectNulls?: boolean
  }
  Blocks: { default: [SeriesParts] }
}

/** A line through the points: recharts' `Line`. */
export class Line extends Series<LineSignature> {
  readonly kind = 'line'

  <template>{{yield (hash LabelList=(component LabelList series=this))}}</template>
}

export interface BarSignature {
  Args: SeriesArgs & {
    fill?: string
    fillOpacity?: number | string
    stroke?: string
    strokeWidth?: number | string
    /** The corners' radius: one for all four, or `[topLeft, topRight, bottomRight, bottomLeft]`. */
    radius?: number | readonly number[]
    /** The bar's width, instead of an equal share of the band. */
    barSize?: number
    maxBarSize?: number
  }
  Blocks: { default: [SeriesParts] }
}

/** A bar for each row: recharts' `Bar`. */
export class Bar extends Series<BarSignature> {
  readonly kind = 'bar'

  <template>{{yield (hash LabelList=(component LabelList series=this))}}</template>
}

// ---------------------------------------------------------------------------------------------
// Labels

/** Where a label sits against its point or bar. */
export type LabelPosition =
  | 'top'
  | 'bottom'
  | 'left'
  | 'right'
  | 'center'
  | 'inside'
  | 'insideLeft'
  | 'insideRight'
  | 'insideTop'
  | 'insideBottom'

export interface LabelListSignature {
  Args: {
    /** The series it labels; the series' yield passes it. */
    series: { registerLabel(label: LabelList): void; unregisterLabel(label: LabelList): void }
    /** The key of each label's value in the row. Default: the series' own value. */
    dataKey?: DataKey
    /** Where each label sits. Default `top` for a line or area, `center` for a bar. */
    position?: LabelPosition
    /** The space between a label and its point. Default 5. */
    offset?: number
    /** Formats each label's value. */
    formatter?: (value: never) => unknown
    fill?: string
    fontSize?: number | string
    /** Classes for each label's `<text>`, such as `fill-foreground`. */
    class?: string
  }
}

/** A label at each point of a series: recharts' `LabelList`. */
export class LabelList extends Component<LabelListSignature> {
  constructor(owner: Owner, args: LabelListSignature['Args']) {
    super(owner, args)
    args.series.registerLabel(this)
  }

  override willDestroy(): void {
    super.willDestroy()
    this.args.series.unregisterLabel(this)
  }

  <template></template>
}

// ---------------------------------------------------------------------------------------------
// Tooltip and legend

export interface ChartTooltipSignature {
  Args: PartArgs & {
    /**
     * What the tooltip shows: a component, handed `@active`, `@payload`, `@label` and the
     * chart's `@config`. Default `ChartTooltipContent`. Curry its own arguments:
     * `@content={{component ChartTooltipContent indicator="line"}}`.
     */
    content?: ComponentLike<{ Args: ChartTooltipContentArgs }>
    /** The line (or band) under the pointer. Default true; false draws none. */
    cursor?: boolean | { stroke?: string; strokeWidth?: number | string; fill?: string }
    /** Shows the tooltip whatever the pointer does (true), or never (false). */
    active?: boolean
    /** The row the tooltip shows before the pointer moves. */
    defaultIndex?: number
    /** The space between the pointer and the tooltip. Default 10. */
    offset?: number
    /** Passed to the content, for its label. */
    labelClassName?: string
    labelFormatter?: LabelFormatter
    formatter?: ValueFormatter
    /** Leaves out entries whose value is null. Default true. */
    filterNull?: boolean
    /** Moves the tooltip box smoothly. Default true. */
    isAnimationActive?: boolean
  }
}

/** The chart's tooltip: shadcn's `ChartTooltip` (recharts' `Tooltip`). */
export class ChartTooltip extends Part<ChartTooltipSignature> {
  readonly kind = 'tooltip'

  <template></template>
}

export interface ChartLegendSignature {
  Args: PartArgs & {
    /** What the legend shows: a component, handed `@payload` and the chart's `@config`. Default `ChartLegendContent`. */
    content?: ComponentLike<{ Args: ChartLegendContentArgs }>
    /** `bottom` (default), `top` or `middle`. */
    verticalAlign?: 'top' | 'middle' | 'bottom'
    /** `center` (default), `left` or `right`. */
    align?: 'left' | 'center' | 'right'
    /** `horizontal` (default) or `vertical`. */
    layout?: 'horizontal' | 'vertical'
  }
}

/** The chart's legend: shadcn's `ChartLegend` (recharts' `Legend`). */
export class ChartLegend extends Part<ChartLegendSignature> {
  readonly kind = 'legend'

  <template></template>
}
