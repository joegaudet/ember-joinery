import PolarChart from '../-private/polar-chart.gts'
import type { PolarChartName } from '../-private/polar-geometry.ts'

export type { PolarChartParts, PolarChartSignature } from '../-private/polar-chart.gts'
export type {
  PolarAngleAxisSignature,
  PolarAngleAxisTickArgs,
  PolarAxisArgs,
  PolarGridSignature,
  PolarLabelContentSignature,
  PolarRadiusAxisParts,
  PolarRadiusAxisSignature,
  PolarSeriesArgs,
  RadarDotOption,
  RadarSignature,
  RadiusAxisLabelSignature,
} from '../-private/polar-parts.gts'
export type { PolarPosition, PolarTick } from '../-private/polar-geometry.ts'

/**
 * recharts' `RadarChart`, as Glimmer SVG: a polygon per series, round the chart's categories
 * from 12 o'clock. It yields its parts (grid, axes, series, tooltip and legend); inside a
 * `ChartContainer`, take it from the container's yield (`chart.RadarChart`), which gives it the
 * container's config and size.
 *
 *   <chart.RadarChart @data={{chartData}} as |c|>
 *     <c.PolarAngleAxis @dataKey="month" />
 *     <c.PolarGrid />
 *     <c.Radar @dataKey="desktop" @fill="var(--color-desktop)" @fillOpacity={{0.6}} />
 *   </chart.RadarChart>
 */
export default class RadarChart extends PolarChart {
  override get chartName(): PolarChartName {
    return 'RadarChart'
  }
}
