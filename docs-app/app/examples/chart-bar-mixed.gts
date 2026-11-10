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

const margin = { left: 0 }
const browserLabel = (value: string) => chartConfig[value as keyof typeof chartConfig]?.label

<template>
  <Card as |card|>
    <card.Header>
      <card.Title>Bar Chart - Mixed</card.Title>
      <card.Description>January - June 2024</card.Description>
    </card.Header>
    <card.Content>
      <ChartContainer @config={{chartConfig}} as |chart|>
        <chart.BarChart
          @accessibilityLayer={{true}}
          @data={{chartData}}
          @layout="vertical"
          @margin={{margin}}
          as |c|
        >
          <c.YAxis
            @dataKey="browser"
            @type="category"
            @tickLine={{false}}
            @tickMargin={{10}}
            @axisLine={{false}}
            @tickFormatter={{browserLabel}}
          />
          <c.XAxis @dataKey="visitors" @type="number" @hide={{true}} />
          <c.ChartTooltip
            @cursor={{false}}
            @content={{component ChartTooltipContent hideLabel=true}}
          />
          <c.Bar @dataKey="visitors" @radius={{5}} />
        </chart.BarChart>
      </ChartContainer>
    </card.Content>
    <card.Footer class="flex-col items-start gap-2 text-sm">
      <div class="flex gap-2 leading-none font-medium">
        Trending up by 5.2% this month
        <Icon @icon={{TrendingUp}} class="h-4 w-4" />
      </div>
      <div class="leading-none text-muted-foreground">
        Showing total visitors for the last 6 months
      </div>
    </card.Footer>
  </Card>
</template>
