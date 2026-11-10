/*
 * recharts' PieChart, as declarative Glimmer SVG. Like the cartesian charts, it measures its box,
 * collects the parts its block registers (its pies, tooltip and legend), lays them out with
 * ./polar.ts, and draws them in recharts' layers and with recharts' class names, so shadcn's
 * chart CSS styles them as it styles recharts.
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
import { Registry } from './registry.ts'
import { defaultAxis, plotArea, valueOf, type Box, type Margin } from './cartesian.ts'
import { legendStyleFor, observeSize, tooltipStyleFor } from './cartesian-chart.gts'
import { linePath } from './paths.ts'
import {
  PIE_DEFAULTS,
  drawnSectorAngles,
  inSector,
  percentOf,
  pieLabelPlacement,
  pieSectors,
  polarLabelPlacement,
  type PieSector,
  type PolarLabelPosition,
  type PolarViewBox,
} from './polar.ts'
import {
  ChartLegend,
  ChartTooltip,
  Pie,
  type ChartPart,
  type ChartRegistrar,
  type LabelContentSignature,
  type PieLabelProps,
  type PieLabelSignature,
  type PieShapeSignature,
  type SectorProps,
} from './parts.gts'
import Sector from '../components/sector.gts'
import ChartTooltipContent from '../components/chart-tooltip-content.gts'
import ChartLegendContent from '../components/chart-legend-content.gts'
import type {
  ChartConfig,
  ChartLegendContentArgs,
  ChartTooltipContentArgs,
  LegendPayloadItem,
  TooltipPayloadItem,
} from '../types.ts'

/** What a pie chart yields: its parts, each a component bound to the chart. */
export interface PieChartParts {
  /** A pie: recharts' `Pie`. */
  Pie: WithBoundArgs<typeof Pie, 'chart'>
  /** The tooltip: shadcn's `ChartTooltip`. */
  ChartTooltip: WithBoundArgs<typeof ChartTooltip, 'chart'>
  /** The legend: shadcn's `ChartLegend`. */
  ChartLegend: WithBoundArgs<typeof ChartLegend, 'chart'>
}

export interface PieChartSignature {
  Args: {
    /** The rows a pie draws when it has no `@data` of its own. */
    data?: readonly unknown[]
    /** The space around the pies. Default 5 on every side; given, a side left out is 0. */
    margin?: Margin
    /**
     * Keyboard access and a screen reader role: the chart takes focus, and the arrow keys move
     * the tooltip between sectors. Default true, as recharts 3's.
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
    /**
     * The chart's ring, which a pie's `Label` is placed against (recharts' polar options): its
     * centre, radii and angles. Default the chart's middle, 0 to `80%`, and 0° to 360°.
     */
    cx?: number | string
    cy?: number | string
    innerRadius?: number | string
    outerRadius?: number | string
    startAngle?: number
    endAngle?: number
    /** The config, from `ChartContainer` (or your own, for a chart outside one). */
    config?: ChartConfig
    /** Set by `ChartContainer`: the chart is inside one, which is what its harness finds. */
    inContainer?: boolean
    /** The chart's name, for its harness, outside a `ChartContainer`. */
    name?: string
  }
  Blocks: {
    /** The chart's parts. The block renders inside the chart's `<svg>`, so it can hold `<defs>`. */
    default: [PieChartParts]
  }
  Element: HTMLDivElement
}

/** A pie, laid out. */
interface PieGeometry {
  part: Pie
  key: string
  sectors: PieSector[]
}

interface DrawnPie {
  index: number
  part: Pie
  key: string
  /** Each sector's tooltip point, as `x,y` pairs, for its harness. */
  points: string
  /** Each sector's props, as its shape is handed them (without `isActive`). */
  sectors: SectorProps[]
  shape?: ComponentLike<PieShapeSignature>
  /** The labels past the sectors' edges (`@label`). */
  labels: DrawnPieLabel[]
  /** Its `LabelList`s. */
  labelLists: DrawnLabelList[]
  /** Its `Label`s that draw themselves (`@content`), inside the pie. */
  contents: {
    component: ComponentLike<LabelContentSignature>
    value: unknown
    offset: number
    position: PolarLabelPosition
  }[]
  /** Its `Label`s with a `@value`, drawn as text. */
  texts: DrawnText[]
}

interface DrawnPieLabel {
  props: PieLabelProps
  index: number
  component?: ComponentLike<PieLabelSignature>
  line?: { d: string; stroke: string; strokeWidth?: number | string }
  text: string
}

interface DrawnText {
  x: number
  y: number
  anchor: string
  dy: string
  text: string
  fill: string
  class: string
  fontSize?: number | string
}

interface DrawnLabelList {
  key: string
  class: string
  fillOpacity?: number | string
  stroke?: string
  fontSize?: number | string
  offset: number
  items: DrawnText[]
}

/** A sector the tooltip shows: the pie's index, and the sector's. */
interface ActiveItem {
  pie: number
  index: number
}

const INITIAL_DIMENSION = { width: -1, height: -1 }
const DEFAULT_MARGIN = { top: 5, right: 5, bottom: 5, left: 5 }

function num(value: number | undefined, fallback: number): number {
  return typeof value === 'number' && Number.isFinite(value) ? value : fallback
}

function keyOf(dataKey: unknown): string {
  return typeof dataKey === 'function' ? '' : String(dataKey ?? '')
}

function round(value: number): number {
  return Math.round(value * 1000) / 1000
}

function textOf(value: unknown): string {
  return value === null || value === undefined ? '' : String(value)
}

interface SurfaceSignature {
  Args: { chart: PieChart }
  Blocks: { default: [] }
  Element: HTMLDivElement
}

/**
 * The chart at its size: recharts' wrapper, its `<svg>` with the pies and their labels in
 * recharts' z-index layers, and the legend and tooltip boxes over it.
 */
const Surface: TOC<SurfaceSignature> = <template>
  <div
    class="recharts-wrapper"
    style={{@chart.wrapperStyle}}
    data-test-jn={{unless @chart.args.inContainer "chart"}}
    data-test-jn-name={{unless @chart.args.inContainer @chart.args.name}}
    data-test-jn-part="wrapper"
    data-layout="centric"
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
      {{! The block registers the chart's parts. Nothing above it may read them (see Registry). }}
      {{yield}}
      {{#if @chart.geometry}}
        <defs>
          <clipPath id={{@chart.clipId}}>
            <rect
              data-test-jn-part="plot"
              x={{@chart.geometry.offset.left}}
              y={{@chart.geometry.offset.top}}
              height={{@chart.geometry.offset.height}}
              width={{@chart.geometry.offset.width}}
            ></rect>
          </clipPath>
        </defs>
        <g class="recharts-zIndex-layer_100">
          {{#each @chart.pies as |pie|}}
            <g
              class="recharts-layer recharts-pie"
              data-test-jn-part="series"
              data-test-jn-value={{pie.key}}
              data-series-type="pie"
              data-test-jn-points={{pie.points}}
            >
              <g class="recharts-layer">
                {{#each pie.sectors key="index" as |sector|}}
                  <g class="recharts-layer recharts-pie-sector">
                    <g class={{@chart.sectorClass pie.index sector.index}}>
                      {{#if pie.shape}}
                        {{#let pie.shape as |Shape|}}
                          <Shape
                            @props={{@chart.sectorProps pie.index sector}}
                            @index={{sector.index}}
                          />
                        {{/let}}
                      {{else}}
                        <Sector @props={{@chart.sectorProps pie.index sector}} />
                      {{/if}}
                    </g>
                  </g>
                {{/each}}
              </g>
              {{#if @chart.polarViewBox}}
                {{#each pie.contents as |content|}}
                  {{#let content.component as |Content|}}
                    <Content
                      @viewBox={{@chart.polarViewBox}}
                      @value={{content.value}}
                      @offset={{content.offset}}
                      @position={{content.position}}
                    />
                  {{/let}}
                {{/each}}
              {{/if}}
            </g>
          {{/each}}
        </g>
        <g class="recharts-zIndex-layer_2000">
          {{#each @chart.pies as |pie|}}
            {{#if pie.labels.length}}
              <g
                class="recharts-layer recharts-pie-labels"
                data-test-jn-part="labels"
                data-test-jn-value={{pie.key}}
              >
                {{#each pie.labels as |label|}}
                  <g class="recharts-layer">
                    {{#if label.line}}
                      <path
                        class="recharts-curve recharts-pie-label-line"
                        fill="none"
                        stroke={{label.line.stroke}}
                        stroke-width={{label.line.strokeWidth}}
                        d={{label.line.d}}
                        data-test-jn-part="label-line"
                      ></path>
                    {{/if}}
                    {{#if label.component}}
                      {{#let label.component as |Label|}}
                        <Label @props={{label.props}} @index={{label.index}} />
                      {{/let}}
                    {{else}}
                      <text
                        class="recharts-text recharts-pie-label-text"
                        stroke="none"
                        alignment-baseline="middle"
                        x={{label.props.x}}
                        y={{label.props.y}}
                        text-anchor={{label.props.textAnchor}}
                        fill={{label.props.fill}}
                        data-test-jn-part="label"
                      ><tspan x={{label.props.x}} dy="0em">{{label.text}}</tspan></text>
                    {{/if}}
                  </g>
                {{/each}}
              </g>
            {{/if}}
            {{#each pie.labelLists as |list|}}
              <g
                class="recharts-layer recharts-label-list"
                data-test-jn-part="labels"
                data-test-jn-value={{pie.key}}
              >
                {{#each list.items as |item|}}
                  <text
                    class={{list.class}}
                    stroke={{list.stroke}}
                    font-size={{list.fontSize}}
                    fill-opacity={{list.fillOpacity}}
                    x={{item.x}}
                    y={{item.y}}
                    text-anchor={{item.anchor}}
                    fill={{item.fill}}
                    data-test-jn-part="label"
                  ><tspan x={{item.x}} dy={{item.dy}}>{{item.text}}</tspan></text>
                {{/each}}
              </g>
            {{/each}}
            {{#each pie.texts as |item|}}
              <text
                class={{item.class}}
                font-size={{item.fontSize}}
                x={{item.x}}
                y={{item.y}}
                text-anchor={{item.anchor}}
                fill={{item.fill}}
                data-test-jn-part="label"
              ><tspan x={{item.x}} dy={{item.dy}}>{{item.text}}</tspan></text>
            {{/each}}
          {{/each}}
        </g>
      {{/if}}
    </svg>
    {{#if @chart.legendPart}}
      <div class="recharts-legend-wrapper" style={{@chart.legendStyle}} {{@chart.measureLegend}}>
        {{#let @chart.legendContent as |Content|}}
          {{! The legend's @class goes to its content only when given (see the cartesian chart). }}
          {{#if @chart.legendPart.args.class}}
            <Content
              @payload={{@chart.legendPayload}}
              @verticalAlign={{@chart.legendVerticalAlign}}
              @config={{@chart.args.config}}
              @class={{@chart.legendPart.args.class}}
            />
          {{else}}
            <Content
              @payload={{@chart.legendPayload}}
              @verticalAlign={{@chart.legendVerticalAlign}}
              @config={{@chart.args.config}}
            />
          {{/if}}
        {{/let}}
      </div>
    {{/if}}
    {{#if @chart.tooltipPart}}
      <div
        class="recharts-tooltip-wrapper"
        tabindex="-1"
        style={{@chart.tooltipStyle}}
        {{@chart.measureTooltip @chart.isTooltipActive @chart.tooltipKey}}
      >
        {{#let @chart.tooltipContent as |Content|}}
          <Content
            @active={{@chart.isTooltipActive}}
            @payload={{@chart.tooltipPayload}}
            @config={{@chart.args.config}}
            @coordinate={{@chart.tooltipCoordinate}}
            @tooltip={{@chart.tooltipProps}}
          />
        {{/let}}
      </div>
    {{/if}}
  </div>
</template>

export default class PieChart extends Component<PieChartSignature> implements ChartRegistrar {
  readonly #parts = new Registry<ChartPart>()
  readonly chartId = idFor(this, 'chart')

  @tracked containerSize: { width: number; height: number } | null = null
  @tracked legendBox: { width: number; height: number } | null = null
  @tracked tooltipBox: { width: number; height: number } | null = null
  /** The sector under the pointer. */
  @tracked pointerItem: ActiveItem | null = null
  /** The sector the arrow keys are on, counting every pie's sectors in turn. */
  @tracked keyboardIndex: number | null = null
  @tracked keyboardActive = false

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
    const size = this.containerSize ?? this.args.initialDimension ?? INITIAL_DIMENSION
    if (!(size.width > 0) || !(size.height > 0)) return null
    return size
  }

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

  get viewBox(): string {
    return `0 0 ${this.width} ${this.height}`
  }

  get wrapperStyle(): SafeString {
    return htmlSafe(
      `position: relative; cursor: default; width: ${this.width}px; height: ${this.height}px;`,
    )
  }

  get clipId(): string {
    return `${this.chartId}-clip`
  }

  get accessibilityLayer(): boolean {
    return this.args.accessibilityLayer ?? true
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

  // ---------------------------------------------------------------------------------------
  // Parts

  get partList(): readonly ChartPart[] {
    return this.#parts.items
  }

  get pieParts(): Pie[] {
    return this.partList.filter((part): part is Pie => part instanceof Pie)
  }

  get tooltipPart(): ChartTooltip | undefined {
    return this.partList.find((part): part is ChartTooltip => part instanceof ChartTooltip)
  }

  get legendPart(): ChartLegend | undefined {
    return this.partList.find((part): part is ChartLegend => part instanceof ChartLegend)
  }

  /** A pie's rows: its own `@data`, or the chart's. */
  dataOf(pie: Pie): readonly unknown[] {
    return pie.args.data?.length ? pie.args.data : (this.args.data ?? [])
  }

  // ---------------------------------------------------------------------------------------
  // Layout

  @cached
  get geometry(): { offset: Box; pies: PieGeometry[] } | null {
    const size = this.size
    if (!size) return null
    const legend = this.legendPart
    const offset = plotArea({
      width: size.width,
      height: size.height,
      margin: this.margin,
      xAxis: defaultAxis('x', true),
      yAxis: defaultAxis('y', true),
      legend:
        legend && this.legendBox
          ? {
              ...this.legendBox,
              verticalAlign: legend.args.verticalAlign ?? 'bottom',
              align: legend.args.align ?? 'center',
              layout: legend.args.layout ?? 'horizontal',
            }
          : undefined,
    })
    const pies = this.pieParts
      .filter(part => !part.args.hide)
      .map(part => {
        const args = part.args
        const sectors =
          pieSectors(
            {
              dataKey: args.dataKey ?? PIE_DEFAULTS.dataKey,
              nameKey: args.nameKey ?? PIE_DEFAULTS.nameKey,
              name: args.name,
              cx: args.cx ?? PIE_DEFAULTS.cx,
              cy: args.cy ?? PIE_DEFAULTS.cy,
              innerRadius: args.innerRadius ?? PIE_DEFAULTS.innerRadius,
              outerRadius: args.outerRadius ?? PIE_DEFAULTS.outerRadius,
              startAngle: args.startAngle ?? PIE_DEFAULTS.startAngle,
              endAngle: args.endAngle ?? PIE_DEFAULTS.endAngle,
              paddingAngle: args.paddingAngle ?? PIE_DEFAULTS.paddingAngle,
              minAngle: args.minAngle ?? PIE_DEFAULTS.minAngle,
              cornerRadius: args.cornerRadius,
              fill: args.fill ?? PIE_DEFAULTS.fill,
            },
            this.dataOf(part),
            part.cells.items.map(cell => cell.attributes),
            offset,
          ) ?? []
        return { part, key: keyOf(args.dataKey ?? PIE_DEFAULTS.dataKey), sectors }
      })
    return { offset, pies }
  }

  /** recharts' polar view box: the chart's ring, which a pie's `Label` reads. */
  get polarViewBox(): PolarViewBox | null {
    const geometry = this.geometry
    if (!geometry) return null
    const { width, height } = this
    const maxRadius = Math.min(geometry.offset.width, geometry.offset.height) / 2
    return {
      cx: percentOf(this.args.cx ?? '50%', width, width / 2),
      cy: percentOf(this.args.cy ?? '50%', height, height / 2),
      innerRadius: percentOf(this.args.innerRadius ?? 0, maxRadius, 0),
      outerRadius: percentOf(this.args.outerRadius ?? '80%', maxRadius, maxRadius * 0.8),
      startAngle: this.args.startAngle ?? 0,
      endAngle: this.args.endAngle ?? 360,
      clockWise: false,
    }
  }

  // ---------------------------------------------------------------------------------------
  // Drawing

  @cached
  get pies(): DrawnPie[] {
    const geometry = this.geometry
    if (!geometry) return []
    return geometry.pies.map(({ part, key, sectors }, index): DrawnPie => {
      const args = part.args
      const dataKey = args.dataKey ?? PIE_DEFAULTS.dataKey
      const stroke = args.stroke ?? PIE_DEFAULTS.stroke
      const drawn = drawnSectorAngles(sectors)
      const props = sectors.map((sector, i): SectorProps => ({
        cx: sector.cx,
        cy: sector.cy,
        innerRadius: sector.innerRadius,
        outerRadius: sector.outerRadius,
        startAngle: drawn[i]!.startAngle,
        endAngle: drawn[i]!.endAngle,
        midAngle: sector.midAngle,
        cornerRadius: sector.cornerRadius,
        // The row's attributes (and its Cell's) win over the pie's, as recharts spreads them.
        fill: sector.fill,
        fillOpacity: (sector.payload['fillOpacity'] as string | undefined) ?? args.fillOpacity,
        stroke: (sector.payload['stroke'] as string | undefined) ?? stroke,
        strokeWidth: (sector.payload['strokeWidth'] as string | undefined) ?? args.strokeWidth,
        index: sector.index,
        value: sector.value,
        name: sector.name,
        percent: sector.percent,
        payload: sector.payload as SectorProps['payload'],
        dataKey,
        isActive: false,
      }))
      const label = args.label
      const labels: DrawnPieLabel[] = label
        ? sectors.map((sector, i) => {
            const placement = pieLabelPlacement(sector)
            const { isActive: _, ...sectorProps } = props[i]!
            return {
              index: i,
              component: label === true ? undefined : label,
              props: {
                ...sectorProps,
                stroke: 'none',
                x: placement.x,
                y: placement.y,
                textAnchor: placement.textAnchor,
              },
              line:
                args.labelLine === false
                  ? undefined
                  : {
                      d: linePath(placement.line, 'linear', 'horizontal') ?? '',
                      stroke: sector.fill,
                      strokeWidth: args.strokeWidth,
                    },
              text: textOf(valueOf({ ...sector.payload, value: sector.value }, dataKey)),
            }
          })
        : []
      const labelLists = part.labels.items.map((list, i): DrawnLabelList => {
        const listArgs = list.args
        const offset = num(listArgs.offset, 5)
        const position = (listArgs.position ?? 'middle') as PolarLabelPosition
        return {
          key: `label-${i}`,
          // recharts' Label is `recharts-label` unless given a class, which replaces it.
          class: `recharts-text ${listArgs.class ?? 'recharts-label'}`,
          fillOpacity: listArgs.fillOpacity,
          stroke: listArgs.stroke,
          fontSize: listArgs.fontSize,
          offset,
          items: sectors.map(sector => {
            const raw =
              listArgs.dataKey !== undefined
                ? valueOf(sector.payload, listArgs.dataKey)
                : sector.value
            const shown = listArgs.formatter ? listArgs.formatter(raw as never) : raw
            const placement = polarLabelPlacement(sector, offset, position)
            return {
              x: placement.x,
              y: placement.y,
              anchor: placement.textAnchor,
              dy: placement.dy,
              text: textOf(shown),
              fill: listArgs.fill ?? sector.fill,
              class: '',
            }
          }),
        }
      })
      const viewBox = this.polarViewBox
      const contents: DrawnPie['contents'] = []
      const texts: DrawnText[] = []
      for (const text of part.textLabels.items) {
        const textArgs = text.args
        const offset = num(textArgs.offset, 5)
        const position = textArgs.position ?? 'middle'
        if (textArgs.content) {
          contents.push({ component: textArgs.content, value: textArgs.value, offset, position })
        } else if (viewBox && textArgs.value !== undefined && textArgs.value !== null) {
          const placement = polarLabelPlacement(viewBox, offset, position)
          texts.push({
            x: placement.x,
            y: placement.y,
            anchor: placement.textAnchor,
            dy: placement.dy,
            text: textOf(textArgs.value),
            fill: textArgs.fill ?? '#808080',
            class: `recharts-text ${textArgs.class ?? 'recharts-label'}`,
            fontSize: textArgs.fontSize,
          })
        }
      }
      return {
        index,
        part,
        key,
        points: sectors
          .map(sector => `${round(sector.tooltipPosition.x)},${round(sector.tooltipPosition.y)}`)
          .join(' '),
        sectors: props,
        shape: args.shape,
        labels,
        labelLists,
        contents,
        texts,
      }
    })
  }

  /** A sector's props for its shape, with whether the tooltip shows it. */
  sectorProps = (pie: number, sector: SectorProps): SectorProps => {
    const active = this.activeItem
    const isActive = !!active && active.pie === pie && active.index === sector.index
    return isActive ? { ...sector, isActive } : sector
  }

  /** recharts wraps the sector the tooltip shows in `recharts-active-shape`. */
  sectorClass = (pie: number, index: number): string => {
    const active = this.activeItem
    return active && active.pie === pie && active.index === index
      ? 'recharts-layer recharts-active-shape'
      : 'recharts-layer recharts-shape'
  }

  // ---------------------------------------------------------------------------------------
  // Tooltip

  /** Every sector, pie by pie, in the order the arrow keys step through them. */
  get items(): ActiveItem[] {
    return this.pies.flatMap((pie, p) =>
      pie.sectors.map(sector => ({ pie: p, index: sector.index })),
    )
  }

  get activeItem(): ActiveItem | null {
    const tooltip = this.tooltipPart
    if (!tooltip || tooltip.args.active === false) return null
    if (this.pointerItem) return this.pointerItem
    const items = this.items
    if (this.keyboardActive && this.keyboardIndex !== null) return items[this.keyboardIndex] ?? null
    if (typeof tooltip.args.defaultIndex === 'number' && this.keyboardIndex === null) {
      return items.find(item => item.pie === 0 && item.index === tooltip.args.defaultIndex) ?? null
    }
    if (tooltip.args.active === true) return items[this.keyboardIndex ?? 0] ?? null
    return null
  }

  get activeSector(): { pie: DrawnPie; sector: SectorProps; geometry: PieSector } | null {
    const item = this.activeItem
    if (!item) return null
    const pie = this.pies[item.pie]
    const sector = pie?.sectors[item.index]
    const geometry = this.geometry?.pies[item.pie]?.sectors[item.index]
    return pie && sector && geometry ? { pie, sector, geometry } : null
  }

  get isTooltipActive(): boolean {
    const active = this.activeSector
    return !!active && active.pie.part.args.tooltipType !== 'none'
  }

  /** Which sector the tooltip shows, so its box is measured again when that changes. */
  get tooltipKey(): string {
    const item = this.activeItem
    return item ? `${item.pie}:${item.index}` : ''
  }

  get tooltipPayload(): TooltipPayloadItem[] {
    const active = this.activeSector
    if (!active || !this.isTooltipActive) return []
    const { pie, sector } = active
    const args = pie.part.args
    return [
      {
        name: sector.name as string | number,
        value: sector.value,
        dataKey: args.dataKey ?? PIE_DEFAULTS.dataKey,
        color: sector.fill,
        fill: sector.fill,
        payload: sector.payload,
        type: args.tooltipType,
      },
    ]
  }

  get tooltipCoordinate(): { x: number; y: number } | undefined {
    return this.activeSector?.geometry.tooltipPosition
  }

  get tooltipProps(): ChartTooltipContentArgs['tooltip'] {
    const args = this.tooltipPart?.args
    return {
      labelClassName: args?.labelClassName,
      labelFormatter: args?.labelFormatter,
      formatter: args?.formatter,
    }
  }

  get tooltipContent(): ComponentLike<{ Args: ChartTooltipContentArgs }> {
    return (
      this.tooltipPart?.args.content ??
      (ChartTooltipContent as unknown as ComponentLike<{ Args: ChartTooltipContentArgs }>)
    )
  }

  get tooltipStyle(): SafeString {
    const box = this.tooltipBox
    return tooltipStyleFor({
      visible:
        this.isTooltipActive &&
        this.tooltipPayload.length > 0 &&
        !!box &&
        box.width > 0 &&
        box.height > 0,
      coordinate: this.tooltipCoordinate,
      box,
      plot: this.geometry?.offset,
      tooltip: this.tooltipPart,
    })
  }

  /** Measures the tooltip's box each time what it shows changes. */
  measureTooltip = modifier((element: HTMLElement, positional: [boolean, string]) => {
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

  // ---------------------------------------------------------------------------------------
  // Legend

  /** A legend entry for each pie's rows, as recharts' `selectPieLegend` makes them. */
  get legendPayload(): LegendPayloadItem[] {
    const items: LegendPayloadItem[] = []
    for (const part of this.pieParts) {
      const args = part.args
      const legendType = args.legendType ?? 'rect'
      const dataKey = args.dataKey ?? PIE_DEFAULTS.dataKey
      const cells = part.cells.items
      this.dataOf(part).forEach((datum, i) => {
        const row = (datum ?? {}) as Record<string, unknown>
        const name = valueOf(row, args.nameKey ?? PIE_DEFAULTS.nameKey) ?? args.name
        const cellFill = cells[i]?.args.fill
        const color =
          cellFill ??
          (typeof row['fill'] === 'string' ? row['fill'] : (args.fill ?? PIE_DEFAULTS.fill))
        items.push({
          value: name ? String(name) : typeof dataKey === 'string' ? dataKey : '',
          color,
          payload: row,
          type: legendType,
          inactive: args.hide ?? false,
        })
      })
    }
    // recharts sorts the legend by value (a stable sort).
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
    return legendStyleFor(this.size!, this.margin, this.legendPart!, this.legendBox)
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

  /** The sector under a point, the last-drawn pie's first, as the pointer finds the top one. */
  itemAt(point: { x: number; y: number }): ActiveItem | null {
    const pies = this.geometry?.pies ?? []
    for (let p = pies.length - 1; p >= 0; p--) {
      const sector = pies[p]!.sectors.find(entry => inSector(point, entry))
      if (sector) return { pie: p, index: sector.index }
    }
    return null
  }

  onMouseMove = (event: MouseEvent): void => {
    if (!this.geometry) return
    const element = event.currentTarget as HTMLElement
    const rect = element.getBoundingClientRect()
    const scaleX = element.offsetWidth ? rect.width / element.offsetWidth : 1
    const scaleY = element.offsetHeight ? rect.height / element.offsetHeight : 1
    const item = this.itemAt({
      x: (event.clientX - rect.left) / scaleX,
      y: (event.clientY - rect.top) / scaleY,
    })
    const current = this.pointerItem
    if (item?.pie !== current?.pie || item?.index !== current?.index) this.pointerItem = item
  }

  onMouseLeave = (): void => {
    this.pointerItem = null
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

  /**
   * The arrow keys step through the sectors (every pie's, in turn), and Enter hides or shows the
   * tooltip. recharts 3's keyboard steps through a cartesian chart's rows; on a pie chart it
   * marks a sector active but shows no tooltip, so Joinery's goes further.
   */
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
    const next = current + (key === 'ArrowRight' ? 1 : -1)
    if (next < 0 || next >= this.items.length) return
    this.pointerItem = null
    this.keyboardIndex = next
    this.keyboardActive = true
  }

  <template>
    {{#let
      (hash
        Pie=(component Pie chart=this)
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
