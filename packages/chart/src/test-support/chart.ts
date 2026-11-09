import { blur, focus, settled, triggerEvent } from '@ember/test-helpers'
import { Harness, pressKey } from '@ember-joinery/test-support'

const collapse = (value: string | null | undefined): string =>
  (value ?? '').replace(/\s+/g, ' ').trim()

/** A point, in the chart's pixels (its `<svg>`'s coordinates). */
export interface ChartPoint {
  x: number
  y: number
}

/** A series as its harness reads it. */
export interface ChartSeriesInfo {
  /** Its data key. */
  key: string
  type: 'area' | 'bar' | 'line'
  /** Each drawn point (a bar's top-left corner), in the chart's pixels. */
  points: ChartPoint[]
  /** A line's or area's curve, as the path's `d`. */
  path: string | null
  /** An area's filled path. */
  areaPath: string | null
  fill: string | null
  stroke: string | null
  /** The series' group, to look inside. */
  element: SVGGElement
}

function parsePoints(value: string | null): ChartPoint[] {
  if (!value) return []
  return value
    .trim()
    .split(/\s+/)
    .map(pair => {
      const [x, y] = pair.split(',').map(Number)
      return { x: x!, y: y! }
    })
}

/**
 * Reads a chart tooltip's box (`ChartTooltipContent`): its label and each entry's name and
 * value. A chart's harness gives you the one it shows (`chart.tooltip`); this one also finds a
 * tooltip rendered on its own.
 */
export class ChartTooltipHarness extends Harness {
  static override component = 'chart-tooltip'

  /** `dot`, `line` or `dashed`. */
  get indicator(): string | null {
    return this.element.getAttribute('data-indicator')
  }

  /** The label's text, or `null` without one. */
  get label(): string | null {
    const label = this.queryPart('label')
    return label ? collapse(label.textContent) : null
  }

  /** Each entry: its key, the name it shows, its value's text, and its indicator. */
  get items(): { key: string; name: string; value: string | null; indicator: HTMLElement | null }[] {
    return this.parts('item').map(item => ({
      key: item.getAttribute('data-test-jn-value') ?? '',
      name: collapse(item.querySelector('[data-test-jn-part="name"]')?.textContent),
      value: item.querySelector('[data-test-jn-part="value"]')
        ? collapse(item.querySelector('[data-test-jn-part="value"]')!.textContent)
        : null,
      indicator: item.querySelector<HTMLElement>('[data-test-jn-part="indicator"]'),
    }))
  }

  /** The entries' names, in order. */
  get names(): string[] {
    return this.items.map(item => item.name)
  }

  /** The entries' values' text, in order. */
  get entryValues(): (string | null)[] {
    return this.items.map(item => item.value)
  }

  /** All the text it shows, whitespace collapsed. */
  get text(): string {
    return collapse(this.element.textContent)
  }
}

/** Reads a chart legend (`ChartLegendContent`): each entry's key and label. */
export class ChartLegendHarness extends Harness {
  static override component = 'chart-legend'

  /** Each entry: its key, its label, and its swatch (or `null` where it shows an icon). */
  get items(): { key: string; label: string; swatch: HTMLElement | null }[] {
    return this.parts('item').map(item => ({
      key: item.getAttribute('data-test-jn-value') ?? '',
      label: collapse(item.textContent),
      swatch: item.querySelector<HTMLElement>('[data-test-jn-part="swatch"]'),
    }))
  }

  /** The entries' labels, in order. */
  get labels(): string[] {
    return this.items.map(item => item.label)
  }
}

/**
 * Drives a chart from `@ember-joinery/chart` (`<ChartContainer>`, or a chart outside one): reads
 * its series, axes, grid, labels and legend, and moves the tooltip with the pointer or the
 * keyboard, as a user does.
 *
 *   const chart = new ChartHarness('visitors') // <ChartContainer @name="visitors">
 *   assert.deepEqual(chart.xTicks, ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'])
 *   await chart.hover(1)
 *   assert.strictEqual(chart.tooltip?.label, 'February')
 *   assert.deepEqual(chart.legend?.labels, ['Desktop', 'Mobile'])
 */
export class ChartHarness extends Harness {
  static override component = 'chart'

  /** recharts' wrapper: the chart at its size, holding the `<svg>`, legend and tooltip. */
  get wrapper(): HTMLElement {
    return this.part('wrapper')
  }

  /** The chart's `<svg>`. */
  get surface(): SVGSVGElement {
    return this.part<SVGSVGElement>('surface')
  }

  /** The size the chart drew at. */
  get width(): number {
    return Number(this.surface.getAttribute('width'))
  }

  get height(): number {
    return Number(this.surface.getAttribute('height'))
  }

  /** The plot area: the chart less its margins, axes and legend. */
  get plot(): { x: number; y: number; width: number; height: number } {
    const rect = this.surface.querySelector('clipPath rect')!
    const read = (name: string) => Number(rect.getAttribute(name))
    return { x: read('x'), y: read('y'), width: read('width'), height: read('height') }
  }

  /** The value of the chart's `--color-<key>` variable (from its config). */
  color(key: string): string {
    return getComputedStyle(this.element).getPropertyValue(`--color-${key}`).trim()
  }

  /** Every series, in the order the chart draws them (areas, then bars, then lines). */
  get series(): ChartSeriesInfo[] {
    return this.parts<SVGGElement>('series').map(element => {
      const type = element.getAttribute('data-series-type') as ChartSeriesInfo['type']
      const curve = element.querySelector('.recharts-area-curve, .recharts-line-curve')
      const area = element.querySelector('.recharts-area-area')
      const painted = area ?? curve ?? element.querySelector('.recharts-rectangle')
      return {
        key: element.getAttribute('data-test-jn-value') ?? '',
        type,
        points: parsePoints(element.getAttribute('data-test-jn-points')),
        path: curve?.getAttribute('d') ?? null,
        areaPath: area?.getAttribute('d') ?? null,
        fill: painted?.getAttribute('fill') ?? null,
        stroke: (curve ?? painted)?.getAttribute('stroke') ?? null,
        element,
      }
    })
  }

  /** The series drawn for `key`. Throws when there is none. */
  seriesFor(key: string): ChartSeriesInfo {
    const series = this.series.find(entry => entry.key === key)
    if (!series) throw new Error(`no series "${key}" in ${this}`)
    return series
  }

  /** A bar series' bars, as `<path>` elements. */
  bars(key: string): SVGPathElement[] {
    return Array.from(this.seriesFor(key).element.querySelectorAll<SVGPathElement>('[data-test-jn-part="bar"]'))
  }

  /** A series' dots (circles, or the custom dots it draws). */
  dots(key: string): Element[] {
    const group = this.surface.querySelector(`[data-test-jn-part="dots"][data-test-jn-value="${key}"]`)
    return group ? Array.from(group.children) : []
  }

  /** A series' labels' text (`LabelList`). */
  labels(key: string): string[] {
    const group = this.surface.querySelector(`[data-test-jn-part="labels"][data-test-jn-value="${key}"]`)
    return group ? Array.from(group.querySelectorAll('text')).map(text => collapse(text.textContent)) : []
  }

  #tickTexts(axis: 'xAxis' | 'yAxis'): string[] {
    const group = this.queryPart(`${axis}-labels`)
    return group ? Array.from(group.querySelectorAll('text')).map(text => collapse(text.textContent)) : []
  }

  /** The x-axis's tick labels, as drawn. Empty without a drawn x-axis. */
  get xTicks(): string[] {
    return this.#tickTexts('xAxis')
  }

  /** The y-axis's tick labels, as drawn. Empty without a drawn y-axis. */
  get yTicks(): string[] {
    return this.#tickTexts('yAxis')
  }

  /** The grid's lines: the y of each horizontal one and the x of each vertical one. */
  get gridLines(): { horizontal: number[]; vertical: number[] } {
    const lines = this.parts('grid-line')
    const of = (kind: string, attribute: string) =>
      lines
        .filter(line => line.getAttribute('data-test-jn-value') === kind)
        .map(line => Number(line.getAttribute(attribute)))
    return { horizontal: of('horizontal', 'y1'), vertical: of('vertical', 'x1') }
  }

  /** Where each row sits along the category axis, in the chart's pixels. */
  get categories(): number[] {
    const value = this.wrapper.getAttribute('data-test-jn-categories')
    return value ? value.split(' ').map(Number) : []
  }

  /** Moves the pointer over row `index` (its category), which shows the tooltip there. */
  async hover(index: number): Promise<void> {
    const coordinate = this.categories[index]
    if (coordinate === undefined) throw new Error(`${this} has no row ${index}`)
    const wrapper = this.wrapper
    const rect = wrapper.getBoundingClientRect()
    const scale = wrapper.offsetWidth ? rect.width / wrapper.offsetWidth : 1
    const plot = this.plot
    const vertical = wrapper.getAttribute('data-layout') === 'vertical'
    // Mouse events carry whole pixels: round to one, kept inside the plot area so a row on its
    // edge is still under the pointer.
    const client = (value: number, start: number, size: number, origin: number) => {
      const low = Math.ceil(origin + start * scale)
      const high = Math.floor(origin + (start + size) * scale)
      return Math.min(Math.max(Math.round(origin + value * scale), low), high)
    }
    const clientX = vertical
      ? client(plot.x + plot.width / 2, plot.x, plot.width, rect.left)
      : client(coordinate, plot.x, plot.width, rect.left)
    const clientY = vertical
      ? client(coordinate, plot.y, plot.height, rect.top)
      : client(plot.y + plot.height / 2, plot.y, plot.height, rect.top)
    await triggerEvent(wrapper, 'mousemove', { clientX, clientY })
    await settled()
  }

  /** Moves the pointer off the chart, which hides the tooltip. */
  async unhover(): Promise<void> {
    await triggerEvent(this.wrapper, 'mouseleave')
  }

  /** Focuses the chart, as Tab does: the tooltip shows the first row. */
  async focus(): Promise<void> {
    await focus(this.surface)
  }

  /** Takes focus away from the chart, which hides a keyboard tooltip. */
  async blur(): Promise<void> {
    await blur(this.surface)
  }

  /** Presses a key on the focused chart: `ArrowRight`/`ArrowLeft` move the tooltip, `Enter` toggles it. */
  async press(key: 'ArrowRight' | 'ArrowLeft' | 'Enter'): Promise<void> {
    await pressKey(key)
  }

  /** Whether the tooltip is showing. */
  get isTooltipVisible(): boolean {
    const wrapper = this.wrapper.querySelector<HTMLElement>('.recharts-tooltip-wrapper')
    return !!wrapper && wrapper.style.visibility === 'visible'
  }

  /** The tooltip box, while it shows; otherwise `null`. */
  get tooltip(): ChartTooltipHarness | null {
    if (!this.isTooltipVisible) return null
    const tooltip = this.find(ChartTooltipHarness)
    return tooltip.exists ? tooltip : null
  }

  /** The tooltip's position against the chart: the translate recharts gives it. */
  get tooltipPosition(): { x: number; y: number } | null {
    const wrapper = this.wrapper.querySelector<HTMLElement>('.recharts-tooltip-wrapper')
    const match = /translate\(([-\d.]+)px, ([-\d.]+)px\)/.exec(wrapper?.style.transform ?? '')
    return match ? { x: Number(match[1]), y: Number(match[2]) } : null
  }

  /** The tooltip's cursor: the line (or band) under the active row, or `null`. */
  get cursor(): SVGPathElement | null {
    return this.queryPart<SVGPathElement>('cursor')
  }

  /** The dots drawn at the active row while the tooltip shows. */
  get activeDots(): SVGCircleElement[] {
    return this.parts('active-dot').flatMap(group => Array.from(group.querySelectorAll('circle')))
  }

  /** The legend, or `null` without one. */
  get legend(): ChartLegendHarness | null {
    const legend = this.find(ChartLegendHarness)
    return legend.exists ? legend : null
  }
}
