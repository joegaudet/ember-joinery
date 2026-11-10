import PolarChart from '../-private/polar-chart.gts'
import type { PolarChartName } from '../-private/polar-geometry.ts'

export type {
  PolarLabelListSignature,
  RadialBarBackground,
  RadialBarParts,
  RadialBarSignature,
} from '../-private/polar-parts.gts'

/**
 * recharts' `RadialBarChart`, as Glimmer SVG: a bar round the chart for each row, its rows out
 * from the centre. It yields its parts (grid, axes, series, tooltip and legend); inside a
 * `ChartContainer`, take it from the container's yield (`chart.RadialBarChart`), which gives it
 * the container's config and size.
 *
 *   <chart.RadialBarChart @data={{chartData}} @innerRadius={{30}} @outerRadius={{110}} as |c|>
 *     <c.RadialBar @dataKey="visitors" @background={{true}} />
 *   </chart.RadialBarChart>
 */
export default class RadialBarChart extends PolarChart {
  override get chartName(): PolarChartName {
    return 'RadialBarChart'
  }
}
