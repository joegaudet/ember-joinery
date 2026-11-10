import { Card } from '@ember-joinery/ember'
import { ChartContainer, ChartLegendContent, type ChartConfig } from '@ember-joinery/chart'

const chartData = [
  { browser: 'chrome', visitors: 275, fill: 'var(--color-chrome)' },
  { browser: 'safari', visitors: 200, fill: 'var(--color-safari)' },
  { browser: 'firefox', visitors: 187, fill: 'var(--color-firefox)' },
  { browser: 'edge', visitors: 173, fill: 'var(--color-edge)' },
  { browser: 'other', visitors: 90, fill: 'var(--color-other)' },
]

const chartConfig = {
  visitors: {
    label: 'Visitors',
  },
  chrome: {
    label: 'Chrome',
    color: 'var(--chart-1)',
  },
  safari: {
    label: 'Safari',
    color: 'var(--chart-2)',
  },
  firefox: {
    label: 'Firefox',
    color: 'var(--chart-3)',
  },
  edge: {
    label: 'Edge',
    color: 'var(--chart-4)',
  },
  other: {
    label: 'Other',
    color: 'var(--chart-5)',
  },
} satisfies ChartConfig

<template>
  <Card class="flex flex-col" as |card|>
    <card.Header class="items-center pb-0">
      <card.Title>Pie Chart - Legend</card.Title>
      <card.Description>January - June 2024</card.Description>
    </card.Header>
    <card.Content class="flex-1 pb-0">
      <ChartContainer
        @config={{chartConfig}}
        class="mx-auto aspect-square max-h-[300px]"
        as |chart|
      >
        <chart.PieChart as |c|>
          <c.Pie @data={{chartData}} @dataKey="visitors" />
          <c.ChartLegend
            @content={{component ChartLegendContent nameKey="browser"}}
            @class="-translate-y-2 flex-wrap gap-2 *:basis-1/4 *:justify-center"
          />
        </chart.PieChart>
      </ChartContainer>
    </card.Content>
  </Card>
</template>
