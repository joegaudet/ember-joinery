---
'@ember-joinery/chart': minor
---

`ChartContainer` yields `RadarChart` and `RadialBarChart`, recharts 3's polar charts, with
recharts' polar parts: `PolarGrid` (polygon or circle rings, spokes), `PolarAngleAxis` (whose
`@tick` takes a component), `PolarRadiusAxis` (yielding `Label`, whose `@content` component is
handed the chart's ring, for a total in the middle), `Radar` (with `@dot` and `@activeDot`, and
`[low, high]` pairs for a band) and `RadialBar` (with a `@background` track, `@cornerRadius`,
`@stackId`, a row's own `fill`, and `LabelList`, whose `insideStart` labels run along the bar).
They draw the paths recharts draws, with its class names; the tooltip follows the pointer round
the ring and, with the accessibility layer, the arrow keys from row to row. A bar chart's
tooltip opened by `@defaultIndex` or the keyboard now points at the row's tick half way down the
chart, as recharts' does, rather than at its bar, and a tooltip glides from row to row only
when the user doesn't prefer reduced motion (`@isAnimationActive`, `'auto'` by default, as
recharts'). `/test-support` adds `PolarChartHarness`. The guide's Charts section has the radar,
radial and tooltip charts of shadcn's charts gallery.
