/*
 * The parts a chart yields: a cartesian chart's axes, grid and series, a pie chart's pies, and
 * every chart's tooltip and legend. Each renders nothing where it is written; it registers with
 * the chart, which reads its arguments and draws it in recharts' layer order (grid, areas, bars,
 * lines, axes, dots, labels; pies, then their labels).
 */
import Component from '@glimmer/component'
import { hash } from '@ember/helper'
import type Owner from '@ember/owner'
import type { ComponentLike, WithBoundArgs } from '@glint/template'
import { Registry } from './registry.ts'
import type { CurveType } from './paths.ts'
import type { DataKey, DomainBound } from './cartesian.ts'
import type { PolarLabelPosition, PolarViewBox } from './polar.ts'
import type { TickInterval } from './tick-interval.ts'
import type {
  ChartLegendContentArgs,
  ChartTooltipContentArgs,
  LabelFormatter,
  TooltipFormatter,
} from '../types.ts'

/** What a part needs of its chart: somewhere to register. */
export interface ChartRegistrar {
  register(part: ChartPart): void
  unregister(part: ChartPart): void
}

/** Every part a chart reads. */
export type ChartPart =
  XAxis | YAxis | CartesianGrid | Area | Line | Bar | Pie | ChartTooltip | ChartLegend

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
    /** Recharts' `orientation`, taken as upstream's examples pass it; it doesn't change the grid. */
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
  /** The row the point came from. */
  payload: Record<string, string | number | null | undefined>
  dataKey: DataKey
  stroke?: string
  strokeWidth?: number | string
  fill?: string
}

/** A dot's look: false for none, true for the default, its attributes, or a component. */
export type DotOption =
  | boolean
  | { r?: number; fill?: string; stroke?: string; strokeWidth?: number | string; class?: string }
  | ComponentLike<{ Args: DotArgs; Element: Element }>

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
  LabelList: WithBoundArgs<typeof LabelList, 'series'>
}

/** What a bar series yields: its label list, and a `Cell` per bar. */
export interface BarParts extends SeriesParts {
  /** One bar's attributes (its `@fill`), in the order of the rows: recharts' `Cell`. */
  Cell: WithBoundArgs<typeof Cell, 'series'>
}

abstract class Series<S extends { Args: SeriesArgs }> extends Part<S> {
  readonly labels = new Registry<LabelList>()
  readonly cells = new Registry<Cell>()

  registerLabel = (label: LabelList): void => this.labels.add(label)
  unregisterLabel = (label: LabelList): void => this.labels.remove(label)
  registerCell = (cell: Cell): void => this.cells.add(cell)
  unregisterCell = (cell: Cell): void => this.cells.remove(cell)
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

/**
 * What a bar's `@shape` is handed as `@props`, as recharts hands its `shape` function: the
 * bar's rectangle, its attributes, and the row it came from. Pass it on to `Rectangle`.
 */
export interface RectangleProps {
  x: number
  y: number
  width: number
  height: number
  /** The corners' radius: one for all four, or `[topLeft, topRight, bottomRight, bottomLeft]`. */
  radius?: number | readonly number[]
  fill?: string
  fillOpacity?: number | string
  stroke?: string
  strokeWidth?: number | string
  /** The bar's row. */
  index: number
  /** Its value. */
  value: unknown
  /** The row it came from (with its `Cell`'s attributes over it). */
  payload: Record<string, string | number | null | undefined>
  dataKey: DataKey
  /** Whether the tooltip shows its row. */
  isActive: boolean
}

/** A bar's `@shape`: a component that draws each bar, handed its `@props` and `@index`. */
export interface BarShapeSignature {
  Args: { props: RectangleProps; index: number }
  Element: Element
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
    /**
     * Draws each bar: a component handed `@props` (its rectangle, attributes and row) and
     * `@index`, as recharts' `shape` function is. `Rectangle` draws one. Default a `Rectangle`.
     */
    shape?: ComponentLike<BarShapeSignature>
  }
  Blocks: { default: [BarParts] }
}

/** A bar for each row: recharts' `Bar`. */
export class Bar extends Series<BarSignature> {
  readonly kind = 'bar'

  <template>
    {{yield (hash LabelList=(component LabelList series=this) Cell=(component Cell series=this))}}
  </template>
}

// ---------------------------------------------------------------------------------------------
// Labels

/**
 * Where a label sits against its point or bar, or (in a pie) its sector: `outside`, `center`,
 * `centerTop`, `centerBottom`, or `middle` (the default), in the middle of the sector's ring.
 */
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
  | PolarLabelPosition

export interface LabelListSignature {
  Args: {
    /** The series it labels; the series' yield passes it. */
    series: { registerLabel(label: LabelList): void; unregisterLabel(label: LabelList): void }
    /** The key of each label's value in the row. Default: the series' own value. */
    dataKey?: DataKey
    /**
     * Where each label sits. Default `top` for a line or area, `center` for a bar, `middle`
     * for a pie's sector.
     */
    position?: LabelPosition
    /** The space between a label and its point. Default 5. */
    offset?: number
    /** Formats each label's value. */
    formatter?: (value: never) => unknown
    /** The labels' fill. Default the bar's or sector's own fill (its row's or `Cell`'s), else grey. */
    fill?: string
    fillOpacity?: number | string
    stroke?: string
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
// Cells

export interface CellSignature {
  Args: {
    /** The bar or pie it belongs to; the series' yield passes it. */
    series: { registerCell(cell: Cell): void; unregisterCell(cell: Cell): void }
    fill?: string
    fillOpacity?: number | string
    stroke?: string
    strokeWidth?: number | string
  }
}

/**
 * One bar's or sector's attributes, over its series': recharts' `Cell`. Write one per row, in
 * the rows' order:
 *
 *   {{#each chartData as |row|}}
 *     <bar.Cell @fill={{if (isPositive row.visitors) "var(--chart-1)" "var(--chart-2)"}} />
 *   {{/each}}
 */
export class Cell extends Component<CellSignature> {
  constructor(owner: Owner, args: CellSignature['Args']) {
    super(owner, args)
    args.series.registerCell(this)
  }

  override willDestroy(): void {
    super.willDestroy()
    this.args.series.unregisterCell(this)
  }

  /** The attributes it lays over its bar or sector's row. */
  get attributes(): Record<string, unknown> {
    const { fill, fillOpacity, stroke, strokeWidth } = this.args
    const attributes: Record<string, unknown> = {}
    if (fill !== undefined) attributes['fill'] = fill
    if (fillOpacity !== undefined) attributes['fillOpacity'] = fillOpacity
    if (stroke !== undefined) attributes['stroke'] = stroke
    if (strokeWidth !== undefined) attributes['strokeWidth'] = strokeWidth
    return attributes
  }

  <template></template>
}

// ---------------------------------------------------------------------------------------------
// Pies

/**
 * What a pie's `@shape` is handed as `@props`, as recharts hands its `shape` function: the
 * sector's geometry, its attributes and its row. Pass it on to `Sector`.
 */
export interface SectorProps {
  cx: number
  cy: number
  innerRadius: number
  outerRadius: number
  startAngle: number
  endAngle: number
  midAngle: number
  cornerRadius?: number | string
  fill?: string
  fillOpacity?: number | string
  stroke?: string
  strokeWidth?: number | string
  /** The sector's row. */
  index: number
  value: number
  /** The row's name (the pie's `@nameKey`), or its index. */
  name: unknown
  /** Its share of the pie, from 0 to 1. */
  percent: number
  /** The row it came from (with its `Cell`'s attributes over it). */
  payload: Record<string, string | number | null | undefined>
  dataKey: DataKey
  /** Whether the tooltip shows it. */
  isActive: boolean
}

/** A pie's `@shape`: a component that draws each sector, handed its `@props` and `@index`. */
export interface PieShapeSignature {
  Args: { props: SectorProps; index: number }
  Element: Element
}

/** What a pie's `@label` component is handed as `@props`: where the label goes, and its sector. */
export interface PieLabelProps extends Omit<SectorProps, 'isActive'> {
  /** Where the text goes, past the sector's edge. */
  x: number
  y: number
  /** `start` on the right of the pie, `end` on its left. */
  textAnchor: 'start' | 'middle' | 'end'
  /** recharts' label props have none; here for upstream's examples, which pass it on. */
  dominantBaseline?: string
}

/** A pie's `@label` component: draws a sector's label, handed its `@props` and `@index`. */
export interface PieLabelSignature {
  Args: { props: PieLabelProps; index: number }
  Element: Element
}

/** What a pie yields: labels for its sectors, a label for the pie, and a `Cell` per sector. */
export interface PieParts {
  /** Labels on each sector: recharts' `LabelList`. */
  LabelList: WithBoundArgs<typeof LabelList, 'series'>
  /** A label for the pie, such as the total in a donut's hole: recharts' `Label`. */
  Label: WithBoundArgs<typeof Label, 'pie'>
  /** One sector's attributes (its `@fill`), in the order of the rows: recharts' `Cell`. */
  Cell: WithBoundArgs<typeof Cell, 'series'>
}

export interface PieSignature {
  Args: PartArgs & {
    /** The rows, one sector each. Default the chart's `@data`. */
    data?: readonly unknown[]
    /** The key (or function) of each row's value. Default `value`. */
    dataKey?: DataKey
    /** The key (or function) of each row's name, for the tooltip and legend. Default `name`. */
    nameKey?: DataKey
    /** The pie's name, where a row has none. */
    name?: string
    /** The centre, in pixels or a percentage of the plot area. Default `50%`. */
    cx?: number | string
    cy?: number | string
    /** The hole's radius (a donut), in pixels or a percentage of the largest. Default 0. */
    innerRadius?: number | string
    /** The pie's radius, in pixels or a percentage of the largest. Default `80%`. */
    outerRadius?: number | string
    /** The angles it starts and ends at, in degrees counter-clockwise from 3 o'clock. Default 0 and 360. */
    startAngle?: number
    endAngle?: number
    /** The gap between sectors, in degrees. Default 0. */
    paddingAngle?: number
    /** The smallest angle a sector with a value gets. Default 0. */
    minAngle?: number
    /** Rounds the sectors' corners. */
    cornerRadius?: number | string
    /** The sectors' fill where the row and its `Cell` give none. Default `#808080`. */
    fill?: string
    fillOpacity?: number | string
    /** The line between sectors. Default `#fff` (the chart's CSS makes it transparent). */
    stroke?: string
    strokeWidth?: number | string
    /**
     * A label past each sector's edge, with a line to it: true for its value, or a component
     * handed `@props` (where the label goes, and the sector) and `@index`. Default none.
     */
    label?: boolean | ComponentLike<PieLabelSignature>
    /** Whether each label has a line to its sector. Default true. */
    labelLine?: boolean
    /** Draws each sector: a component handed `@props` and `@index`. `Sector` draws one. */
    shape?: ComponentLike<PieShapeSignature>
    /** The legend's icon type; `none` leaves the pie out of the legend. Default `rect`. */
    legendType?: string
    /** `none` leaves the pie out of the tooltip. */
    tooltipType?: string
    /** Lays the pie out but doesn't draw it. */
    hide?: boolean
  }
  Blocks: { default: [PieParts] }
}

/** A pie, a sector for each row: recharts' `Pie`. */
export class Pie extends Part<PieSignature> {
  readonly kind = 'pie'
  readonly labels = new Registry<LabelList>()
  readonly cells = new Registry<Cell>()
  readonly textLabels = new Registry<Label>()

  registerLabel = (label: LabelList): void => this.labels.add(label)
  unregisterLabel = (label: LabelList): void => this.labels.remove(label)
  registerCell = (cell: Cell): void => this.cells.add(cell)
  unregisterCell = (cell: Cell): void => this.cells.remove(cell)
  registerTextLabel = (label: Label): void => this.textLabels.add(label)
  unregisterTextLabel = (label: Label): void => this.textLabels.remove(label)

  <template>
    {{yield
      (hash
        LabelList=(component LabelList series=this)
        Label=(component Label pie=this)
        Cell=(component Cell series=this)
      )
    }}
  </template>
}

/** What a `Label`'s `@content` is handed. */
export interface LabelContentSignature {
  Args: {
    /** The chart's ring: its centre (`cx`, `cy`), radii and angles. */
    viewBox: PolarViewBox
    /** The label's `@value`. */
    value?: unknown
    /** The label's `@offset`. */
    offset: number
    /** The label's `@position`. */
    position: PolarLabelPosition
  }
  Element: Element
}

export interface LabelSignature {
  Args: {
    /** The pie it belongs to; the pie's yield passes it. */
    pie: { registerTextLabel(label: Label): void; unregisterTextLabel(label: Label): void }
    /** The text to show. */
    value?: string | number
    /**
     * Draws the label instead: a component handed `@viewBox` (the chart's ring, its centre at
     * `cx`, `cy`), as recharts' `content` function is handed it. It draws inside the pie.
     */
    content?: ComponentLike<LabelContentSignature>
    /** Where `@value` sits against the chart's ring. Default `middle`, as recharts'. */
    position?: PolarLabelPosition
    /** The space between the label and the ring's edge, for `outside`. Default 5. */
    offset?: number
    /** Classes for the text. */
    class?: string
    /** The text's fill. Default grey (`#808080`). */
    fill?: string
    fontSize?: number | string
  }
}

/** A label for a pie, such as the total in a donut's hole: recharts' `Label`. */
export class Label extends Component<LabelSignature> {
  constructor(owner: Owner, args: LabelSignature['Args']) {
    super(owner, args)
    args.pie.registerTextLabel(this)
  }

  override willDestroy(): void {
    super.willDestroy()
    this.args.pie.unregisterTextLabel(this)
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
    /** Formats each entry: a function returning its text, or a component that draws it. */
    formatter?: TooltipFormatter
    /** Leaves out entries whose value is null. Default true. */
    filterNull?: boolean
    /**
     * Moves the tooltip box smoothly: `'auto'` (the default) unless the user prefers reduced
     * motion, `true` always, `false` never.
     */
    isAnimationActive?: boolean | 'auto'
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
    /** Classes for the legend, handed to its content as `@class`, as recharts' `className`. */
    class?: string
  }
}

/** The chart's legend: shadcn's `ChartLegend` (recharts' `Legend`). */
export class ChartLegend extends Part<ChartLegendSignature> {
  readonly kind = 'legend'

  <template></template>
}
