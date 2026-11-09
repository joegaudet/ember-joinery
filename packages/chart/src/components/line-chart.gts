import CartesianChart from '../-private/cartesian-chart.gts'
import type { ChartName } from '../-private/cartesian.ts'

/**
 * recharts' `LineChart`, as Glimmer SVG. It yields its parts (axes, grid, series, tooltip and
 * legend); inside a `ChartContainer`, take it from the container's yield (`chart.LineChart`), which
 * gives it the container's config and size.
 *
 *   <chart.LineChart @data={{chartData}} as |c|>
 *     <c.CartesianGrid @vertical={{false}} />
 *     <c.XAxis @dataKey="month" />
 *   </chart.LineChart>
 */
export default class LineChart extends CartesianChart {
  override get chartName(): ChartName {
    return 'LineChart'
  }
}
