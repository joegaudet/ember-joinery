import PieChart from '../-private/pie-chart.gts'

/**
 * recharts' `PieChart`, as Glimmer SVG. It yields its parts (pies, tooltip and legend); inside a
 * `ChartContainer`, take it from the container's yield (`chart.PieChart`), which gives it the
 * container's config and size.
 *
 *   <chart.PieChart as |c|>
 *     <c.ChartTooltip @content={{component ChartTooltipContent hideLabel=true}} />
 *     <c.Pie @data={{chartData}} @dataKey="visitors" @nameKey="browser" />
 *   </chart.PieChart>
 */
export default PieChart
