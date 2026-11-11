import type { TOC } from '@ember/component/template-only'
import { Card, Icon } from '@ember-joinery/ember'
import {
  ChartContainer,
  ChartTooltipContent,
  type ChartConfig,
  type LabelContentSignature,
} from '@ember-joinery/chart'
import { TrendingUp } from 'lucide'

const chartData = [
  { browser: 'chrome', visitors: 275, fill: 'var(--color-chrome)' },
  { browser: 'safari', visitors: 200, fill: 'var(--color-safari)' },
  { browser: 'firefox', visitors: 287, fill: 'var(--color-firefox)' },
  { browser: 'edge', visitors: 173, fill: 'var(--color-edge)' },
  { browser: 'other', visitors: 190, fill: 'var(--color-other)' },
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

const totalVisitors = chartData.reduce((acc, curr) => acc + curr.visitors, 0)
const localeString = (value: number) => value.toLocaleString()
const below = (cy = 0) => cy + 24

// The total in the donut's hole (upstream's Label `content` function).
const TotalVisitors: TOC<LabelContentSignature> = <template>
  <text x={{@viewBox.cx}} y={{@viewBox.cy}} text-anchor="middle" dominant-baseline="middle">
    <tspan
      x={{@viewBox.cx}}
      y={{@viewBox.cy}}
      class="fill-foreground text-3xl font-bold"
    >{{localeString totalVisitors}}</tspan>
    <tspan x={{@viewBox.cx}} y={{below @viewBox.cy}} class="fill-muted-foreground">Visitors</tspan>
  </text>
</template>

<template>
  <Card class="flex flex-col" as |card|>
    <card.Header class="items-center pb-0">
      <card.Title>Pie Chart - Donut with Text</card.Title>
      <card.Description>January - June 2024</card.Description>
    </card.Header>
    <card.Content class="flex-1 pb-0">
      <ChartContainer
        @config={{chartConfig}}
        class="mx-auto aspect-square max-h-[250px]"
        as |chart|
      >
        <chart.PieChart as |c|>
          <c.ChartTooltip
            @cursor={{false}}
            @content={{component ChartTooltipContent hideLabel=true}}
          />
          <c.Pie
            @data={{chartData}}
            @dataKey="visitors"
            @nameKey="browser"
            @innerRadius={{60}}
            @strokeWidth={{5}}
            as |pie|
          >
            <pie.Label @content={{TotalVisitors}} />
          </c.Pie>
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
