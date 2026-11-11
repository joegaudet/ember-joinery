import type { TOC } from '@ember/component/template-only'
import { Card, Icon } from '@ember-joinery/ember'
import {
  ChartContainer,
  type ChartConfig,
  type PolarLabelContentSignature,
} from '@ember-joinery/chart'
import { TrendingUp } from 'lucide'

const chartData = [{ browser: 'safari', visitors: 1260, fill: 'var(--color-safari)' }]

const chartConfig = {
  visitors: {
    label: 'Visitors',
  },
  safari: {
    label: 'Safari',
    color: 'var(--chart-2)',
  },
} satisfies ChartConfig

const polarRadius = [86, 74]
const visitors = chartData[0]!.visitors.toLocaleString()
const below = (cy: number, by: number) => (cy || 0) + by

// Upstream's Label `content` function: the value and "Visitors" in the middle of the chart, at
// the centre of the ring it is handed.
const Center: TOC<PolarLabelContentSignature> = <template>
  <text x={{@viewBox.cx}} y={{@viewBox.cy}} text-anchor="middle" dominant-baseline="middle"><tspan
      x={{@viewBox.cx}}
      y={{@viewBox.cy}}
      class="fill-foreground text-4xl font-bold"
    >{{visitors}}</tspan><tspan
      x={{@viewBox.cx}}
      y={{below @viewBox.cy 24}}
      class="fill-muted-foreground"
    >Visitors</tspan></text>
</template>

<template>
  <Card class="flex flex-col" as |card|>
    <card.Header class="items-center pb-0">
      <card.Title>Radial Chart - Shape</card.Title>
      <card.Description>January - June 2024</card.Description>
    </card.Header>
    <card.Content class="flex-1 pb-0">
      <ChartContainer
        @config={{chartConfig}}
        class="mx-auto aspect-square max-h-[250px]"
        as |chart|
      >
        <chart.RadialBarChart
          @data={{chartData}}
          @endAngle={{100}}
          @innerRadius={{65}}
          @outerRadius={{95}}
          as |c|
        >
          <c.PolarGrid
            @gridType="circle"
            @radialLines={{false}}
            @stroke="none"
            @class="first:fill-muted last:fill-background"
            @polarRadius={{polarRadius}}
          />
          <c.RadialBar @dataKey="visitors" @background={{true}} />
          <c.PolarRadiusAxis @tick={{false}} @tickLine={{false}} @axisLine={{false}} as |axis|>
            <axis.Label @content={{Center}} />
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
