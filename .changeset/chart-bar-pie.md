---
'@ember-joinery/chart': minor
---

`ChartContainer` yields `PieChart`, recharts' pie chart: its `Pie` draws recharts 3's sectors,
with a label and a line past each one (`@label`, `true` or a component), an inner radius for a
donut, and a `@shape` that draws each sector with `Sector`; it yields `LabelList`, `Label` (a
`@content` component handed the chart's ring, for a donut's total) and `Cell`. Its tooltip shows
the sector under the pointer, and with the accessibility layer the arrow keys step through the
sectors. A bar takes the `fill` in its row and its `Cell`'s, its labels take that fill, its
`@shape` draws each bar with `Rectangle`, and a bar with no length is left out, as recharts'
are. A `ChartLegend`'s `@class` reaches its content. `ChartHarness` reads a pie's sectors, label
lists and label lines, and points at a sector. The guide's Charts section has the bar and pie
charts of shadcn's charts gallery.
