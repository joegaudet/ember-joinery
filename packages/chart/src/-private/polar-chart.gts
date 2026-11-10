/*
 * The chart behind RadarChart and RadialBarChart: recharts' PolarChart, as declarative Glimmer
 * SVG. It measures its box (as recharts' ResponsiveContainer does), collects the parts its block
 * registers, lays them out with ./polar-geometry.ts, and draws them in recharts' layers and with
 * recharts' class names, so shadcn's chart CSS styles them as it styles recharts.
 *
 * recharts is MIT licensed; its notice is in NOTICE, and the build keeps it in the module that
 * ships this (see rollup.config.mjs).
 */
import Component from '@glimmer/component'
import type { TOC } from '@ember/component/template-only'
import { cached, tracked } from '@glimmer/tracking'
import { hash } from '@ember/helper'
import { on } from '@ember/modifier'
import { htmlSafe, type SafeString } from '@ember/template'
import { modifier } from 'ember-modifier'
import type { ComponentLike, WithBoundArgs } from '@glint/template'
import { idFor } from '@ember-joinery/primitives/id'
import { resizeObserver } from '@ember-joinery/primitives/resize-observer'
import { Registry } from './registry.ts'
import { tooltipTranslate, valueOf, type Margin, type StackOffset } from './cartesian.ts'
import { ChartLegend, ChartTooltip, type ChartPart, type DotArgs } from './parts.gts'
import { isPlainObject } from './dots.ts'
import {
  activeTickIndex,
  gridPolygonPath,
  inRangeOfSector,
  polarGeometry,
  polarLabelAttrs,
  polarToCartesian,
  polygonPath,
  radialLabelPath,
  rangePolygonPath,
  sectorPath,
  TEXT_DY,
  defaultAngleAxis,
  defaultRadiusAxis,
  type PolarAxisSettings,
  type PolarChartName,
  type PolarGeometry,
  type PolarLayout,
  type PolarPosition,
  type PolarTick,
  type PolarViewBox,
  type RadialBarSector,
} from './polar-geometry.ts'
import {
  PolarAngleAxis,
  PolarGrid,
  PolarRadiusAxis,
  Radar,
  RadialBar,
  type PolarAngleAxisTickArgs,
  type PolarLabelContentSignature,
  type PolarPart,
  type PolarRegistrar,
  type RadarDotOption,
} from './polar-parts.gts'
import ChartTooltipContent from '../components/chart-tooltip-content.gts'
import ChartLegendContent from '../components/chart-legend-content.gts'
import type {
  ChartConfig,
  ChartLegendContentArgs,
  ChartTooltipContentArgs,
  LegendPayloadItem,
  TooltipPayloadItem,
} from '../types.ts'

/** What a polar chart yields: its parts, each a component bound to the chart. */
export interface PolarChartParts {
  /** The grid behind the chart: recharts' `PolarGrid`. */
  PolarGrid: WithBoundArgs<typeof PolarGrid, 'chart'>
  /** The axis round the chart: recharts' `PolarAngleAxis`. */
  PolarAngleAxis: WithBoundArgs<typeof PolarAngleAxis, 'chart'>
  /** The axis out from its centre: recharts' `PolarRadiusAxis`. */
  PolarRadiusAxis: WithBoundArgs<typeof PolarRadiusAxis, 'chart'>
  /** A radar series: recharts' `Radar`. */
  Radar: WithBoundArgs<typeof Radar, 'chart'>
  /** A radial bar series: recharts' `RadialBar`. */
  RadialBar: WithBoundArgs<typeof RadialBar, 'chart'>
  /** The tooltip: shadcn's `ChartTooltip`. */
  ChartTooltip: WithBoundArgs<typeof ChartTooltip, 'chart'>
  /** The legend: shadcn's `ChartLegend`. */
  ChartLegend: WithBoundArgs<typeof ChartLegend, 'chart'>
}

export interface PolarChartSignature {
  Args: {
    /** The rows to draw. */
    data: readonly unknown[]
    /** The space around the chart's ring. Default 5 on every side; given, a side left out is 0. */
    margin?: Margin
    /** The ring's centre: pixels, or a percentage of the chart's size. Default `50%`. */
    cx?: number | string
    cy?: number | string
    /** The ring's radii: pixels, or a percentage of the largest that fits. Default 0 and `80%`. */
    innerRadius?: number | string
    outerRadius?: number | string
    /**
     * Where the angle axis starts and ends, in degrees counter-clockwise from 3 o'clock. A radar
     * chart's default is 90 to -270 (from 12 o'clock, clockwise); a radial bar chart's 0 to 360.
     */
    startAngle?: number
    endAngle?: number
    /** How stacked radial bars stack: `none` (default), `expand` (to 100%), `sign`… */
    stackOffset?: StackOffset
    /** The space between radial bar bands' bars and the band's edge. Default `10%`. */
    barCategoryGap?: number | string
    /** The space between radial bars in a band. Default 4. */
    barGap?: number | string
    /** Every radial bar's width, instead of an equal share of the band. */
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
    /** Set by `RadarChart` and `RadialBarChart`. */
    chartName?: PolarChartName
  }
  Blocks: {
    /** The chart's parts. The block renders inside the chart's `<svg>`, so it can hold `<defs>`. */
    default: [PolarChartParts]
  }
  Element: HTMLDivElement
}

type Anchor = 'start' | 'middle' | 'end'

interface DrawnDot {
  component?: ComponentLike<{ Args: DotArgs; Element: Element }>
  args: DotArgs
  attrs: {
    r?: number
    fill?: string
    fillOpacity?: string | number
    stroke?: string
    strokeWidth?: string | number
    class: string
  }
}

interface DrawnRadar {
  key: string
  class: string
  points: string
  d: string | null
  /** A range radar (values `[low, high]`): the ring between its outlines, and each outline. */
  range: { area: string; outer: string | null; inner: string | null } | null
  fill?: string
  fillOpacity?: string | number
  stroke?: string
  strokeWidth?: string | number
  dots: DrawnDot[]
}

interface DrawnSector {
  d: string | null
  fill?: string
  fillOpacity?: string | number
  stroke?: string
  strokeWidth?: string | number
  index: number
  value: string
}

interface DrawnLabelItem {
  text: string
  fill?: string
  /** A label along its bar: the arc its `<textPath>` follows. */
  arc?: { id: string; d: string }
  x?: number
  y?: number
  anchor?: Anchor
  dy?: string
}

interface DrawnLabelList {
  key: string
  class: string
  fontSize?: string | number
  items: DrawnLabelItem[]
}

interface DrawnRadialBar {
  key: string
  class: string
  points: string
  hasBackground: boolean
  background: { d: string | null; fill: string; class: string }[]
  sectors: DrawnSector[]
  labels: DrawnLabelList[]
}

const INITIAL_DIMENSION = { width: -1, height: -1 }
const DEFAULT_MARGIN = { top: 5, right: 5, bottom: 5, left: 5 }
const EPS = 1e-5
const COS_45 = Math.cos(45 * (Math.PI / 180))

let seriesIds = 0
const ids = new WeakMap<object, string>()
function seriesId(part: object): string {
  let id = ids.get(part)
  if (!id) ids.set(part, (id = `polar-series-${++seriesIds}`))
  return id
}

let labelIds = 0

function keyOf(dataKey: unknown): string {
  return typeof dataKey === 'function' ? '' : String(dataKey ?? '')
}

function round(value: number): number {
  return Math.round(value * 1000) / 1000
}

function asText(value: unknown): string {
  return value === null || value === undefined ? '' : String(value)
}

/** recharts' `getLegendItemColor`: the stroke, where there is one, else the fill. */
function itemColor(stroke: string | undefined, fill: string | undefined): string | undefined {
  return stroke && stroke !== 'none' ? stroke : fill
}

/** Calls `callback` with an element's layout size now, then on every resize, until removed. */
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
  Args: { chart: PolarChart }
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
    data-polar-chart={{@chart.chartName}}
    {{on "mousemove" @chart.onMouseMove}}
    {{on "mouseleave" @chart.onMouseLeave}}
    ...attributes
  >
    <svg
      class="recharts-surface"
      width={{@chart.width}}
      height={{@chart.height}}
      viewBox={{@chart.viewBoxAttribute}}
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
        them, in this render or a later one: see ./registry.ts.
      }}
      {{yield}}
      {{#if @chart.geometry}}
        <g class="recharts-zIndex-layer_-100">
          {{#if @chart.grid}}
            <g
              class="recharts-polar-grid"
              data-test-jn-part="polar-grid"
              data-grid-type={{@chart.grid.gridType}}
            >
              <g class="recharts-polar-grid-concentric">
                {{#if @chart.grid.background}}
                  {{#if @chart.grid.circle}}
                    <circle
                      stroke={{@chart.grid.stroke}}
                      fill={{@chart.grid.background.fill}}
                      fill-opacity={{@chart.grid.fillOpacity}}
                      stroke-width={{@chart.grid.strokeWidth}}
                      stroke-dasharray={{@chart.grid.strokeDasharray}}
                      class="recharts-polar-grid-concentric-circle {{@chart.grid.class}}"
                      cx={{@chart.grid.cx}}
                      cy={{@chart.grid.cy}}
                      r={{@chart.grid.background.radius}}
                    ></circle>
                  {{else}}
                    <path
                      stroke={{@chart.grid.stroke}}
                      fill={{@chart.grid.background.fill}}
                      fill-opacity={{@chart.grid.fillOpacity}}
                      stroke-width={{@chart.grid.strokeWidth}}
                      stroke-dasharray={{@chart.grid.strokeDasharray}}
                      class="recharts-polar-grid-concentric-polygon {{@chart.grid.class}}"
                      d={{@chart.grid.background.d}}
                    ></path>
                  {{/if}}
                {{/if}}
                {{#each @chart.grid.rings as |ring|}}
                  {{#if @chart.grid.circle}}
                    <circle
                      stroke={{@chart.grid.stroke}}
                      fill="none"
                      stroke-width={{@chart.grid.strokeWidth}}
                      stroke-dasharray={{@chart.grid.strokeDasharray}}
                      class="recharts-polar-grid-concentric-circle {{@chart.grid.class}}"
                      cx={{@chart.grid.cx}}
                      cy={{@chart.grid.cy}}
                      r={{ring.radius}}
                      data-test-jn-part="grid-ring"
                      data-test-jn-value={{ring.radius}}
                    ></circle>
                  {{else}}
                    <path
                      stroke={{@chart.grid.stroke}}
                      fill="none"
                      stroke-width={{@chart.grid.strokeWidth}}
                      stroke-dasharray={{@chart.grid.strokeDasharray}}
                      class="recharts-polar-grid-concentric-polygon {{@chart.grid.class}}"
                      d={{ring.d}}
                      data-test-jn-part="grid-ring"
                      data-test-jn-value={{ring.radius}}
                    ></path>
                  {{/if}}
                {{/each}}
              </g>
              {{#if @chart.grid.spokes.length}}
                <g class="recharts-polar-grid-angle">
                  {{#each @chart.grid.spokes as |spoke|}}
                    <line
                      stroke={{@chart.grid.stroke}}
                      stroke-width={{@chart.grid.strokeWidth}}
                      stroke-dasharray={{@chart.grid.strokeDasharray}}
                      fill={{@chart.grid.fill}}
                      class={{@chart.grid.class}}
                      x1={{spoke.x1}}
                      y1={{spoke.y1}}
                      x2={{spoke.x2}}
                      y2={{spoke.y2}}
                      data-test-jn-part="grid-spoke"
                      data-test-jn-value={{spoke.angle}}
                    ></line>
                  {{/each}}
                </g>
              {{/if}}
            </g>
          {{/if}}
        </g>
        <g class="recharts-zIndex-layer_-50">
          {{#each @chart.radialBars as |bar|}}
            {{#each bar.background as |sector|}}
              <g class="recharts-layer recharts-shape">
                <path
                  fill={{sector.fill}}
                  class="recharts-sector recharts-radial-bar-background-sector {{sector.class}}"
                  d={{sector.d}}
                  data-test-jn-part="background-sector"
                ></path>
              </g>
            {{/each}}
          {{/each}}
        </g>
        <defs>
          <clipPath id={{@chart.clipId}}>
            <rect
              data-test-jn-part="plot"
              data-test-jn-categories={{@chart.categoryCoordinates}}
              data-test-jn-ring={{@chart.ringAttribute}}
              x={{@chart.geometry.offset.left}}
              y={{@chart.geometry.offset.top}}
              height={{@chart.geometry.offset.height}}
              width={{@chart.geometry.offset.width}}
            ></rect>
          </clipPath>
        </defs>
        <g class="recharts-zIndex-layer_100">
          {{#each @chart.radars as |radar|}}
            <g
              class="recharts-layer recharts-radar {{radar.class}}"
              data-test-jn-part="series"
              data-test-jn-value={{radar.key}}
              data-series-type="radar"
              data-test-jn-points={{radar.points}}
            >
              <g class="recharts-layer recharts-radar-polygon">
                {{#if radar.range}}
                  <g class="recharts-polygon">
                    <path
                      fill={{radar.fill}}
                      fill-opacity={{radar.fillOpacity}}
                      stroke="none"
                      stroke-width={{radar.strokeWidth}}
                      d={{radar.range.area}}
                    ></path>
                    {{#if radar.range.outer}}
                      <path
                        fill="none"
                        stroke={{radar.stroke}}
                        stroke-width={{radar.strokeWidth}}
                        d={{radar.range.outer}}
                      ></path>
                      <path
                        fill="none"
                        stroke={{radar.stroke}}
                        stroke-width={{radar.strokeWidth}}
                        d={{radar.range.inner}}
                      ></path>
                    {{/if}}
                  </g>
                {{else if radar.d}}
                  <path
                    fill={{radar.fill}}
                    fill-opacity={{radar.fillOpacity}}
                    stroke={{radar.stroke}}
                    stroke-width={{radar.strokeWidth}}
                    class="recharts-polygon"
                    d={{radar.d}}
                  ></path>
                {{/if}}
              </g>
            </g>
          {{/each}}
        </g>
        <g class="recharts-zIndex-layer_300">
          {{#each @chart.radialBars as |bar|}}
            <g
              class="recharts-layer recharts-area {{bar.class}}"
              data-test-jn-part="series"
              data-test-jn-value={{bar.key}}
              data-series-type="radial-bar"
              data-test-jn-points={{bar.points}}
            >
              {{#if bar.hasBackground}}
                <g class="recharts-layer recharts-radial-bar-background"></g>
              {{/if}}
              <g class="recharts-layer recharts-radial-bar-sectors">
                {{#each bar.sectors as |sector|}}
                  <g class="recharts-layer recharts-shape">
                    {{#if sector.d}}
                      <path
                        fill={{sector.fill}}
                        fill-opacity={{sector.fillOpacity}}
                        stroke={{sector.stroke}}
                        stroke-width={{sector.strokeWidth}}
                        class="recharts-sector recharts-radial-bar-sector"
                        d={{sector.d}}
                        data-test-jn-part="sector"
                        data-test-jn-value={{sector.index}}
                      ></path>
                    {{/if}}
                  </g>
                {{/each}}
              </g>
            </g>
          {{/each}}
        </g>
        <g class="recharts-zIndex-layer_500">
          {{#if @chart.angleAxis}}
            <g
              class="recharts-layer recharts-polar-angle-axis angleAxis {{@chart.angleAxis.class}}"
              data-test-jn-part="angle-axis"
            >
              {{#if @chart.angleAxis.line}}
                {{#if @chart.angleAxis.line.circle}}
                  <circle
                    class="recharts-dot recharts-polar-angle-axis-line"
                    fill="none"
                    stroke={{@chart.angleAxis.stroke}}
                    cx={{@chart.angleAxis.line.cx}}
                    cy={{@chart.angleAxis.line.cy}}
                    r={{@chart.angleAxis.line.r}}
                  ></circle>
                {{else}}
                  <path
                    class="recharts-polygon recharts-polar-angle-axis-line"
                    fill="none"
                    stroke={{@chart.angleAxis.stroke}}
                    d={{@chart.angleAxis.line.d}}
                  ></path>
                {{/if}}
              {{/if}}
              <g class="recharts-layer recharts-polar-angle-axis-ticks">
                {{#each @chart.angleAxis.ticks as |tick|}}
                  <g class="recharts-layer recharts-polar-angle-axis-tick">
                    {{#if tick.line}}
                      <line
                        class="recharts-polar-angle-axis-tick-line"
                        fill="none"
                        stroke={{@chart.angleAxis.stroke}}
                        x1={{tick.line.x1}}
                        y1={{tick.line.y1}}
                        x2={{tick.line.x2}}
                        y2={{tick.line.y2}}
                      ></line>
                    {{/if}}
                    {{#if @chart.angleAxis.tickComponent}}
                      {{#let @chart.angleAxis.tickComponent as |Tick|}}
                        <Tick
                          @x={{tick.args.x}}
                          @y={{tick.args.y}}
                          @textAnchor={{tick.args.textAnchor}}
                          @verticalAnchor={{tick.args.verticalAnchor}}
                          @index={{tick.args.index}}
                          @payload={{tick.args.payload}}
                          @value={{tick.args.value}}
                          @fill={{tick.args.fill}}
                          @stroke={{tick.args.stroke}}
                          @cx={{tick.args.cx}}
                          @cy={{tick.args.cy}}
                          @radius={{tick.args.radius}}
                        />
                      {{/let}}
                    {{else if @chart.angleAxis.showLabels}}
                      <text
                        stroke="none"
                        x={{tick.args.x}}
                        y={{tick.args.y}}
                        class="recharts-text recharts-polar-angle-axis-tick-value"
                        text-anchor={{tick.args.textAnchor}}
                        fill={{@chart.angleAxis.labelFill}}
                        data-test-jn-part="tick"
                      ><tspan x={{tick.args.x}} dy={{tick.dy}}>{{tick.text}}</tspan></text>
                    {{/if}}
                  </g>
                {{/each}}
              </g>
            </g>
          {{/if}}
          {{#if @chart.radiusAxis}}
            <g
              class="recharts-layer recharts-polar-radius-axis radiusAxis
                {{@chart.radiusAxis.class}}"
              data-test-jn-part="radius-axis"
            >
              {{#if @chart.radiusAxis.line}}
                <line
                  class="recharts-polar-radius-axis-line"
                  stroke={{@chart.radiusAxis.stroke}}
                  fill="none"
                  x1={{@chart.radiusAxis.line.x1}}
                  y1={{@chart.radiusAxis.line.y1}}
                  x2={{@chart.radiusAxis.line.x2}}
                  y2={{@chart.radiusAxis.line.y2}}
                ></line>
              {{/if}}
              {{#if @chart.radiusAxis.ticks.length}}
                <g class="recharts-layer recharts-polar-radius-axis-ticks">
                  {{#each @chart.radiusAxis.ticks as |tick|}}
                    <g class="recharts-layer recharts-polar-radius-axis-tick">
                      <text
                        transform={{tick.transform}}
                        stroke="none"
                        x={{tick.x}}
                        y={{tick.y}}
                        class="recharts-text recharts-polar-radius-axis-tick-value"
                        text-anchor={{@chart.radiusAxis.textAnchor}}
                        fill={{@chart.radiusAxis.stroke}}
                        data-test-jn-part="tick"
                      ><tspan x={{tick.x}} dy="0em">{{tick.text}}</tspan></text>
                    </g>
                  {{/each}}
                </g>
              {{/if}}
              {{#each @chart.radiusAxis.labels as |label|}}
                {{#if label.content}}
                  {{#let label.content as |Content|}}
                    <Content
                      @viewBox={{label.viewBox}}
                      @value={{label.value}}
                      @offset={{label.offset}}
                      @position={{label.position}}
                    />
                  {{/let}}
                {{else if label.arc}}
                  <text
                    fill={{label.fill}}
                    font-size={{label.fontSize}}
                    class="recharts-radial-bar-label {{label.class}}"
                    dominant-baseline="central"
                    data-test-jn-part="axis-label"
                  ><defs><path id={{label.arc.id}} d={{label.arc.d}}></path></defs><textPath
                      href="#{{label.arc.id}}"
                    >{{label.text}}</textPath></text>
                {{else}}
                  <text
                    x={{label.x}}
                    y={{label.y}}
                    text-anchor={{label.anchor}}
                    fill={{label.fill}}
                    font-size={{label.fontSize}}
                    class="recharts-text recharts-label {{label.class}}"
                    data-test-jn-part="axis-label"
                  ><tspan x={{label.x}} dy={{label.dy}}>{{label.text}}</tspan></text>
                {{/if}}
              {{/each}}
            </g>
          {{/if}}
        </g>
        <g class="recharts-zIndex-layer_600">
          {{#each @chart.radars as |radar|}}
            {{#if radar.dots.length}}
              <g
                class="recharts-layer recharts-radar-dots"
                data-test-jn-part="dots"
                data-test-jn-value={{radar.key}}
              >
                {{#each radar.dots as |dot|}}
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
                      r={{dot.attrs.r}}
                      fill={{dot.attrs.fill}}
                      fill-opacity={{dot.attrs.fillOpacity}}
                      stroke={{dot.attrs.stroke}}
                      stroke-width={{dot.attrs.strokeWidth}}
                      cx={{dot.args.cx}}
                      cy={{dot.args.cy}}
                      class={{dot.attrs.class}}
                    ></circle>
                  {{/if}}
                {{/each}}
              </g>
            {{/if}}
          {{/each}}
        </g>
        <g class="recharts-zIndex-layer_1100">
          {{#if @chart.cursor}}
            <path
              class="{{@chart.cursor.class}} recharts-tooltip-cursor"
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
                  class={{dot.attrs.class}}
                  cx={{dot.args.cx}}
                  cy={{dot.args.cy}}
                  r={{dot.attrs.r}}
                  fill={{dot.attrs.fill}}
                  fill-opacity={{dot.attrs.fillOpacity}}
                  stroke-width={{dot.attrs.strokeWidth}}
                  stroke={{dot.attrs.stroke}}
                ></circle>
              {{/if}}
            </g>
          {{/each}}
        </g>
        <g class="recharts-zIndex-layer_2000">
          {{#each @chart.labelLists as |list|}}
            <g
              class="recharts-layer recharts-label-list"
              data-test-jn-part="labels"
              data-test-jn-value={{list.series}}
            >
              {{#each list.items as |item|}}
                {{#if item.arc}}
                  <text
                    fill={{item.fill}}
                    class="recharts-radial-bar-label {{list.class}}"
                    font-size={{list.fontSize}}
                    dominant-baseline="central"
                    data-test-jn-part="label"
                  ><defs><path id={{item.arc.id}} d={{item.arc.d}}></path></defs><textPath
                      href="#{{item.arc.id}}"
                    >{{item.text}}</textPath></text>
                {{else}}
                  <text
                    x={{item.x}}
                    y={{item.y}}
                    text-anchor={{item.anchor}}
                    fill={{item.fill}}
                    font-size={{list.fontSize}}
                    class="recharts-text recharts-label {{list.class}}"
                    data-test-jn-part="label"
                  ><tspan x={{item.x}} dy={{item.dy}}>{{item.text}}</tspan></text>
                {{/if}}
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

export default class PolarChart extends Component<PolarChartSignature> implements PolarRegistrar {
  readonly #parts = new Registry<PolarPart | ChartPart>()
  readonly chartId = idFor(this, 'chart')

  @tracked containerSize: { width: number; height: number } | null = null
  @tracked legendBox: { width: number; height: number } | null = null
  @tracked tooltipBox: { width: number; height: number } | null = null
  /** The pointer, in the chart's pixels, while it is over the chart. */
  @tracked pointer: { x: number; y: number } | null = null
  @tracked keyboardIndex: number | null = null
  @tracked keyboardActive = false

  register(part: PolarPart | ChartPart): void {
    this.#parts.add(part)
  }

  unregister(part: PolarPart | ChartPart): void {
    this.#parts.remove(part)
  }

  // ---------------------------------------------------------------------------------------
  // Size

  get fixedSize(): boolean {
    return typeof this.args.width === 'number' && typeof this.args.height === 'number'
  }

  get size(): { width: number; height: number } | null {
    if (this.fixedSize) return { width: this.args.width!, height: this.args.height! }
    const size = this.containerSize ?? this.args.initialDimension ?? INITIAL_DIMENSION
    if (!(size.width > 0) || !(size.height > 0)) return null
    return size
  }

  // The measurements below compare with untracked copies: a modifier that read the tracked
  // value it sets would run again each time it set it.
  #containerSize: { width: number; height: number } | null = null
  #legendBox: { width: number; height: number } | null = null
  #tooltipBox: { width: number; height: number } | null = null

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

  get width(): number {
    return this.size?.width ?? 0
  }

  get height(): number {
    return this.size?.height ?? 0
  }

  get viewBoxAttribute(): string {
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
  // Parts

  get partList(): readonly (PolarPart | ChartPart)[] {
    return this.#parts.items
  }

  get gridPart(): PolarGrid | undefined {
    return this.partList.find((part): part is PolarGrid => part instanceof PolarGrid)
  }

  get angleAxisPart(): PolarAngleAxis | undefined {
    return this.partList.find((part): part is PolarAngleAxis => part instanceof PolarAngleAxis)
  }

  get radiusAxisPart(): PolarRadiusAxis | undefined {
    return this.partList.find((part): part is PolarRadiusAxis => part instanceof PolarRadiusAxis)
  }

  get radarParts(): Radar[] {
    return this.partList.filter((part): part is Radar => part instanceof Radar)
  }

  get radialBarParts(): RadialBar[] {
    return this.partList.filter((part): part is RadialBar => part instanceof RadialBar)
  }

  get seriesParts(): (Radar | RadialBar)[] {
    return this.partList.filter(
      (part): part is Radar | RadialBar => part instanceof Radar || part instanceof RadialBar,
    )
  }

  get tooltipPart(): ChartTooltip | undefined {
    return this.partList.find((part): part is ChartTooltip => part instanceof ChartTooltip)
  }

  get legendPart(): ChartLegend | undefined {
    return this.partList.find((part): part is ChartLegend => part instanceof ChartLegend)
  }

  get chartName(): PolarChartName {
    return this.args.chartName ?? 'RadarChart'
  }

  get layout(): PolarLayout {
    return this.chartName === 'RadarChart' ? 'centric' : 'radial'
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

  axisSettings(part: PolarAngleAxis | PolarRadiusAxis | undefined, axis: 'angle' | 'radius') {
    const settings: PolarAxisSettings = axis === 'angle' ? defaultAngleAxis() : defaultRadiusAxis()
    if (!part) return settings
    const args = part.args
    return {
      ...settings,
      dataKey: args.dataKey,
      type: args.type ?? 'auto',
      domain: args.domain,
      allowDecimals: args.allowDecimals ?? settings.allowDecimals,
      // A PolarAngleAxis has no tick count unless given; a PolarRadiusAxis aims for 5.
      tickCount: args.tickCount ?? settings.tickCount,
      ticks: args.ticks,
      reversed: args.reversed ?? false,
      scale: args.scale ?? 'auto',
    } satisfies PolarAxisSettings
  }

  // ---------------------------------------------------------------------------------------
  // Layout

  @cached
  get geometry(): PolarGeometry | null {
    const size = this.size
    if (!size) return null
    const radar = this.chartName === 'RadarChart'
    const legend = this.legendPart
    return polarGeometry({
      chartName: this.chartName,
      layout: this.layout,
      width: size.width,
      height: size.height,
      margin: this.margin,
      legend:
        legend && this.legendBox
          ? {
              ...this.legendBox,
              verticalAlign: legend.args.verticalAlign ?? 'bottom',
              align: legend.args.align ?? 'center',
              layout: legend.args.layout ?? 'horizontal',
            }
          : undefined,
      cx: this.args.cx ?? '50%',
      cy: this.args.cy ?? '50%',
      innerRadius: this.args.innerRadius ?? 0,
      outerRadius: this.args.outerRadius ?? '80%',
      startAngle: this.args.startAngle ?? (radar ? 90 : 0),
      endAngle: this.args.endAngle ?? (radar ? -270 : 360),
      data: this.args.data ?? [],
      angleAxis: this.axisSettings(this.angleAxisPart, 'angle'),
      radiusAxis: this.axisSettings(this.radiusAxisPart, 'radius'),
      radars: this.radarParts.map(part => ({
        id: seriesId(part),
        dataKey: part.args.dataKey,
        hide: part.args.hide ?? false,
      })),
      radialBars: this.radialBarParts.map(part => ({
        id: seriesId(part),
        dataKey: part.args.dataKey,
        stackId: part.args.stackId,
        hide: part.args.hide ?? false,
        minPointSize: part.args.minPointSize ?? 0,
        barSize: part.args.barSize,
        maxBarSize: part.args.maxBarSize,
      })),
      stackOffset: this.args.stackOffset ?? 'none',
      barGap: this.args.barGap ?? 4,
      barCategoryGap: this.args.barCategoryGap ?? '10%',
      barSize: this.args.barSize,
      maxBarSize: this.args.maxBarSize,
    })
  }

  get viewBox(): PolarViewBox | null {
    return this.geometry?.viewBox ?? null
  }

  /** Where each row sits on the tooltip's axis (an angle, or a radius), for the harness. */
  get categoryCoordinates(): string {
    return (this.geometry?.tooltipTicks ?? []).map(tick => round(tick.coordinate)).join(' ')
  }

  /** The ring, for the harness: `cx cy innerRadius outerRadius startAngle endAngle`. */
  get ringAttribute(): string {
    const box = this.viewBox
    if (!box) return ''
    return [box.cx, box.cy, box.innerRadius, box.outerRadius, box.startAngle, box.endAngle]
      .map(round)
      .join(' ')
  }

  // ---------------------------------------------------------------------------------------
  // Drawing

  get grid() {
    const part = this.gridPart
    const geometry = this.geometry
    if (!part || !geometry) return null
    const { cx, cy, innerRadius, outerRadius } = geometry.viewBox
    if (outerRadius <= 0) return null
    const args = part.args
    const angles = args.polarAngles ?? geometry.angleAxis.ticks.map(tick => tick.coordinate)
    const radii = args.polarRadius ?? geometry.radiusAxis.ticks.map(tick => tick.coordinate)
    if (!radii.length) return null
    const circle = args.gridType === 'circle'
    const max = Math.max(...radii)
    return {
      gridType: circle ? 'circle' : 'polygon',
      circle,
      cx,
      cy,
      stroke: args.stroke ?? '#ccc',
      strokeWidth: args.strokeWidth,
      strokeDasharray: args.strokeDasharray,
      fill: args.fill,
      fillOpacity: args.fillOpacity,
      class: args.class,
      background:
        args.fill && args.fill !== 'none'
          ? { fill: args.fill, radius: max, d: gridPolygonPath(max, cx, cy, angles) }
          : null,
      rings: radii.map(radius => ({ radius, d: gridPolygonPath(radius, cx, cy, angles) })),
      spokes:
        args.radialLines === false
          ? []
          : angles.map(angle => {
              const start = polarToCartesian(cx, cy, innerRadius, angle)
              const end = polarToCartesian(cx, cy, outerRadius, angle)
              return { angle, x1: start.x, y1: start.y, x2: end.x, y2: end.y }
            }),
    }
  }

  get angleAxis() {
    const part = this.angleAxisPart
    const geometry = this.geometry
    if (!part || !geometry || part.args.hide || !geometry.angleAxisTicks.length) return null
    const args = part.args
    const { cx, cy, outerRadius: radius } = geometry.viewBox
    const ticks = geometry.angleAxisTicks
    const outer = (args.orientation ?? 'outer') === 'outer'
    const tickSize = args.tickSize || 8
    const tick = args.tick ?? true
    const tickComponent =
      tick === true || tick === false
        ? undefined
        : (tick as ComponentLike<{ Args: PolarAngleAxisTickArgs; Element: SVGElement }>)
    const axisLine = args.axisLine ?? true
    return {
      class: args.class,
      stroke: args.stroke,
      labelFill: args.stroke ?? '#808080',
      showLabels: tick !== false,
      tickComponent,
      line: axisLine
        ? args.axisLineType === 'circle'
          ? { circle: true, cx, cy, r: radius, d: null }
          : {
              circle: false,
              d: polygonPath(
                ticks.map(entry => polarToCartesian(cx, cy, radius, entry.coordinate)),
              ),
            }
        : null,
      ticks: ticks.map((entry, index) => {
        const start = polarToCartesian(cx, cy, radius, entry.coordinate)
        const end = polarToCartesian(cx, cy, radius + (outer ? 1 : -1) * tickSize, entry.coordinate)
        const cos = Math.cos((-entry.coordinate * Math.PI) / 180)
        const sin = Math.sin((-entry.coordinate * Math.PI) / 180)
        const textAnchor: Anchor =
          cos > EPS ? (outer ? 'start' : 'end') : cos < -EPS ? (outer ? 'end' : 'start') : 'middle'
        const verticalAnchor: Anchor =
          Math.abs(cos) <= COS_45 ? (sin > 0 ? 'start' : 'end') : 'middle'
        const value = args.tickFormatter
          ? args.tickFormatter(entry.value as never, index)
          : entry.value
        return {
          line: (args.tickLine ?? true) ? { x1: start.x, y1: start.y, x2: end.x, y2: end.y } : null,
          text: asText(value),
          dy: TEXT_DY[verticalAnchor],
          args: {
            x: end.x,
            y: end.y,
            textAnchor,
            verticalAnchor,
            index,
            payload: entry,
            value,
            fill: args.stroke,
            stroke: 'none',
            cx,
            cy,
            radius,
          } satisfies PolarAngleAxisTickArgs,
        }
      }),
    }
  }

  get radiusAxis() {
    const part = this.radiusAxisPart
    const geometry = this.geometry
    if (!part || !geometry || part.args.hide || !geometry.radiusAxis.ticks.length) return null
    const args = part.args
    const { cx, cy } = geometry.viewBox
    const angle = args.angle ?? 0
    const ticks = geometry.radiusAxis.ticks
    const stroke = args.stroke ?? '#ccc'
    const orientation = args.orientation ?? 'right'
    const coordinates = ticks.map(entry => entry.coordinate)
    const start = polarToCartesian(cx, cy, Math.min(...coordinates), angle)
    const end = polarToCartesian(cx, cy, Math.max(...coordinates), angle)
    // The ring a Label sits in: recharts' radius axis view box.
    const radii = ticks.map(entry => entry.coordinate || 0)
    const viewBox: PolarViewBox = {
      cx,
      cy,
      startAngle: angle,
      endAngle: angle,
      innerRadius: Math.min(...radii),
      outerRadius: Math.max(...radii),
      clockWise: false,
    }
    return {
      class: args.class,
      stroke,
      textAnchor: orientation === 'left' ? 'end' : orientation === 'right' ? 'start' : 'middle',
      line: (args.axisLine ?? true) ? { x1: start.x, y1: start.y, x2: end.x, y2: end.y } : null,
      ticks:
        args.tick === false
          ? []
          : ticks.map((entry, index) => {
              const point = polarToCartesian(cx, cy, entry.coordinate, angle)
              const value = args.tickFormatter
                ? args.tickFormatter(entry.value as never, index)
                : entry.value
              return {
                x: point.x,
                y: point.y,
                transform: `rotate(${90 - angle}, ${point.x}, ${point.y})`,
                text: asText(value),
              }
            }),
      labels: part.labels.items.map(label => {
        const labelArgs = label.args
        const position: PolarPosition = labelArgs.position ?? 'middle'
        const offset = labelArgs.offset ?? 5
        const common = {
          viewBox,
          value: labelArgs.value,
          offset,
          position,
          content: labelArgs.content as ComponentLike<PolarLabelContentSignature> | undefined,
          text: asText(labelArgs.value),
          fill: labelArgs.fill ?? '#808080',
          fontSize: labelArgs.fontSize,
          class: labelArgs.class,
        }
        if (position === 'insideStart' || position === 'insideEnd' || position === 'end') {
          return {
            ...common,
            arc: {
              id: `${this.chartId}-axis-label-${++labelIds}`,
              d: radialLabelPath(viewBox, position, offset),
            },
          }
        }
        const attrs = polarLabelAttrs(viewBox, offset, position)
        return {
          ...common,
          arc: null,
          x: attrs.x,
          y: attrs.y,
          anchor: attrs.textAnchor,
          dy: attrs.dy,
        }
      }),
    }
  }

  dotsFor(
    option: RadarDotOption | undefined,
    fallback: boolean,
    base: Omit<DrawnDot['attrs'], 'class'>,
    className: string,
    points: { x: number; y: number; index: number; value: unknown; payload: unknown }[],
    dataKey: DotArgs['dataKey'],
  ): DrawnDot[] {
    const value = option ?? fallback
    if (value === false) return []
    return points.map(point => {
      const args: DotArgs = {
        cx: point.x,
        cy: point.y,
        r: base.r ?? 3,
        index: point.index,
        value: point.value,
        payload: point.payload as DotArgs['payload'],
        dataKey,
        stroke: base.stroke,
        strokeWidth: base.strokeWidth,
        fill: base.fill,
      }
      if (value === true) return { args, attrs: { ...base, class: className } }
      if (isPlainObject(value)) {
        const own = value as {
          r?: number
          fill?: string
          fillOpacity?: number | string
          stroke?: string
          strokeWidth?: number | string
          class?: string
        }
        const attrs = {
          r: own.r ?? base.r,
          fill: own.fill ?? base.fill,
          fillOpacity: own.fillOpacity ?? base.fillOpacity,
          stroke: own.stroke ?? base.stroke,
          strokeWidth: own.strokeWidth ?? base.strokeWidth,
          class: [className, own.class].filter(Boolean).join(' '),
        }
        return { args: { ...args, r: attrs.r ?? 3 }, attrs }
      }
      return {
        component: value as ComponentLike<{ Args: DotArgs; Element: Element }>,
        args,
        attrs: { ...base, class: className },
      }
    })
  }

  @cached
  get radars(): DrawnRadar[] {
    const geometry = this.geometry
    if (!geometry) return []
    return this.radarParts.flatMap((part, i) => {
      const args = part.args
      if (args.hide) return []
      const drawn = geometry.radars[i]!
      const points = drawn.points
      return [
        {
          key: keyOf(args.dataKey),
          class: args.class ?? '',
          points: points.map(point => `${round(point.x)},${round(point.y)}`).join(' '),
          d: drawn.isRange ? null : polygonPath(points, args.connectNulls ?? false),
          range: drawn.isRange
            ? {
                area: rangePolygonPath(points, drawn.baseLinePoints, args.connectNulls ?? false),
                outer:
                  args.stroke && args.stroke !== 'none'
                    ? polygonPath(points, args.connectNulls ?? false)
                    : null,
                inner:
                  args.stroke && args.stroke !== 'none'
                    ? polygonPath(drawn.baseLinePoints, args.connectNulls ?? false)
                    : null,
              }
            : null,
          fill: args.fill,
          fillOpacity: args.fillOpacity,
          stroke: args.stroke,
          strokeWidth: args.strokeWidth,
          dots: this.dotsFor(
            args.dot,
            false,
            {
              r: 3,
              fill: args.fill,
              fillOpacity: args.fillOpacity,
              stroke: args.stroke,
              strokeWidth: args.strokeWidth,
            },
            'recharts-dot recharts-radar-dot',
            points,
            args.dataKey,
          ),
        },
      ]
    })
  }

  sectorFill(part: RadialBar, sector: RadialBarSector): string | undefined {
    // recharts spreads the row over the sector, so a row's `fill` wins over the bar's.
    const own = (sector.payload as Record<string, unknown> | null)?.['fill']
    return typeof own === 'string' ? own : part.args.fill
  }

  @cached
  get radialBars(): DrawnRadialBar[] {
    const geometry = this.geometry
    if (!geometry) return []
    return this.radialBarParts.flatMap((part, i) => {
      const args = part.args
      if (args.hide) return []
      const drawn = geometry.radialBars[i]!
      const corners = {
        cornerRadius: args.cornerRadius ?? 0,
        forceCornerRadius: args.forceCornerRadius ?? false,
        cornerIsExternal: args.cornerIsExternal ?? false,
      }
      const background = args.background ?? false
      const backgroundOwn = isPlainObject(background) ? background : {}
      const key = keyOf(args.dataKey)
      return [
        {
          key,
          class: args.class ?? '',
          points: drawn.sectors
            .map(sector => {
              const point = polarToCartesian(
                sector.cx,
                sector.cy,
                (sector.innerRadius + sector.outerRadius) / 2,
                (sector.startAngle + sector.endAngle) / 2,
              )
              return `${round(point.x)},${round(point.y)}`
            })
            .join(' '),
          hasBackground: background !== false,
          background:
            background === false
              ? []
              : drawn.sectors
                  .filter(sector => sector.background)
                  .map(sector => ({
                    d: sectorPath({ ...sector.background!, ...corners }),
                    fill: backgroundOwn.fill ?? '#eee',
                    class: backgroundOwn.class ?? '',
                  })),
          sectors: drawn.sectors.map(sector => ({
            d: sectorPath({ ...sector, ...corners }),
            fill: this.sectorFill(part, sector),
            fillOpacity: args.fillOpacity,
            stroke: args.stroke,
            strokeWidth: args.strokeWidth,
            index: sector.index,
            value: Array.isArray(sector.value) ? sector.value.join(',') : asText(sector.value),
          })),
          labels: part.labels.items.map((label, j) => {
            const labelArgs = label.args
            const position = labelArgs.position ?? 'middle'
            const offset = labelArgs.offset ?? 5
            return {
              key: `label-${j}`,
              class: labelArgs.class ?? '',
              fontSize: labelArgs.fontSize,
              items: drawn.sectors.map(sector => {
                const raw =
                  labelArgs.dataKey !== undefined
                    ? valueOf(sector.payload, labelArgs.dataKey)
                    : Array.isArray(sector.value)
                      ? sector.value[sector.value.length - 1]
                      : sector.value
                const shown = labelArgs.formatter ? labelArgs.formatter(raw as never) : raw
                const item: DrawnLabelItem = {
                  text: asText(shown),
                  fill: labelArgs.fill ?? this.sectorFill(part, sector),
                }
                if (position === 'insideStart' || position === 'insideEnd' || position === 'end') {
                  item.arc = {
                    id: `${this.chartId}-radial-line-${++labelIds}`,
                    d: radialLabelPath(sector, position, offset),
                  }
                } else {
                  const attrs = polarLabelAttrs(sector, offset, position)
                  item.x = attrs.x
                  item.y = attrs.y
                  item.anchor = attrs.textAnchor
                  item.dy = attrs.dy
                }
                return item
              }),
            }
          }),
        },
      ]
    })
  }

  get labelLists(): (DrawnLabelList & { series: string })[] {
    return this.radialBars.flatMap(bar => bar.labels.map(list => ({ ...list, series: bar.key })))
  }

  // ---------------------------------------------------------------------------------------
  // Tooltip

  /** The pointer's radius and angle, while it is on the ring. */
  get pointerOnRing(): { radius: number; angle: number } | null {
    const viewBox = this.viewBox
    const pointer = this.pointer
    if (!viewBox || !pointer) return null
    return inRangeOfSector(pointer, viewBox)
  }

  get activeIndex(): number | null {
    const geometry = this.geometry
    const tooltip = this.tooltipPart
    if (!geometry || !tooltip || tooltip.args.active === false) return null
    if (this.pointer) {
      const ring = this.pointerOnRing
      if (!ring) return null
      const axis = geometry.tooltipAxis
      const index = activeTickIndex(
        this.layout === 'centric' ? ring.angle : ring.radius,
        geometry.tooltipTicks,
        axis.axisType,
        axis.range,
      )
      return index >= 0 ? index : null
    }
    if (this.keyboardActive && this.keyboardIndex !== null) return this.keyboardIndex
    if (typeof tooltip.args.defaultIndex === 'number' && this.keyboardIndex === null)
      return tooltip.args.defaultIndex
    if (tooltip.args.active === true) return this.keyboardIndex ?? 0
    return null
  }

  get activeTick(): PolarTick | undefined {
    const index = this.activeIndex
    if (index === null) return undefined
    return this.geometry?.tooltipTicks.find(tick => tick.index === index)
  }

  get isTooltipActive(): boolean {
    return this.activeTick !== undefined && this.activeIndex! < (this.args.data?.length ?? 0)
  }

  /**
   * Where the tooltip points: on the active row's spoke (a radar) or ring (a radial bar chart),
   * at the pointer. Without the pointer (the keyboard, `@defaultIndex`), at the first series'
   * point on that row, or the middle of its bar.
   */
  get activeCoordinate(): { x: number; y: number } | null {
    const geometry = this.geometry
    const tick = this.activeTick
    if (!geometry || !tick) return null
    const { cx, cy, outerRadius, startAngle } = geometry.viewBox
    const ring = this.pointerOnRing
    if (this.pointer && ring) {
      return this.layout === 'centric'
        ? polarToCartesian(cx, cy, ring.radius, tick.coordinate)
        : polarToCartesian(cx, cy, tick.coordinate, ring.angle)
    }
    const radar = geometry.radars.find((_, i) => !this.radarParts[i]?.args.hide)
    const point = radar?.points[tick.index]
    if (point) return { x: point.x, y: point.y }
    const bar = geometry.radialBars.find((_, i) => !this.radialBarParts[i]?.args.hide)
    const sector = bar?.sectors.find(entry => entry.index === tick.index)
    if (sector) {
      return polarToCartesian(
        sector.cx,
        sector.cy,
        (sector.innerRadius + sector.outerRadius) / 2,
        (sector.startAngle + sector.endAngle) / 2,
      )
    }
    return this.layout === 'centric'
      ? polarToCartesian(cx, cy, outerRadius, tick.coordinate)
      : polarToCartesian(cx, cy, tick.coordinate, startAngle)
  }

  /** What the tooltip's own arguments pass to its content; see CartesianChart's. */
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
    const tick = this.activeTick
    const tooltip = this.tooltipPart
    if (!tick || !tooltip) return []
    const row = this.args.data?.[tick.index] as Record<string, unknown> | undefined
    if (row === undefined) return []
    const filterNull = tooltip.args.filterNull ?? true
    const items: TooltipPayloadItem[] = []
    for (const part of this.seriesParts) {
      const args = part.args
      if (args.hide || args.tooltipType === 'none') continue
      const value = valueOf(row, args.dataKey)
      if (filterNull && (value === null || value === undefined)) continue
      items.push({
        name: args.name ?? keyOf(args.dataKey),
        value,
        dataKey: args.dataKey,
        // A radar's colour is its stroke, else its fill; a radial bar's, its fill.
        color: part instanceof Radar ? itemColor(args.stroke, args.fill) : args.fill,
        fill: args.fill,
        stroke: args.stroke,
        payload: row,
        type: args.tooltipType,
      })
    }
    // recharts sorts the entries by name.
    return items.sort((a, b) =>
      String(a.name) < String(b.name) ? -1 : String(a.name) > String(b.name) ? 1 : 0,
    )
  }

  get tooltipLabel(): unknown {
    return this.activeTick?.value
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
    const offset = tooltip.args.offset ?? 10
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

  /**
   * The cursor: a radar's spoke at the active row, or a radial bar chart's ring through the
   * active bar, as recharts draws them.
   */
  get cursor() {
    const tooltip = this.tooltipPart
    const geometry = this.geometry
    const tick = this.activeTick
    if (!tooltip || !geometry || !tick || !this.isTooltipActive || tooltip.args.cursor === false)
      return null
    const option = typeof tooltip.args.cursor === 'object' ? tooltip.args.cursor : {}
    const { cx, cy, innerRadius, outerRadius, startAngle, endAngle } = geometry.viewBox
    const stroke = option.stroke ?? '#ccc'
    if (this.layout === 'centric') {
      const inner = polarToCartesian(cx, cy, innerRadius, tick.coordinate)
      const outer = polarToCartesian(cx, cy, outerRadius, tick.coordinate)
      return {
        class: 'recharts-curve',
        d: `M${inner.x},${inner.y}L${outer.x},${outer.y}`,
        stroke,
        strokeWidth: option.strokeWidth ?? 1,
      }
    }
    return {
      class: 'recharts-sector',
      d: sectorPath({
        cx,
        cy,
        innerRadius: tick.coordinate,
        outerRadius: tick.coordinate,
        startAngle,
        endAngle,
      }),
      stroke,
      strokeWidth: option.strokeWidth ?? 1,
    }
  }

  get activeDots(): DrawnDot[] {
    const tick = this.activeTick
    const geometry = this.geometry
    if (!tick || !geometry || !this.isTooltipActive) return []
    return this.radarParts.flatMap((part, i) => {
      const args = part.args
      if (args.hide) return []
      const point = geometry.radars[i]!.points[tick.index]
      if (!point) return []
      const color = itemColor(args.stroke, args.fill) ?? 'none'
      return this.dotsFor(
        args.activeDot,
        true,
        { r: 4, fill: color, stroke: '#fff', strokeWidth: 2 },
        'recharts-dot',
        [point],
        args.dataKey,
      )
    })
  }

  // ---------------------------------------------------------------------------------------
  // Legend

  get legendPayload(): LegendPayloadItem[] {
    const items: LegendPayloadItem[] = []
    for (const part of this.seriesParts) {
      const args = part.args
      if (args.legendType === 'none') continue
      if (part instanceof RadialBar) {
        // A radial bar chart's legend names each row, as recharts' does.
        for (const row of (this.args.data ?? []) as Record<string, unknown>[]) {
          items.push({
            value: asText(row['name']),
            dataKey: args.dataKey,
            color: typeof row['fill'] === 'string' ? row['fill'] : args.fill,
            type: args.legendType ?? 'rect',
            payload: row,
          } as LegendPayloadItem)
        }
        continue
      }
      items.push({
        value: args.name ?? keyOf(args.dataKey),
        dataKey: args.dataKey,
        color: itemColor(args.stroke, args.fill),
        type: args.legendType ?? 'rect',
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

  // ---------------------------------------------------------------------------------------
  // Events

  onMouseMove = (event: MouseEvent): void => {
    if (!this.geometry) return
    const element = event.currentTarget as HTMLElement
    const rect = element.getBoundingClientRect()
    const scaleX = element.offsetWidth ? rect.width / element.offsetWidth : 1
    const scaleY = element.offsetHeight ? rect.height / element.offsetHeight : 1
    this.pointer = {
      x: (event.clientX - rect.left) / scaleX,
      y: (event.clientY - rect.top) / scaleY,
    }
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
    // ArrowRight moves to the next row and ArrowLeft to the previous one, as recharts 3 does
    // in a polar chart (its direction there is always left to right).
    const next = current + (key === 'ArrowRight' ? 1 : -1)
    const count = this.geometry?.tooltipTicks.length ?? 0
    if (next < 0 || next >= count) return
    this.pointer = null
    this.keyboardIndex = next
    this.keyboardActive = true
  }

  <template>
    {{#let
      (hash
        PolarGrid=(component PolarGrid chart=this)
        PolarAngleAxis=(component PolarAngleAxis chart=this)
        PolarRadiusAxis=(component PolarRadiusAxis chart=this)
        Radar=(component Radar chart=this)
        RadialBar=(component RadialBar chart=this)
        ChartTooltip=(component ChartTooltip chart=this)
        ChartLegend=(component ChartLegend chart=this)
      )
      as |parts|
    }}
      {{#if this.fixedSize}}
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
