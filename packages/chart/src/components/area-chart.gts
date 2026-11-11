import CartesianChart from '../-private/cartesian-chart.gts'
import type { ChartName } from '../-private/cartesian.ts'

/**
 * recharts' `AreaChart`, as Glimmer SVG. It yields its parts (axes, grid, series, tooltip and
 * legend); inside a `ChartContainer`, take it from the container's yield (`chart.AreaChart`), which
 * gives it the container's config and size.
 *
 *   <chart.AreaChart @data={{chartData}} as |c|>
 *     <c.CartesianGrid @vertical={{false}} />
 *     <c.XAxis @dataKey="month" />
 *   </chart.AreaChart>
 */
export default class AreaChart extends CartesianChart {
  override get chartName(): ChartName {
    return 'AreaChart'
  }
}
