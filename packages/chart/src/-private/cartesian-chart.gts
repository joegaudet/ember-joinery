/*
 * The chart behind AreaChart, BarChart and LineChart: recharts' CartesianChart, as declarative
 * Glimmer SVG. It measures its box (as recharts' ResponsiveContainer does), collects the parts
 * its block registers, lays them out with ./cartesian.ts, and draws them in recharts' layers and
 * with recharts' class names, so shadcn's chart CSS styles them as it styles recharts.
 *
 * recharts is MIT licensed; its notice is in NOTICE, and the build keeps it in the module that
 * ships this (see rollup.config.mjs).
 */
import Component from '@glimmer/component'
import type { TOC } from '@ember/component/template-only'
import { cached, tracked } from '@glimmer/tracking'
import { hash } from '@ember/helper'
import { registerDestructor } from '@ember/destroyable'
import type Owner from '@ember/owner'
import { on } from '@ember/modifier'
import { htmlSafe, type SafeString } from '@ember/template'
import { modifier } from 'ember-modifier'
import type { ComponentLike, WithBoundArgs } from '@glint/template'
import { idFor } from '@ember-joinery/primitives/id'
import { resizeObserver } from '@ember-joinery/primitives/resize-observer'
import { Registry } from './registry.ts'
import {
  cartesianGeometry,
  defaultAxis,
  tooltipTranslate,
  valueOf,
  activeIndexAt,
  type AxisGeometry,
  type AxisSettings,
  type CartesianGeometry,
  type ChartName,
  type Layout,
  type Margin,
  type SeriesGeometry,
  type SeriesSettings,
  type StackOffset,
} from './cartesian.ts'
import { areaPath, linePath, rectanglePath } from './paths.ts'
import { dotFor, type DotRender } from './dots.ts'
import {
  Area,
  Bar,
  CartesianGrid,
  ChartLegend,
  ChartTooltip,
  Line,
  XAxis,
  YAxis,
  type ChartPart,
  type ChartRegistrar,
  type DotArgs,
  type LabelList,
  type LabelPosition,
} from './parts.gts'
import ChartTooltipContent from '../components/chart-tooltip-content.gts'
import ChartLegendContent from '../components/chart-legend-content.gts'
import type {
  ChartConfig,
  ChartLegendContentArgs,
  ChartTooltipContentArgs,
  LegendPayloadItem,
  TooltipPayloadItem,
} from '../types.ts'
import { clearStringSizeCache, type TextStyle } from './text-size.ts'

/** What every cartesian chart yields: its parts, each a component bound to the chart. */
export interface CartesianChartParts {
  /** The x-axis: recharts' `XAxis`. */
  XAxis: WithBoundArgs<typeof XAxis, 'chart'>
  /** The y-axis: recharts' `YAxis`. */
  YAxis: WithBoundArgs<typeof YAxis, 'chart'>
  /** Grid lines behind the marks: recharts' `CartesianGrid`. */
  CartesianGrid: WithBoundArgs<typeof CartesianGrid, 'chart'>
  /** An area series: recharts' `Area`. */
  Area: WithBoundArgs<typeof Area, 'chart'>
  /** A bar series: recharts' `Bar`. */
  Bar: WithBoundArgs<typeof Bar, 'chart'>
  /** A line series: recharts' `Line`. */
  Line: WithBoundArgs<typeof Line, 'chart'>
  /** The tooltip: shadcn's `ChartTooltip`. */
  ChartTooltip: WithBoundArgs<typeof ChartTooltip, 'chart'>
  /** The legend: shadcn's `ChartLegend`. */
  ChartLegend: WithBoundArgs<typeof ChartLegend, 'chart'>
}

export interface CartesianChartSignature {
  Args: {
    /** The rows to draw. */
    data: readonly unknown[]
    /** `horizontal` (default): categories along x. `vertical`: categories down y. */
    layout?: Layout
    /** The space around the plot area. Default 5 on every side; given, a side left out is 0. */
    margin?: Margin
    /** How stacked series stack: `none` (default), `expand` (to 100%), `sign`, `positive`… */
    stackOffset?: StackOffset
    /** The space between bar bands' bars and the band's edge. Default `10%`. */
    barCategoryGap?: number | string
    /** The space between bars in a band. Default 4. */
    barGap?: number | string
    /** Every bar's width, instead of an equal share of the band. */
    barSize?: number
    maxBarSize?: number
    /**
     * Keyboard access and a screen reader role: the chart takes focus, and the arrow keys move
     * the tooltip between rows. Default true, as recharts 3's.
     */
    accessibilityLayer?: boolean
    /** A fixed size, in pixels. Without both, the chart fills its container and follows it. */
    width?: number
    height?: number
    /** The size to draw before the container has been measured. */
    initialDimension?: { width: number; height: number }
    /** The svg's `<title>` and `<desc>`, for a screen reader. */
    title?: string
    desc?: string
    /** The config, from `ChartContainer` (or your own, for a chart outside one). */
    config?: ChartConfig
    /** Set by `ChartContainer`: the chart is inside one, which is what its harness finds. */
    inContainer?: boolean
    /** The chart's name, for its harness, outside a `ChartContainer`. */
    name?: string
    /** Set by `AreaChart`, `BarChart` and `LineChart`. */
    chartName?: ChartName
  }
  Blocks: {
    /**
     * The chart's parts. The block renders inside the chart's `<svg>`, so it can also hold
     * `<defs>` (gradients the series fill with).
     */
    default: [CartesianChartParts]
  }
  Element: HTMLDivElement
}

interface DrawnSeries {
  id: string
  type: 'area' | 'bar' | 'line'
  key: string
  name: string
  /** The points, as `x,y` pairs, for its harness. */
  points: string
  areaPath?: string | null
  curvePath?: string | null
  fill?: string
  fillOpacity?: string | number
  stroke?: string
  strokeWidth?: string | number
  strokeDasharray?: string
  bars: {
    d: string
    fill?: string
    fillOpacity?: string | number
    stroke?: string
    strokeWidth?: string | number
    x: number
    y: number
    width: number
    height: number
    radius: string
    index: number
    value: string
  }[]
  dots: DotRender[]
  labels: DrawnLabel[]
}

interface DrawnLabel {
  key: string
  class: string
  fill: string
  fontSize?: string | number
  items: { x: number; y: number; text: string; anchor: string; dy: string }[]
}

const INITIAL_DIMENSION = { width: -1, height: -1 }
const DEFAULT_MARGIN = { top: 5, right: 5, bottom: 5, left: 5 }

let seriesIds = 0
const ids = new WeakMap<object, string>()
function seriesId(part: object): string {
  let id = ids.get(part)
  if (!id) ids.set(part, (id = `series-${++seriesIds}`))
  return id
}

function num(value: number | undefined, fallback: number): number {
  return typeof value === 'number' && Number.isFinite(value) ? value : fallback
}

function keyOf(dataKey: unknown): string {
  return typeof dataKey === 'function' ? '' : String(dataKey ?? '')
}

function round(value: number): number {
  return Math.round(value * 1000) / 1000
}

/** recharts' `getLegendItemColor`: the stroke, where there is one, else the fill. */
function itemColor(stroke: string | undefined, fill: string | undefined): string | undefined {
  return stroke && stroke !== 'none' ? stroke : fill
}

/** Where a label sits against its point (a zero-size box) or bar, as recharts' Label places it. */
function labelPlacement(
  box: { x: number; y: number; width: number; height: number },
  position: LabelPosition,
  offset: number,
): { x: number; y: number; anchor: string; dy: string } {
  const { x, y, width, height } = box
  const vertical = height >= 0 ? 1 : -1
  const horizontal = width >= 0 ? 1 : -1
  const DY = { start: '0.71em', middle: '0.355em', end: '0em' } as const
  switch (position) {
    case 'top':
      return {
        x: x + width / 2,
        y: y - vertical * offset,
        anchor: 'middle',
        dy: DY[vertical > 0 ? 'end' : 'start'],
      }
    case 'bottom':
      return {
        x: x + width / 2,
        y: y + height + vertical * offset,
        anchor: 'middle',
        dy: DY[vertical > 0 ? 'start' : 'end'],
      }
    case 'left':
      return {
        x: x - horizontal * offset,
        y: y + height / 2,
        anchor: horizontal > 0 ? 'end' : 'start',
        dy: DY.middle,
      }
    case 'right':
      return {
        x: x + width + horizontal * offset,
        y: y + height / 2,
        anchor: horizontal > 0 ? 'start' : 'end',
        dy: DY.middle,
      }
    case 'insideLeft':
      return {
        x: x + horizontal * offset,
        y: y + height / 2,
        anchor: horizontal > 0 ? 'start' : 'end',
        dy: DY.middle,
      }
    case 'insideRight':
      return {
        x: x + width - horizontal * offset,
        y: y + height / 2,
        anchor: horizontal > 0 ? 'end' : 'start',
        dy: DY.middle,
      }
    case 'insideTop':
      return {
        x: x + width / 2,
        y: y + vertical * offset,
        anchor: 'middle',
        dy: DY[vertical > 0 ? 'start' : 'end'],
      }
    case 'insideBottom':
      return {
        x: x + width / 2,
        y: y + height - vertical * offset,
        anchor: 'middle',
        dy: DY[vertical > 0 ? 'end' : 'start'],
      }
    default:
      return { x: x + width / 2, y: y + height / 2, anchor: 'middle', dy: DY.middle }
  }
}

/**
 * Calls `callback` with an element's size now, then on every resize, until it is removed. The
 * size is the element's layout size (`offsetWidth`, as a ResizeObserver reports it), not its
 * box on screen, which a CSS transform scales.
 */
function observeSize(
  context: object,
  element: HTMLElement,
  callback: (size: { width: number; height: number }) => void,
): () => void {
  callback({ width: element.offsetWidth, height: element.offsetHeight })
  const observer = resizeObserver(context)
  const onEntry = (entry: ResizeObserverEntry) =>
    callback({ width: entry.contentRect.width, height: entry.contentRect.height })
  observer.observe(element, onEntry)
  return () => observer.unobserve(element, onEntry)
}

interface SurfaceSignature {
  Args: { chart: CartesianChart }
  Blocks: { default: [] }
  Element: HTMLDivElement
}

/**
 * The chart itself, at its size: recharts' wrapper, its `<svg>` with the marks in recharts'
 * z-index layers, and the legend and tooltip boxes over it.
 */
const Surface: TOC<SurfaceSignature> = <template>
  <div
    class="recharts-wrapper"
    style={{@chart.wrapperStyle}}
    data-test-jn={{unless @chart.args.inContainer "chart"}}
    data-test-jn-name={{unless @chart.args.inContainer @chart.args.name}}
    data-test-jn-part="wrapper"
    data-layout={{@chart.layout}}
    {{on "mousemove" @chart.onMouseMove}}
    {{on "mouseleave" @chart.onMouseLeave}}
    ...attributes
  >
    <svg
      class="recharts-surface"
      width={{@chart.width}}
      height={{@chart.height}}
      viewBox={{@chart.viewBox}}
      style="width: 100%; height: 100%; display: block;"
      role={{if @chart.accessibilityLayer "application"}}
      tabindex={{if @chart.accessibilityLayer "0"}}
      data-test-jn-part="surface"
      {{on "focus" @chart.onFocus}}
      {{on "blur" @chart.onBlur}}
      {{on "keydown" @chart.onKeyDown}}
    >
      <title>{{@chart.args.title}}</title>
      <desc>{{@chart.args.desc}}</desc>
      {{!
        The block registers the chart's parts (and can hold <defs>). Nothing above it may read
        them, in this render or a later one: a part the block adds (inside an if, say) writes
        the registry, and Glimmer forbids writing tracked state the same render has read. So
        everything that reads them, the categories attribute included, comes after it.
      }}
      {{yield}}
      {{#if @chart.geometry}}
        <g class="recharts-zIndex-layer_-100">
          {{#if @chart.grid}}
            <g class="recharts-cartesian-grid" data-test-jn-part="grid">
              {{#if @chart.grid.horizontal.length}}
                <g class="recharts-cartesian-grid-horizontal">
                  {{#each @chart.grid.horizontal as |gridLine|}}
                    <line
                      stroke={{gridLine.stroke}}
                      fill="none"
                      stroke-dasharray={{gridLine.dash}}
                      x1={{gridLine.x1}}
                      y1={{gridLine.y1}}
                      x2={{gridLine.x2}}
                      y2={{gridLine.y2}}
                      data-test-jn-part="grid-line"
                      data-test-jn-value="horizontal"
                    ></line>
                  {{/each}}
                </g>
              {{/if}}
              {{#if @chart.grid.vertical.length}}
                <g class="recharts-cartesian-grid-vertical">
                  {{#each @chart.grid.vertical as |gridLine|}}
                    <line
                      stroke={{gridLine.stroke}}
                      fill="none"
                      stroke-dasharray={{gridLine.dash}}
                      x1={{gridLine.x1}}
                      y1={{gridLine.y1}}
                      x2={{gridLine.x2}}
                      y2={{gridLine.y2}}
                      data-test-jn-part="grid-line"
                      data-test-jn-value="vertical"
                    ></line>
                  {{/each}}
                </g>
              {{/if}}
            </g>
          {{/if}}
        </g>
        <defs>
          <clipPath id={{@chart.clipId}}>
            <rect
              data-test-jn-part="plot"
              data-test-jn-categories={{@chart.categoryCoordinates}}
              x={{@chart.geometry.offset.left}}
              y={{@chart.geometry.offset.top}}
              height={{@chart.geometry.offset.height}}
              width={{@chart.geometry.offset.width}}
            ></rect>
          </clipPath>
        </defs>
        <g class="recharts-zIndex-layer_100">
          {{#each @chart.areas as |area|}}
            <g
              class="recharts-layer recharts-area"
              data-test-jn-part="series"
              data-test-jn-value={{area.key}}
              data-series-type="area"
              data-test-jn-points={{area.points}}
            >
              <g class="recharts-layer">
                {{#if area.areaPath}}
                  <path
                    class="recharts-curve recharts-area-area"
                    stroke-width={{area.strokeWidth}}
                    fill={{area.fill}}
                    fill-opacity={{area.fillOpacity}}
                    stroke="none"
                    d={{area.areaPath}}
                  ></path>
                {{/if}}
                {{#if area.curvePath}}
                  <path
                    class="recharts-curve recharts-area-curve"
                    stroke-width={{area.strokeWidth}}
                    fill="none"
                    stroke={{area.stroke}}
                    stroke-dasharray={{area.strokeDasharray}}
                    d={{area.curvePath}}
                  ></path>
                {{/if}}
              </g>
            </g>
          {{/each}}
        </g>
        <g class="recharts-zIndex-layer_200">
          {{#if @chart.cursor.isRectangle}}
            <path
              class="recharts-rectangle recharts-tooltip-cursor"
              stroke="none"
              fill={{@chart.cursor.fill}}
              pointer-events="none"
              d={{@chart.cursor.d}}
              data-test-jn-part="cursor"
            ></path>
          {{/if}}
        </g>
        <g class="recharts-zIndex-layer_300">
          {{#each @chart.bars as |bar|}}
            <g
              class="recharts-layer recharts-bar"
              data-test-jn-part="series"
              data-test-jn-value={{bar.key}}
              data-series-type="bar"
              data-test-jn-points={{bar.points}}
            >
              <g class="recharts-layer recharts-bar-rectangles">
                <g class="recharts-layer">
                  {{#each bar.bars as |rectangle|}}
                    <g class="recharts-layer recharts-bar-rectangle">
                      <g class="recharts-layer recharts-inactive-bar">
                        <path
                          class="recharts-rectangle"
                          fill={{rectangle.fill}}
                          fill-opacity={{rectangle.fillOpacity}}
                          stroke={{rectangle.stroke}}
                          stroke-width={{rectangle.strokeWidth}}
                          d={{rectangle.d}}
                          data-test-jn-part="bar"
                          data-test-jn-value={{rectangle.value}}
                        ></path>
                      </g>
                    </g>
                  {{/each}}
                </g>
              </g>
            </g>
          {{/each}}
        </g>
        <g class="recharts-zIndex-layer_400">
          {{#each @chart.lines as |lineSeries|}}
            <g
              class="recharts-layer recharts-line"
              data-test-jn-part="series"
              data-test-jn-value={{lineSeries.key}}
              data-series-type="line"
              data-test-jn-points={{lineSeries.points}}
            >
              <g class="recharts-layer recharts-shape">
                {{#if lineSeries.curvePath}}
                  <path
                    class="recharts-curve recharts-line-curve"
                    stroke={{lineSeries.stroke}}
                    stroke-width={{lineSeries.strokeWidth}}
                    stroke-dasharray={{lineSeries.strokeDasharray}}
                    fill="none"
                    d={{lineSeries.curvePath}}
                  ></path>
                {{/if}}
              </g>
            </g>
          {{/each}}
        </g>
        <g class="recharts-zIndex-layer_500">
          {{#each @chart.axes as |axis|}}
            <g
              class="recharts-layer recharts-cartesian-axis recharts-{{axis.kind}} {{axis.kind}}"
              data-test-jn-part={{axis.kind}}
            >
              {{#if axis.line}}
                <line
                  class="recharts-cartesian-axis-line"
                  stroke={{axis.line.stroke}}
                  fill="none"
                  x1={{axis.line.x1}}
                  y1={{axis.line.y1}}
                  x2={{axis.line.x2}}
                  y2={{axis.line.y2}}
                ></line>
              {{/if}}
              <g class="recharts-cartesian-axis-ticks recharts-{{axis.kind}}-ticks">
                <g class="recharts-cartesian-axis-tick-lines recharts-{{axis.kind}}-tick-lines">
                  {{#each axis.ticks as |tick|}}
                    <g class="recharts-layer recharts-cartesian-axis-tick">
                      {{#if tick.tickLine}}
                        <line
                          class="recharts-cartesian-axis-tick-line"
                          stroke={{tick.tickLine.stroke}}
                          fill="none"
                          x1={{tick.tickLine.x1}}
                          y1={{tick.tickLine.y1}}
                          x2={{tick.tickLine.x2}}
                          y2={{tick.tickLine.y2}}
                        ></line>
                      {{/if}}
                    </g>
                  {{/each}}
                </g>
              </g>
            </g>
          {{/each}}
        </g>
        <g class="recharts-zIndex-layer_600">
          {{#each @chart.series as |series|}}
            {{#if series.dots.length}}
              <g
                class="recharts-layer recharts-{{series.type}}-dots"
                data-test-jn-part="dots"
                data-test-jn-value={{series.key}}
              >
                {{#each series.dots as |dot|}}
                  {{#if dot.component}}
                    {{#let dot.component as |Dot|}}
                      <Dot
                        @cx={{dot.args.cx}}
                        @cy={{dot.args.cy}}
                        @r={{dot.args.r}}
                        @index={{dot.args.index}}
                        @value={{dot.args.value}}
                        @payload={{dot.args.payload}}
                        @dataKey={{dot.args.dataKey}}
                        @stroke={{dot.args.stroke}}
                        @strokeWidth={{dot.args.strokeWidth}}
                        @fill={{dot.args.fill}}
                      />
                    {{/let}}
                  {{else}}
                    <circle
                      class="recharts-dot recharts-{{series.type}}-dot {{dot.attrs.class}}"
                      r={{dot.attrs.r}}
                      stroke={{dot.attrs.stroke}}
                      stroke-width={{dot.attrs.strokeWidth}}
                      fill={{dot.attrs.fill}}
                      cx={{dot.args.cx}}
                      cy={{dot.args.cy}}
                    ></circle>
                  {{/if}}
                {{/each}}
              </g>
            {{/if}}
          {{/each}}
        </g>
        <g class="recharts-zIndex-layer_1100">
          {{#if @chart.cursor.isCurve}}
            <path
              class="recharts-curve recharts-tooltip-cursor"
              stroke={{@chart.cursor.stroke}}
              stroke-width={{@chart.cursor.strokeWidth}}
              fill="none"
              pointer-events="none"
              d={{@chart.cursor.d}}
              data-test-jn-part="cursor"
            ></path>
          {{/if}}
        </g>
        <g class="recharts-zIndex-layer_1200">
          {{#each @chart.activeDots as |dot|}}
            <g class="recharts-layer recharts-active-dot" data-test-jn-part="active-dot">
              {{#if dot.component}}
                {{#let dot.component as |Dot|}}
                  <Dot
                    @cx={{dot.args.cx}}
                    @cy={{dot.args.cy}}
                    @r={{dot.args.r}}
                    @index={{dot.args.index}}
                    @value={{dot.args.value}}
                    @payload={{dot.args.payload}}
                    @dataKey={{dot.args.dataKey}}
                    @stroke={{dot.args.stroke}}
                    @strokeWidth={{dot.args.strokeWidth}}
                    @fill={{dot.args.fill}}
                  />
                {{/let}}
              {{else}}
                <circle
                  class="recharts-dot {{dot.attrs.class}}"
                  cx={{dot.args.cx}}
                  cy={{dot.args.cy}}
                  r={{dot.attrs.r}}
                  fill={{dot.attrs.fill}}
                  stroke-width={{dot.attrs.strokeWidth}}
                  stroke={{dot.attrs.stroke}}
                ></circle>
              {{/if}}
            </g>
          {{/each}}
        </g>
        <g class="recharts-zIndex-layer_2000">
          {{#each @chart.axes as |axis|}}
            {{#if axis.showLabels}}
              <g
                class="recharts-cartesian-axis-tick-labels recharts-{{axis.kind}}-tick-labels"
                data-test-jn-part="{{axis.kind}}-labels"
                {{@chart.measureTicks axis.axisKey axis.ticks.length}}
              >
                {{#each axis.ticks as |tick|}}
                  <g class="recharts-layer recharts-cartesian-axis-tick-label">
                    <text
                      class="recharts-text recharts-cartesian-axis-tick-value"
                      stroke="none"
                      x={{tick.label.x}}
                      y={{tick.label.y}}
                      text-anchor={{axis.textAnchor}}
                      fill={{axis.fill}}
                      data-test-jn-part="tick"
                    ><tspan x={{tick.label.x}} dy={{axis.dy}}>{{tick.text}}</tspan></text>
                  </g>
                {{/each}}
              </g>
            {{/if}}
          {{/each}}
          {{#each @chart.labelLists as |list|}}
            <g
              class="recharts-layer recharts-label-list"
              data-test-jn-part="labels"
              data-test-jn-value={{list.series}}
            >
              {{#each list.items as |item|}}
                <text
                  class={{list.class}}
                  x={{item.x}}
                  y={{item.y}}
                  text-anchor={{item.anchor}}
                  fill={{list.fill}}
                  font-size={{list.fontSize}}
                  data-test-jn-part="label"
                ><tspan x={{item.x}} dy={{item.dy}}>{{item.text}}</tspan></text>
              {{/each}}
            </g>
          {{/each}}
        </g>
      {{/if}}
    </svg>
    {{#if @chart.legendPart}}
      <div class="recharts-legend-wrapper" style={{@chart.legendStyle}} {{@chart.measureLegend}}>
        {{#let @chart.legendContent as |Content|}}
          <Content
            @payload={{@chart.legendPayload}}
            @verticalAlign={{@chart.legendVerticalAlign}}
            @config={{@chart.args.config}}
          />
        {{/let}}
      </div>
    {{/if}}
    {{#if @chart.tooltipPart}}
      <div
        class="recharts-tooltip-wrapper"
        tabindex="-1"
        style={{@chart.tooltipStyle}}
        {{@chart.measureTooltip
          @chart.isTooltipActive
          @chart.tooltipLabel
          @chart.tooltipPayload.length
        }}
      >
        {{#let @chart.tooltipContent as |Content|}}
          <Content
            @active={{@chart.isTooltipActive}}
            @payload={{@chart.tooltipPayload}}
            @label={{@chart.tooltipLabel}}
            @config={{@chart.args.config}}
            @coordinate={{@chart.tooltipCoordinate}}
            @tooltip={{@chart.tooltipProps}}
          />
        {{/let}}
      </div>
    {{/if}}
  </div>
</template>

export default class CartesianChart
  extends Component<CartesianChartSignature>
  implements ChartRegistrar
{
  readonly #parts = new Registry<ChartPart>()
  readonly chartId = idFor(this, 'chart')

  @tracked containerSize: { width: number; height: number } | null = null
  @tracked tickStyles: { x: TextStyle; y: TextStyle } = { x: {}, y: {} }
  @tracked legendBox: { width: number; height: number } | null = null
  @tracked tooltipBox: { width: number; height: number } | null = null
  /** The pointer, in the chart's pixels, while it is over the plot area. */
  @tracked pointer: { x: number; y: number } | null = null
  @tracked keyboardIndex: number | null = null
  @tracked keyboardActive = false

  /** Bumped when the page's fonts finish loading, which changes how wide tick labels are. */
  @tracked fontRevision = 0

  constructor(owner: Owner, args: CartesianChartSignature['Args']) {
    super(owner, args)
    // Tick labels are measured to drop those that would overlap, and a web font that loads
    // after the first render changes their size: measure again once it has.
    const fonts = typeof document !== 'undefined' ? document.fonts : undefined
    if (fonts?.addEventListener) {
      const onFontsLoaded = () => {
        clearStringSizeCache()
        this.fontRevision += 1
      }
      fonts.addEventListener('loadingdone', onFontsLoaded)
      registerDestructor(this, () => fonts.removeEventListener('loadingdone', onFontsLoaded))
    }
  }

  register(part: ChartPart): void {
    this.#parts.add(part)
  }

  unregister(part: ChartPart): void {
    this.#parts.remove(part)
  }

  // ---------------------------------------------------------------------------------------
  // Size

  get fixedSize(): boolean {
    return typeof this.args.width === 'number' && typeof this.args.height === 'number'
  }

  get size(): { width: number; height: number } | null {
    if (this.fixedSize) return { width: this.args.width!, height: this.args.height! }
    const measured = this.containerSize
    const size = measured ?? this.args.initialDimension ?? INITIAL_DIMENSION
    if (!(size.width > 0) || !(size.height > 0)) return null
    return size
  }

  // The measurements below compare with untracked copies: a modifier that read the tracked
  // value it sets would run again each time it set it.
  #containerSize: { width: number; height: number } | null = null
  #legendBox: { width: number; height: number } | null = null
  #tooltipBox: { width: number; height: number } | null = null
  #tickStyles: { x: TextStyle; y: TextStyle } = { x: {}, y: {} }

  measureContainer = modifier((element: HTMLElement) =>
    observeSize(this, element, ({ width, height }) => {
      const next = { width: Math.round(width), height: Math.round(height) }
      const current = this.#containerSize
      if (!current || current.width !== next.width || current.height !== next.height) {
        this.#containerSize = next
        this.containerSize = next
      }
    }),
  )

  // ---------------------------------------------------------------------------------------
  // Parts

  get partList(): readonly ChartPart[] {
    return this.#parts.items
  }

  get xAxisPart(): XAxis | undefined {
    return this.partList.find((part): part is XAxis => part instanceof XAxis)
  }

  get yAxisPart(): YAxis | undefined {
    return this.partList.find((part): part is YAxis => part instanceof YAxis)
  }

  get gridPart(): CartesianGrid | undefined {
    return this.partList.find((part): part is CartesianGrid => part instanceof CartesianGrid)
  }

  get tooltipPart(): ChartTooltip | undefined {
    return this.partList.find((part): part is ChartTooltip => part instanceof ChartTooltip)
  }

  get legendPart(): ChartLegend | undefined {
    return this.partList.find((part): part is ChartLegend => part instanceof ChartLegend)
  }

  get seriesParts(): (Area | Bar | Line)[] {
    return this.partList.filter(
      (part): part is Area | Bar | Line =>
        part instanceof Area || part instanceof Bar || part instanceof Line,
    )
  }

  get layout(): Layout {
    return this.args.layout ?? 'horizontal'
  }

  get chartName(): ChartName {
    return this.args.chartName ?? 'ComposedChart'
  }

  get margin(): Required<Margin> {
    const margin = this.args.margin
    if (!margin) return DEFAULT_MARGIN
    return {
      top: margin.top ?? 0,
      right: margin.right ?? 0,
      bottom: margin.bottom ?? 0,
      left: margin.left ?? 0,
    }
  }

  axisSettings(part: XAxis | YAxis | undefined, axis: 'x' | 'y'): AxisSettings {
    const settings = defaultAxis(axis, !part)
    if (!part) {
      // recharts' implicit axes: a hidden category x-axis and a hidden number y-axis, swapped in
      // a vertical chart.
      if (this.layout === 'vertical') settings.type = axis === 'x' ? 'number' : 'category'
      return settings
    }
    const args = part.args as XAxis['args'] & YAxis['args']
    const padding = args.padding as
      { left?: number; right?: number; top?: number; bottom?: number } | undefined
    return {
      ...settings,
      dataKey: args.dataKey,
      type:
        args.type ??
        (this.layout === 'vertical' ? (axis === 'x' ? 'number' : 'category') : settings.type),
      hide: args.hide ?? false,
      height: num(args.height, settings.height),
      width: num(args.width, settings.width),
      orientation: args.orientation ?? settings.orientation,
      mirror: args.mirror ?? false,
      reversed: args.reversed ?? false,
      padding:
        axis === 'x'
          ? { start: padding?.left ?? 0, end: padding?.right ?? 0 }
          : { start: padding?.top ?? 0, end: padding?.bottom ?? 0 },
      domain: args.domain,
      allowDataOverflow: args.allowDataOverflow ?? false,
      allowDecimals: args.allowDecimals ?? true,
      tickCount: num(args.tickCount, settings.tickCount),
      ticks: args.ticks,
      tick: args.tick ?? true,
      tickLine: args.tickLine ?? true,
      axisLine: args.axisLine ?? true,
      tickSize: num(args.tickSize, settings.tickSize),
      tickMargin: num(args.tickMargin, settings.tickMargin),
      minTickGap: num(args.minTickGap, settings.minTickGap),
      interval: args.interval ?? settings.interval,
      tickFormatter: args.tickFormatter,
      unit: args.unit,
      angle: num(args.angle, 0),
      stroke: args.stroke ?? settings.stroke,
      scale: args.scale ?? 'auto',
    }
  }

  seriesSettings(part: Area | Bar | Line): SeriesSettings {
    const args = part.args
    return {
      id: seriesId(part),
      type: part.kind,
      dataKey: args.dataKey,
      name: args.name,
      stackId: args.stackId,
      hide: args.hide ?? false,
      baseValue: part instanceof Area ? part.args.baseValue : undefined,
      barSize: part instanceof Bar ? part.args.barSize : undefined,
      maxBarSize: part instanceof Bar ? part.args.maxBarSize : undefined,
    }
  }

  // ---------------------------------------------------------------------------------------
  // Layout

  @cached
  get geometry(): CartesianGeometry | null {
    void this.fontRevision
    const size = this.size
    if (!size) return null
    const legend = this.legendPart
    return cartesianGeometry({
      chartName: this.chartName,
      layout: this.layout,
      width: size.width,
      height: size.height,
      margin: this.margin,
      data: this.args.data ?? [],
      xAxis: this.axisSettings(this.xAxisPart, 'x'),
      yAxis: this.axisSettings(this.yAxisPart, 'y'),
      series: this.seriesParts.map(part => this.seriesSettings(part)),
      stackOffset: this.args.stackOffset ?? 'none',
      barCategoryGap: this.args.barCategoryGap ?? '10%',
      barGap: this.args.barGap ?? 4,
      barSize: this.args.barSize,
      maxBarSize: this.args.maxBarSize,
      legend:
        legend && this.legendBox
          ? {
              ...this.legendBox,
              verticalAlign: legend.args.verticalAlign ?? 'bottom',
              align: legend.args.align ?? 'center',
              layout: legend.args.layout ?? 'horizontal',
            }
          : undefined,
      tickStyle: this.tickStyles,
      measure: typeof document !== 'undefined',
    })
  }

  /** Where each row sits along the category axis, for the harness to point at. */
  get categoryCoordinates(): string {
    return (this.geometry?.categoryTicks ?? []).map(tick => round(tick.coordinate)).join(' ')
  }

  get width(): number {
    return this.size?.width ?? 0
  }

  get height(): number {
    return this.size?.height ?? 0
  }

  get viewBox(): string {
    const size = this.size!
    return `0 0 ${size.width} ${size.height}`
  }

  get wrapperStyle(): SafeString {
    const size = this.size!
    return htmlSafe(
      `position: relative; cursor: default; width: ${size.width}px; height: ${size.height}px;`,
    )
  }

  get clipId(): string {
    return `${this.chartId}-clip`
  }

  get accessibilityLayer(): boolean {
    return this.args.accessibilityLayer ?? true
  }

  // ---------------------------------------------------------------------------------------
  // Drawing

  get grid() {
    const part = this.gridPart
    const geometry = this.geometry
    if (!part || !geometry) return null
    const { offset } = geometry
    const args = part.args
    const common = { stroke: args.stroke ?? '#ccc', dash: args.strokeDasharray }
    return {
      horizontal:
        args.horizontal === false
          ? []
          : geometry.grid.horizontal.map(y => ({
              ...common,
              x1: offset.left,
              y1: y,
              x2: offset.left + offset.width,
              y2: y,
            })),
      vertical:
        args.vertical === false
          ? []
          : geometry.grid.vertical.map(x => ({
              ...common,
              x1: x,
              y1: offset.top,
              x2: x,
              y2: offset.top + offset.height,
            })),
    }
  }

  drawAxis(axis: AxisGeometry, kind: 'xAxis' | 'yAxis') {
    const settings = axis.settings
    if (settings.hide) return null
    return {
      kind,
      axisKey: kind === 'xAxis' ? ('x' as const) : ('y' as const),
      settings,
      line: settings.axisLine ? { ...axis.line, stroke: settings.stroke, fill: 'none' } : null,
      ticks: axis.ticks.map(tick => ({
        ...tick,
        tickLine: settings.tickLine
          ? { ...tick.line, stroke: settings.stroke, fill: 'none' }
          : null,
      })),
      showLabels: settings.tick,
      textAnchor: axis.textAnchor,
      dy: axis.dy,
      fill: settings.stroke,
    }
  }

  get axes() {
    const geometry = this.geometry
    if (!geometry) return []
    return [this.drawAxis(geometry.xAxis, 'xAxis'), this.drawAxis(geometry.yAxis, 'yAxis')].filter(
      axis => axis !== null,
    )
  }

  drawLabels(part: Area | Bar | Line, geometry: SeriesGeometry): DrawnLabel[] {
    return part.labels.items.map((label: LabelList, i) => {
      const args = label.args
      const offset = num(args.offset, 5)
      const position = args.position ?? (part instanceof Bar ? 'center' : 'top')
      const boxes =
        part instanceof Bar
          ? geometry.bars.map(bar => ({ box: bar, payload: bar.payload, value: bar.value }))
          : geometry.points
              .filter(point => point.x !== null && point.y !== null)
              .map(point => ({
                box: { x: point.x!, y: point.y!, width: 0, height: 0 },
                payload: point.payload,
                value: point.value,
              }))
      return {
        key: `label-${i}`,
        class: ['recharts-text', args.class].filter(Boolean).join(' '),
        fill: args.fill ?? '#808080',
        fontSize: args.fontSize,
        items: boxes.map(({ box, payload, value }) => {
          const raw = args.dataKey !== undefined ? valueOf(payload, args.dataKey) : value
          const shown = args.formatter ? args.formatter(raw as never) : raw
          return { ...labelPlacement(box, position, offset), text: String(shown ?? '') }
        }),
      }
    })
  }

  @cached
  get series(): DrawnSeries[] {
    const geometry = this.geometry
    if (!geometry) return []
    return this.seriesParts.map((part, i) => {
      const drawn = geometry.series[i]!
      const settings = drawn.settings
      const key = keyOf(settings.dataKey)
      const base: DrawnSeries = {
        id: settings.id,
        type: part.kind,
        key,
        name: settings.name ?? key,
        points: drawn.points
          .filter(point => point.x !== null && point.y !== null)
          .map(point => `${round(point.x!)},${round(point.y!)}`)
          .join(' '),
        bars: [],
        dots: [],
        labels: settings.hide ? [] : this.drawLabels(part, drawn),
      }
      if (settings.hide) return base
      if (part instanceof Bar) {
        const args = part.args
        const radius = args.radius ?? 0
        return {
          ...base,
          points: drawn.bars.map(bar => `${round(bar.x)},${round(bar.y)}`).join(' '),
          fill: args.fill,
          bars: drawn.bars.map(bar => ({
            d: rectanglePath(bar.x, bar.y, bar.width, bar.height, radius),
            fill: args.fill,
            fillOpacity: args.fillOpacity,
            stroke: args.stroke,
            strokeWidth: args.strokeWidth,
            x: round(bar.x),
            y: round(bar.y),
            width: round(bar.width),
            height: round(bar.height),
            radius: Array.isArray(radius) ? radius.join(',') : String(radius),
            index: bar.index,
            value: String(bar.value ?? ''),
          })),
        }
      }
      const curveType = part.args.type ?? 'linear'
      const connectNulls = part.args.connectNulls ?? false
      const curvePath = linePath(drawn.points, curveType, this.layout, connectNulls)
      if (part instanceof Area) {
        const args = part.args
        const fill = args.fill ?? '#3182bd'
        const stroke = args.stroke ?? '#3182bd'
        const strokeWidth = args.strokeWidth ?? 1
        return {
          ...base,
          areaPath: areaPath(drawn.points, drawn.base, curveType, this.layout, connectNulls),
          curvePath,
          fill,
          fillOpacity: args.fillOpacity ?? 0.6,
          stroke,
          strokeWidth,
          strokeDasharray: args.strokeDasharray,
          dots: this.dots(args.dot, false, drawn, {
            r: 3,
            fill: '#fff',
            stroke,
            strokeWidth: String(strokeWidth),
          }),
        }
      }
      const args = (part as Line).args
      const stroke = args.stroke ?? '#3182bd'
      const strokeWidth = args.strokeWidth ?? 1
      return {
        ...base,
        curvePath,
        stroke,
        strokeWidth,
        strokeDasharray: args.strokeDasharray,
        fill: args.fill ?? '#fff',
        dots: this.dots(args.dot, true, drawn, {
          r: 3,
          fill: args.fill ?? '#fff',
          stroke,
          strokeWidth: String(strokeWidth),
        }),
      }
    })
  }

  dots(
    option: Area['args']['dot'],
    fallback: boolean,
    drawn: SeriesGeometry,
    defaults: { r: number; fill: string; stroke: string; strokeWidth: string },
  ): DotRender[] {
    const result: DotRender[] = []
    for (const point of drawn.points) {
      if (point.x === null || point.y === null) continue
      const dot = dotFor(option, fallback, defaults, {
        cx: point.x,
        cy: point.y,
        r: defaults.r,
        index: point.index,
        value: point.value,
        payload: point.payload as DotArgs['payload'],
        dataKey: drawn.settings.dataKey,
        stroke: defaults.stroke,
        strokeWidth: defaults.strokeWidth,
        fill: defaults.fill,
      })
      if (dot) result.push(dot)
    }
    return result
  }

  get areas(): DrawnSeries[] {
    return this.series.filter(series => series.type === 'area')
  }

  get bars(): DrawnSeries[] {
    return this.series.filter(series => series.type === 'bar')
  }

  get lines(): DrawnSeries[] {
    return this.series.filter(series => series.type === 'line')
  }

  get labelLists(): (DrawnLabel & { series: string })[] {
    return this.series.flatMap(series =>
      series.labels.map(list => ({ ...list, series: series.key })),
    )
  }

  // ---------------------------------------------------------------------------------------
  // Tooltip

  get activeIndex(): number | null {
    const geometry = this.geometry
    const tooltip = this.tooltipPart
    if (!geometry || !tooltip || tooltip.args.active === false) return null
    const pointer = this.pointer
    if (pointer) {
      return activeIndexAt(
        geometry.categoryTicks,
        this.layout === 'horizontal' ? pointer.x : pointer.y,
      )
    }
    if (this.keyboardActive && this.keyboardIndex !== null) return this.keyboardIndex
    if (typeof tooltip.args.defaultIndex === 'number' && this.keyboardIndex === null)
      return tooltip.args.defaultIndex
    if (tooltip.args.active === true) return this.keyboardIndex ?? 0
    return null
  }

  get isTooltipActive(): boolean {
    return this.activeIndex !== null && this.activeIndex < (this.args.data?.length ?? 0)
  }

  /** Where the tooltip points: the active row's tick, at the pointer (or the first series' point). */
  get activeCoordinate(): { x: number; y: number } | null {
    const geometry = this.geometry
    const index = this.activeIndex
    if (!geometry || index === null) return null
    const tick = geometry.categoryTicks.find(entry => entry.index === index)
    if (!tick) return null
    const pointer = this.pointer
    if (pointer) {
      return this.layout === 'horizontal'
        ? { x: tick.coordinate, y: pointer.y }
        : { x: pointer.x, y: tick.coordinate }
    }
    const first = geometry.series.find(series => !series.settings.hide)
    const point = first?.points[index]
    if (point && point.x !== null && point.y !== null) return { x: point.x, y: point.y }
    const bar = first?.bars.find(entry => entry.index === index)
    if (bar) return { x: bar.x + bar.width / 2, y: bar.y + bar.height / 2 }
    const size = this.size!
    return this.layout === 'horizontal'
      ? { x: tick.coordinate, y: (geometry.offset.top + size.height) / 2 }
      : { x: (geometry.offset.left + size.width) / 2, y: tick.coordinate }
  }

  /**
   * What the tooltip's own arguments pass to its content. They go in one object: passed one by
   * one, an argument the tooltip leaves out would reach the content as `undefined` and override
   * the one curried into it (recharts passes only the props given).
   */
  get tooltipProps(): ChartTooltipContentArgs['tooltip'] {
    const args = this.tooltipPart?.args
    return {
      labelClassName: args?.labelClassName,
      labelFormatter: args?.labelFormatter,
      formatter: args?.formatter,
    }
  }

  get tooltipCoordinate(): { x: number; y: number } | undefined {
    return this.activeCoordinate ?? undefined
  }

  get tooltipPayload(): TooltipPayloadItem[] {
    const index = this.activeIndex
    const tooltip = this.tooltipPart
    if (index === null || !tooltip) return []
    const datum = this.args.data?.[index] as Record<string, unknown> | undefined
    if (datum === undefined) return []
    const filterNull = tooltip.args.filterNull ?? true
    const items: TooltipPayloadItem[] = []
    for (const part of this.seriesParts) {
      const args = part.args
      if (args.hide || args.tooltipType === 'none') continue
      const value = valueOf(datum, args.dataKey)
      if (filterNull && (value === null || value === undefined)) continue
      const fill = 'fill' in args ? (args.fill as string | undefined) : undefined
      const stroke = 'stroke' in args ? (args.stroke as string | undefined) : undefined
      const color =
        part instanceof Bar
          ? fill
          : part instanceof Line
            ? (stroke ?? '#3182bd')
            : itemColor(stroke ?? '#3182bd', fill)
      items.push({
        name: args.name ?? keyOf(args.dataKey),
        value,
        dataKey: args.dataKey,
        color,
        fill: part instanceof Line ? (fill ?? '#fff') : fill,
        stroke,
        payload: datum,
        type: args.tooltipType,
        unit: args.unit,
      })
    }
    // recharts sorts the entries by name.
    return items.sort((a, b) =>
      String(a.name) < String(b.name) ? -1 : String(a.name) > String(b.name) ? 1 : 0,
    )
  }

  get tooltipLabel(): unknown {
    const index = this.activeIndex
    const geometry = this.geometry
    if (index === null || !geometry) return undefined
    return geometry.categoryTicks.find(tick => tick.index === index)?.value
  }

  get tooltipContent(): ComponentLike<{ Args: ChartTooltipContentArgs }> {
    return (
      this.tooltipPart?.args.content ??
      (ChartTooltipContent as unknown as ComponentLike<{ Args: ChartTooltipContentArgs }>)
    )
  }

  get tooltipVisible(): boolean {
    return (
      this.isTooltipActive &&
      this.tooltipPayload.length > 0 &&
      !!this.tooltipBox &&
      this.tooltipBox.width > 0 &&
      this.tooltipBox.height > 0
    )
  }

  get tooltipStyle(): SafeString {
    const base = 'pointer-events: none; position: absolute; top: 0px; left: 0px;'
    const coordinate = this.activeCoordinate
    const box = this.tooltipBox
    const geometry = this.geometry
    if (!this.tooltipVisible || !coordinate || !box || !geometry) {
      return htmlSafe(`visibility: hidden; ${base}`)
    }
    const tooltip = this.tooltipPart!
    const offset = num(tooltip.args.offset, 10)
    const { offset: plot } = geometry
    const x = tooltipTranslate({
      coordinate: coordinate.x,
      offset,
      tooltipSize: box.width,
      viewBoxStart: plot.left,
      viewBoxSize: plot.width,
      allowEscape: false,
      reverse: false,
    })
    const y = tooltipTranslate({
      coordinate: coordinate.y,
      offset,
      tooltipSize: box.height,
      viewBoxStart: plot.top,
      viewBoxSize: plot.height,
      allowEscape: false,
      reverse: false,
    })
    const animate = tooltip.args.isAnimationActive !== false
    return htmlSafe(
      `visibility: visible; ${base}${animate ? ' transition: transform 400ms;' : ''} transform: translate(${x}px, ${y}px);`,
    )
  }

  /** Measures the tooltip's box each time what it shows changes (its arguments). */
  measureTooltip = modifier((element: HTMLElement, positional: [boolean, unknown, number]) => {
    // Read the arguments, so the modifier runs again when they change.
    void [...positional]
    const rect = { width: element.offsetWidth, height: element.offsetHeight }
    const current = this.#tooltipBox
    if (
      !current ||
      Math.abs(current.width - rect.width) > 1 ||
      Math.abs(current.height - rect.height) > 1
    ) {
      this.#tooltipBox = rect
      this.tooltipBox = rect
    }
  })

  get cursor() {
    const tooltip = this.tooltipPart
    const geometry = this.geometry
    const coordinate = this.activeCoordinate
    if (
      !tooltip ||
      !geometry ||
      !coordinate ||
      !this.isTooltipActive ||
      tooltip.args.cursor === false
    )
      return null
    const option = typeof tooltip.args.cursor === 'object' ? tooltip.args.cursor : {}
    const { offset } = geometry
    if (this.chartName === 'BarChart') {
      const half = geometry.bandSize / 2
      const rect =
        this.layout === 'horizontal'
          ? {
              x: coordinate.x - half,
              y: offset.top + 0.5,
              width: geometry.bandSize,
              height: offset.height - 1,
            }
          : {
              x: offset.left + 0.5,
              y: coordinate.y - half,
              width: offset.width - 1,
              height: geometry.bandSize,
            }
      return {
        isRectangle: true,
        isCurve: false,
        d: rectanglePath(rect.x, rect.y, rect.width, rect.height, 0),
        fill: option.fill ?? '#ccc',
        stroke: 'none',
        strokeWidth: undefined,
      }
    }
    const points =
      this.layout === 'horizontal'
        ? [
            { x: coordinate.x, y: offset.top },
            { x: coordinate.x, y: offset.top + offset.height },
          ]
        : [
            { x: offset.left, y: coordinate.y },
            { x: offset.left + offset.width, y: coordinate.y },
          ]
    return {
      isRectangle: false,
      isCurve: true,
      d: linePath(points, 'linear', this.layout) ?? '',
      stroke: option.stroke ?? '#ccc',
      strokeWidth: option.strokeWidth ?? 1,
      fill: 'none',
    }
  }

  get activeDots(): DotRender[] {
    const index = this.activeIndex
    const geometry = this.geometry
    if (index === null || !geometry || !this.isTooltipActive) return []
    const result: DotRender[] = []
    this.seriesParts.forEach((part, i) => {
      if (part instanceof Bar || part.args.hide) return
      const point = geometry.series[i]!.points[index]
      if (!point || point.x === null || point.y === null) return
      const args = part.args
      const stroke = args.stroke ?? '#3182bd'
      const fill = part instanceof Area ? itemColor(stroke, args.fill ?? '#3182bd') : stroke
      const dot = dotFor(
        args.activeDot,
        true,
        { r: 4, fill: fill ?? 'none', stroke: '#fff', strokeWidth: '2' },
        {
          cx: point.x,
          cy: point.y,
          r: 4,
          index,
          value: point.value,
          payload: point.payload as DotArgs['payload'],
          dataKey: args.dataKey,
          fill,
          stroke: '#fff',
          strokeWidth: 2,
        },
      )
      if (dot) result.push(dot)
    })
    return result
  }

  // ---------------------------------------------------------------------------------------
  // Legend

  get legendPayload(): LegendPayloadItem[] {
    const items: LegendPayloadItem[] = []
    for (const part of this.seriesParts) {
      const args = part.args
      if (args.legendType === 'none') continue
      const fill = 'fill' in args ? (args.fill as string | undefined) : undefined
      const stroke = 'stroke' in args ? (args.stroke as string | undefined) : undefined
      items.push({
        value: args.name ?? keyOf(args.dataKey),
        dataKey: args.dataKey,
        color:
          part instanceof Bar
            ? fill
            : part instanceof Line
              ? (stroke ?? '#3182bd')
              : itemColor(stroke ?? '#3182bd', fill ?? '#3182bd'),
        type: args.legendType ?? (part instanceof Bar ? 'rect' : 'line'),
        inactive: args.hide ?? false,
      })
    }
    // recharts sorts the legend by value.
    return items.sort((a, b) => (a.value < b.value ? -1 : a.value > b.value ? 1 : 0))
  }

  get legendVerticalAlign(): 'top' | 'middle' | 'bottom' {
    return this.legendPart?.args.verticalAlign ?? 'bottom'
  }

  get legendContent(): ComponentLike<{ Args: ChartLegendContentArgs }> {
    return (
      this.legendPart?.args.content ??
      (ChartLegendContent as unknown as ComponentLike<{ Args: ChartLegendContentArgs }>)
    )
  }

  get legendStyle(): SafeString {
    const size = this.size!
    const legend = this.legendPart!
    const margin = this.margin
    const layout = legend.args.layout ?? 'horizontal'
    const align = legend.args.align ?? 'center'
    const verticalAlign = legend.args.verticalAlign ?? 'bottom'
    const width = layout === 'horizontal' ? `${size.width - margin.left - margin.right}px` : 'auto'
    const box = this.legendBox ?? { width: 0, height: 0 }
    const horizontal =
      align === 'center' && layout === 'vertical'
        ? `left: ${(size.width - box.width) / 2}px;`
        : align === 'right'
          ? `right: ${margin.right}px;`
          : `left: ${margin.left}px;`
    const vertical =
      verticalAlign === 'middle'
        ? `top: ${(size.height - box.height) / 2}px;`
        : verticalAlign === 'bottom'
          ? `bottom: ${margin.bottom}px;`
          : `top: ${margin.top}px;`
    return htmlSafe(`position: absolute; width: ${width}; height: auto; ${horizontal} ${vertical}`)
  }

  measureLegend = modifier((element: HTMLElement) =>
    observeSize(this, element, ({ width, height }) => {
      const current = this.#legendBox
      if (
        !current ||
        Math.abs(current.width - width) > 1 ||
        Math.abs(current.height - height) > 1
      ) {
        this.#legendBox = { width, height }
        this.legendBox = { width, height }
      }
    }),
  )

  /** Reads the font the tick labels are drawn in, which the axes measure them with. */
  measureTicks = modifier((element: SVGGElement, [axis, count]: ['x' | 'y', number]) => {
    void count
    const text = element.querySelector('.recharts-cartesian-axis-tick-value')
    if (!text) return
    const style = getComputedStyle(text)
    const current = this.#tickStyles[axis]
    if (current.fontSize !== style.fontSize || current.letterSpacing !== style.letterSpacing) {
      this.#tickStyles = {
        ...this.#tickStyles,
        [axis]: { fontSize: style.fontSize, letterSpacing: style.letterSpacing },
      }
      this.tickStyles = this.#tickStyles
    }
  })

  // ---------------------------------------------------------------------------------------
  // Events

  onMouseMove = (event: MouseEvent): void => {
    const geometry = this.geometry
    if (!geometry) return
    const element = event.currentTarget as HTMLElement
    const rect = element.getBoundingClientRect()
    const scaleX = element.offsetWidth ? rect.width / element.offsetWidth : 1
    const scaleY = element.offsetHeight ? rect.height / element.offsetHeight : 1
    const x = (event.clientX - rect.left) / scaleX
    const y = (event.clientY - rect.top) / scaleY
    const { offset } = geometry
    const inside =
      x >= offset.left &&
      x <= offset.left + offset.width &&
      y >= offset.top &&
      y <= offset.top + offset.height
    this.pointer = inside ? { x, y } : null
  }

  onMouseLeave = (): void => {
    this.pointer = null
  }

  onFocus = (): void => {
    if (!this.accessibilityLayer || this.keyboardActive) return
    if (this.keyboardIndex === null) this.keyboardIndex = 0
    this.keyboardActive = true
  }

  onBlur = (): void => {
    if (!this.accessibilityLayer) return
    this.keyboardActive = false
  }

  onKeyDown = (event: KeyboardEvent): void => {
    if (!this.accessibilityLayer) return
    const { key } = event
    if (key !== 'ArrowRight' && key !== 'ArrowLeft' && key !== 'Enter') return
    const current = this.keyboardIndex ?? -1
    if (current < 0) return
    if (key === 'Enter') {
      this.keyboardActive = !this.keyboardActive
      return
    }
    const geometry = this.geometry
    const categoryAxis =
      this.layout === 'horizontal' ? geometry?.xAxis.settings : geometry?.yAxis.settings
    // ArrowRight moves to the next row and ArrowLeft to the previous one, the other way on a
    // reversed category axis, as recharts 3 does in a horizontal chart. In a vertical chart
    // recharts' keyboardEventsMiddleware flips every move (its direction there is never
    // 'left-to-right'), so its ArrowRight goes up to the previous row; Joinery's goes down to
    // the next, as in a horizontal chart. The guide's Keyboard interactions section says so.
    const direction = categoryAxis?.reversed ? -1 : 1
    const next = current + (key === 'ArrowRight' ? 1 : -1) * direction
    const count = geometry?.categoryTicks.length ?? 0
    if (next < 0 || next >= count) return
    this.pointer = null
    this.keyboardIndex = next
    this.keyboardActive = true
  }

  <template>
    {{#let
      (hash
        XAxis=(component XAxis chart=this)
        YAxis=(component YAxis chart=this)
        CartesianGrid=(component CartesianGrid chart=this)
        Area=(component Area chart=this)
        Bar=(component Bar chart=this)
        Line=(component Line chart=this)
        ChartTooltip=(component ChartTooltip chart=this)
        ChartLegend=(component ChartLegend chart=this)
      )
      as |parts|
    }}
      {{#if this.fixedSize}}
        {{! A fixed size: recharts draws the wrapper alone. }}
        {{#if this.size}}
          <Surface @chart={{this}} ...attributes>{{yield parts}}</Surface>
        {{/if}}
      {{else}}
        <div
          class="recharts-responsive-container"
          style="width: 100%; height: 100%; min-width: 0px;"
          {{this.measureContainer}}
        >
          <div style="width: 0px; height: 0px; overflow: visible;">
            {{#if this.size}}
              <Surface @chart={{this}} ...attributes>{{yield parts}}</Surface>
            {{/if}}
          </div>
        </div>
      {{/if}}
    {{/let}}
  </template>
}
