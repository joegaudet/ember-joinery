import type { TOC } from '@ember/component/template-only'
import { Card, Icon } from '@ember-joinery/ember'
import {
  ChartContainer,
  ChartTooltipContent,
  type ChartConfig,
  type PolarLabelContentSignature,
} from '@ember-joinery/chart'
import { TrendingUp } from 'lucide'

const chartData = [{ month: 'january', mobile: 570, desktop: 1260 }]

const chartConfig = {
  desktop: {
    label: 'Desktop',
    color: 'var(--chart-1)',
  },
  mobile: {
    label: 'Mobile',
    color: 'var(--chart-2)',
  },
} satisfies ChartConfig

const totalVisitors = (chartData[0]!.desktop + chartData[0]!.mobile).toLocaleString()
const below = (cy: number, by: number) => (cy || 0) + by

// Upstream's Label `content` function: the total, and "Visitors" under it, in the middle of the
// chart, at the centre of the ring it is handed.
const Total: TOC<PolarLabelContentSignature> = <template>
  <text x={{@viewBox.cx}} y={{@viewBox.cy}} text-anchor="middle"><tspan
      x={{@viewBox.cx}}
      y={{below @viewBox.cy -16}}
      class="fill-foreground text-2xl font-bold"
    >{{totalVisitors}}</tspan><tspan
      x={{@viewBox.cx}}
      y={{below @viewBox.cy 4}}
      class="fill-muted-foreground"
    >Visitors</tspan></text>
</template>

<template>
  <Card class="flex flex-col" as |card|>
    <card.Header class="items-center pb-0">
      <card.Title>Radial Chart - Stacked</card.Title>
      <card.Description>January - June 2024</card.Description>
    </card.Header>
    <card.Content class="flex flex-1 items-center pb-0">
      <ChartContainer
        @config={{chartConfig}}
        class="mx-auto aspect-square w-full max-w-[250px]"
        as |chart|
      >
        <chart.RadialBarChart
          @data={{chartData}}
          @endAngle={{180}}
          @innerRadius={{80}}
          @outerRadius={{110}}
          as |c|
        >
          <c.RadialBar
            @dataKey="mobile"
            @fill="var(--color-mobile)"
            @stackId="a"
            @cornerRadius={{5}}
            @class="stroke-transparent stroke-2"
          />
          <c.RadialBar
            @dataKey="desktop"
            @stackId="a"
            @cornerRadius={{5}}
            @fill="var(--color-desktop)"
            @class="stroke-transparent stroke-2"
          />
          <c.ChartTooltip
            @cursor={{false}}
            @content={{component ChartTooltipContent hideLabel=true}}
          />
          <c.PolarRadiusAxis @tick={{false}} @tickLine={{false}} @axisLine={{false}} as |axis|>
            <axis.Label @content={{Total}} />
          </c.PolarRadiusAxis>
        </chart.RadialBarChart>
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
