# @ember-joinery/chart

## 1.0.1

### Patch Changes

- Updated dependencies [2b887bf]
- Updated dependencies [2b887bf]
- Updated dependencies [2b887bf]
- Updated dependencies [2b887bf]
- Updated dependencies [2b887bf]
- Updated dependencies [2b887bf]
- Updated dependencies [2b887bf]
- Updated dependencies [2b887bf]
  - @ember-joinery/primitives@1.0.1
  - @ember-joinery/ember@1.0.1
  - @ember-joinery/test-support@1.0.1

## 1.0.0

### Major Changes

- a73065d: `@ember-joinery/chart` is a new add-on: shadcn's charts, drawn as declarative Glimmer SVG on
  `d3-scale` and `d3-shape` with an API shaped like recharts. `ChartContainer` takes the chart's
  `@config` (labels, icons and colours, set as `--color-<key>` variables, light and dark) and the
  `@initialDimension` it draws at before it is measured, and yields `AreaChart`, `BarChart` and `LineChart`, which yield recharts' parts: `XAxis`, `YAxis`,
  `CartesianGrid`, `Area`, `Bar` and `Line` (each with `LabelList`), `ChartTooltip` and
  `ChartLegend`. The geometry is recharts 3's (margins, nice ticks, overlapping labels dropped,
  stacking, bar bands, curves), so a chart draws the paths recharts draws, with recharts' class
  names. `ChartTooltipContent` and `ChartLegendContent` are shadcn's; the tooltip follows the
  pointer and, with the accessibility layer, the arrow keys, and its `@formatter` is a function
  that returns an entry's text or a component that draws the entry (recharts' formatter can
  return markup). `Dot` and `ChartStyle` go with them. Its `/test-support` has `ChartHarness`,
  `ChartTooltipHarness` and `ChartLegendHarness`. `@ember-joinery/ember`'s CSS styles the chart,
  its tooltip and its legend. The built modules that hold code ported from recharts keep
  recharts' MIT notice.

### Minor Changes

- a73065d: `ChartContainer` yields `PieChart`, recharts' pie chart: its `Pie` draws recharts 3's sectors,
  with a label and a line past each one (`@label`, `true` or a component), an inner radius for a
  donut, and a `@shape` that draws each sector with `Sector`; it yields `LabelList`, `Label` (a
  `@content` component handed the chart's ring, for a donut's total) and `Cell`. Its tooltip shows
  the sector under the pointer, and with the accessibility layer the arrow keys step through the
  sectors. A bar takes the `fill` in its row and its `Cell`'s, its labels take that fill, its
  `@shape` draws each bar with `Rectangle`, and a bar with no length is left out, as recharts'
  are. A `ChartLegend`'s `@class` reaches its content. `ChartHarness` reads a pie's sectors, label
  lists and label lines, and points at a sector. The guide's Charts section has the bar and pie
  charts of shadcn's charts gallery.
- a73065d: `ChartContainer` yields `RadarChart` and `RadialBarChart`, recharts 3's polar charts, with
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

### Patch Changes

- a53c07b: Type checks in package source use `@sindresorhus/is` (`isString`, `isFunction`, …) instead of `typeof`, and a lint rule keeps it that way. `@sindresorhus/is` is a new runtime dependency, so `ember-joinery add` now installs it into the app for most components, `icon` included. `isNumber` rejects `NaN`, so a `NaN` reaching a numeric check now takes the non-number branch.
- a73065d: Every package's tarball carries Joinery's `LICENSE.md` and `NOTICE`, with the licences and
  notices of what it ports (shadcn/ui, ember-primitives, sonner, recharts and the rest), copied in
  from the repository's root by the package's `prepack`.
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [17c5b5c]
- Updated dependencies [17c5b5c]
- Updated dependencies [99eab0c]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
  - @ember-joinery/primitives@1.0.0
  - @ember-joinery/ember@1.0.0
  - @ember-joinery/test-support@1.0.0
