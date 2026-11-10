import { triggerEvent } from '@ember/test-helpers'
import { ChartHarness, type ChartPoint } from './chart.ts'

const collapse = (value: string | null | undefined): string =>
  (value ?? '').replace(/\s+/g, ' ').trim()

/** A polar chart's ring: its centre, its radii, and the angles its angle axis runs between. */
export interface PolarRing {
  cx: number
  cy: number
  innerRadius: number
  outerRadius: number
  startAngle: number
  endAngle: number
}

/** A polar chart's grid, as its harness reads it. */
export interface PolarGridInfo {
  /** `polygon` or `circle`. */
  type: string
  /** Each ring's radius, innermost first as drawn. */
  radii: number[]
  /** Each spoke's angle, in degrees. Empty without spokes (`@radialLines={{false}}`). */
  angles: number[]
  /** The rings (`<path>`s or `<circle>`s) and the spokes (`<line>`s). */
  rings: SVGElement[]
  spokes: SVGLineElement[]
}

const RADIAN = Math.PI / 180

function point(cx: number, cy: number, radius: number, angle: number): ChartPoint {
  return { x: cx + Math.cos(-RADIAN * angle) * radius, y: cy + Math.sin(-RADIAN * angle) * radius }
}

/**
 * Drives a radar or radial bar chart from `@ember-joinery/chart` (`RadarChart`,
 * `RadialBarChart`): everything `ChartHarness` reads, plus the ring, the polar grid and axes,
 * each radar's polygon and each radial bar's sectors. `hover(index)` points at a row as recharts
 * finds it: on its spoke in a radar chart, on its ring in a radial bar chart.
 *
 *   const chart = new PolarChartHarness('visitors') // <ChartContainer @name="visitors">
 *   assert.deepEqual(chart.angleTicks, ['January', 'February', 'March', 'April', 'May', 'June'])
 *   await chart.hover(1)
 *   assert.strictEqual(chart.tooltip?.label, 'February')
 */
export class PolarChartHarness extends ChartHarness {
  /** `centric` (a radar chart, its rows round the ring) or `radial` (rows out from the centre). */
  get layout(): string {
    return this.wrapper.getAttribute('data-layout') ?? ''
  }

  /** The chart's ring. */
  get ring(): PolarRing {
    const value = this.queryPart('plot')?.getAttribute('data-test-jn-ring') ?? ''
    const [cx, cy, innerRadius, outerRadius, startAngle, endAngle] = value.split(' ').map(Number)
    return {
      cx: cx ?? 0,
      cy: cy ?? 0,
      innerRadius: innerRadius ?? 0,
      outerRadius: outerRadius ?? 0,
      startAngle: startAngle ?? 0,
      endAngle: endAngle ?? 0,
    }
  }

  /** The polar grid, or `null` without one. */
  get polarGrid(): PolarGridInfo | null {
    const grid = this.queryPart('polar-grid')
    if (!grid) return null
    const rings = Array.from(grid.querySelectorAll<SVGElement>('[data-test-jn-part="grid-ring"]'))
    const spokes = Array.from(
      grid.querySelectorAll<SVGLineElement>('[data-test-jn-part="grid-spoke"]'),
    )
    return {
      type: grid.getAttribute('data-grid-type') ?? '',
      radii: rings.map(ring => Number(ring.getAttribute('data-test-jn-value'))),
      angles: spokes.map(spoke => Number(spoke.getAttribute('data-test-jn-value'))),
      rings,
      spokes,
    }
  }

  #axisTexts(part: 'angle-axis' | 'radius-axis'): string[] {
    const tick = part === 'angle-axis' ? 'polar-angle-axis-tick' : 'polar-radius-axis-tick'
    const axis = this.queryPart(part)
    return axis
      ? Array.from(axis.querySelectorAll(`.recharts-${tick}`)).map(entry =>
          collapse(entry.querySelector('text')?.textContent),
        )
      : []
  }

  /** The angle axis's labels, as drawn (a custom `@tick`'s text included). */
  get angleTicks(): string[] {
    return this.#axisTexts('angle-axis')
  }

  /** The radius axis's labels, as drawn. */
  get radiusTicks(): string[] {
    return this.#axisTexts('radius-axis')
  }

  /** The angle axis's group, or `null` without one. */
  get angleAxis(): SVGGElement | null {
    return this.queryPart<SVGGElement>('angle-axis')
  }

  /** The radius axis's group, or `null` without one: its `Label`s draw inside it. */
  get radiusAxis(): SVGGElement | null {
    return this.queryPart<SVGGElement>('radius-axis')
  }

  /** A radar's polygon (the `<path>` it fills). Throws when there is no radar for `key`. */
  polygon(key: string): SVGPathElement {
    const series = this.seriesFor(key)
    const path = series.element.querySelector<SVGPathElement>('.recharts-radar-polygon path')
    if (!path) throw new Error(`the radar "${key}" in ${this} draws no polygon`)
    return path
  }

  /** A radial bar series' bars (sectors), in its rows' order. */
  radialBars(key: string): SVGPathElement[] {
    return Array.from(
      this.seriesFor(key).element.querySelectorAll<SVGPathElement>('[data-test-jn-part="sector"]'),
    )
  }

  /** The tracks behind the radial bars (`@background`), in their rows' order. */
  get backgroundSectors(): SVGPathElement[] {
    return this.parts<SVGPathElement>('background-sector')
  }

  /**
   * Moves the pointer over row `index`, which shows the tooltip there: halfway along the row's
   * spoke in a radar chart, halfway round its ring in a radial bar chart.
   */
  override async hover(index: number): Promise<void> {
    const coordinate = this.categories[index]
    if (coordinate === undefined) throw new Error(`${this} has no row ${index}`)
    const { cx, cy, innerRadius, outerRadius, startAngle, endAngle } = this.ring
    const target =
      this.layout === 'centric'
        ? point(cx, cy, (innerRadius + outerRadius) / 2, coordinate)
        : point(cx, cy, coordinate, (startAngle + endAngle) / 2)
    const wrapper = this.wrapper
    const rect = wrapper.getBoundingClientRect()
    const scale = wrapper.offsetWidth ? rect.width / wrapper.offsetWidth : 1
    await triggerEvent(wrapper, 'mousemove', {
      clientX: Math.round(rect.left + target.x * scale),
      clientY: Math.round(rect.top + target.y * scale),
    })
  }
}
