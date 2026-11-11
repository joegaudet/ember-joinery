# Pie Charts

The pie charts of shadcn's [charts gallery](https://ui.shadcn.com/charts/pie), from
`apps/v4/registry/new-york-v4/charts` at shadcn-ui/ui@8ab2771. Each is a `PieChart` from
`@ember-joinery/chart` in a [Card](/components/card.md); see [Chart](/components/chart.md#piechart)
for its parts.

## Pie Chart

<Example @name="chart-pie-simple" @title="Pie Chart" />

## Pie Chart - Separator None

<Example @name="chart-pie-separator-none" @title="Pie Chart - Separator None" />

## Pie Chart - Label

<Example @name="chart-pie-label" @title="Pie Chart - Label" />

## Pie Chart - Custom Label

The pie's `@label` is a component that draws each label, handed `@props` (where the label goes,
and its sector, its row in `payload`) and `@index`, as upstream's `label` function is.

<Example @name="chart-pie-label-custom" @title="Pie Chart - Custom Label" />

## Pie Chart - Label List

<Example @name="chart-pie-label-list" @title="Pie Chart - Label List" />

## Pie Chart - Legend

Upstream's gallery gives the card its width; here the preview stretches it across, as the
card, which has no footer, would otherwise shrink to its title.

<Example @name="chart-pie-legend" @title="Pie Chart - Legend" @fullWidth={{true}} />

## Pie Chart - Donut

<Example @name="chart-pie-donut" @title="Pie Chart - Donut" />

## Pie Chart - Donut Active

The pie's `@shape` is a component that draws each sector with `Sector`, handed the sector's
`@props` and `@index`, as upstream's `shape` function is.

<Example @name="chart-pie-donut-active" @title="Pie Chart - Donut Active" />

## Pie Chart - Donut with Text

A `Label`'s `@content` is a component handed the chart's ring as `@viewBox`, its centre at `cx`
and `cy`; it draws inside the pie, after its sectors.

<Example @name="chart-pie-donut-text" @title="Pie Chart - Donut with Text" />

## Pie Chart - Stacked

<Example @name="chart-pie-stacked" @title="Pie Chart - Stacked" />

## Pie Chart - Interactive

A [Select](/components/select.md) in the card's header picks the month. The pie's `@shape` draws
the chosen month's sector 10px further out with a ring past it, curried with the active index
(`(component PieShape activeIndex=this.activeIndex)`), as upstream's `shape` callback closes over
it, and the `Label`'s `@value` hands its `@content` that month's visitors. As with the legend
example, the preview stretches the card across, which upstream's gallery cell does.

<Example @name="chart-pie-interactive" @title="Pie Chart - Interactive" @fullWidth={{true}} />

## Testing

Each example's Test tab drives it with `ChartHarness` from `@ember-joinery/chart/test-support`
(see [Chart](/components/chart.md#testing)): `sectors(key)` and `sectorNames(key)` read a pie,
`hover(index, key)` points at a sector, and the arrow keys step through the sectors.
