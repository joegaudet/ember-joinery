import { Card, Icon } from '@ember-joinery/ember'
import { ChartContainer, ChartTooltipContent, type ChartConfig } from '@ember-joinery/chart'
import { TrendingUp } from 'lucide'

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
      <card.Title>Pie Chart - Label</card.Title>
      <card.Description>January - June 2024</card.Description>
    </card.Header>
    <card.Content class="flex-1 pb-0">
      <ChartContainer
        @config={{chartConfig}}
        class="mx-auto aspect-square max-h-[250px] pb-0 [&_.recharts-pie-label-text]:fill-foreground"
        as |chart|
      >
        <chart.PieChart as |c|>
          <c.ChartTooltip @content={{component ChartTooltipContent hideLabel=true}} />
          <c.Pie @data={{chartData}} @dataKey="visitors" @label={{true}} @nameKey="browser" />
        </chart.PieChart>
      </ChartContainer>
    </card.Content>
    <card.Footer class="flex-col gap-2 text-sm">
      <div class="flex items-center gap-2 leading-none font-medium">
        Trending up by 5.2% this month
        <Icon @icon={{TrendingUp}} class="h-4 w-4" />
      </div>
      <div class="leading-none text-muted-foreground">
        Showing total visitors for the last 6 months
      </div>
    </card.Footer>
  </Card>
</template>
