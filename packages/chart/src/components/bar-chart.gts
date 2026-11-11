import CartesianChart from '../-private/cartesian-chart.gts'
import type { ChartName } from '../-private/cartesian.ts'

/**
 * recharts' `BarChart`, as Glimmer SVG. It yields its parts (axes, grid, series, tooltip and
 * legend); inside a `ChartContainer`, take it from the container's yield (`chart.BarChart`), which
 * gives it the container's config and size.
 *
 *   <chart.BarChart @data={{chartData}} as |c|>
 *     <c.CartesianGrid @vertical={{false}} />
 *     <c.XAxis @dataKey="month" />
 *   </chart.BarChart>
 */
export default class BarChart extends CartesianChart {
  override get chartName(): ChartName {
    return 'BarChart'
  }
}
