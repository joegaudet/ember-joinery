import type { TOC } from '@ember/component/template-only'
import { Card, Icon } from '@ember-joinery/ember'
import {
  ChartContainer,
  ChartTooltipContent,
  type ChartConfig,
  type PolarAngleAxisTickArgs,
} from '@ember-joinery/chart'
import { TrendingUp } from 'lucide'

const chartData = [
  { month: 'January', desktop: 186, mobile: 80 },
  { month: 'February', desktop: 305, mobile: 200 },
  { month: 'March', desktop: 237, mobile: 120 },
  { month: 'April', desktop: 73, mobile: 190 },
  { month: 'May', desktop: 209, mobile: 130 },
  { month: 'June', desktop: 214, mobile: 140 },
]

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

const margin = { top: 10, right: 10, bottom: 10, left: 10 }

const row = (index: number) => chartData[index]!
const tickY = (y: number, index: number) => y + (index === 0 ? -10 : 0)

// Upstream's `tick` render function: each month's two values over its name. Its tspans sit on
// one line here, as JSX joins them, since whitespace between them would draw as spaces.
const Tick: TOC<{ Args: PolarAngleAxisTickArgs; Element: SVGElement }> = <template>
  {{#let (row @index) as |data|}}
    <text
      x={{@x}}
      y={{tickY @y @index}}
      text-anchor={{@textAnchor}}
      font-size="13"
      font-weight="500"
      stroke={{@stroke}}
    ><tspan>{{data.desktop}}</tspan><tspan class="fill-muted-foreground">/</tspan><tspan
      >{{data.mobile}}</tspan><tspan
        x={{@x}}
        dy="1rem"
        font-size="12"
        class="fill-muted-foreground"
      >{{data.month}}</tspan></text>
  {{/let}}
</template>

<template>
  <Card as |card|>
    <card.Header class="items-center pb-4">
      <card.Title>Radar Chart - Custom Label</card.Title>
      <card.Description>
        Showing total visitors for the last 6 months
      </card.Description>
    </card.Header>
    <card.Content class="pb-0">
      <ChartContainer
        @config={{chartConfig}}
        class="mx-auto aspect-square max-h-[250px]"
        as |chart|
      >
        <chart.RadarChart @data={{chartData}} @margin={{margin}} as |c|>
          <c.ChartTooltip
            @cursor={{false}}
            @content={{component ChartTooltipContent indicator="line"}}
          />
          <c.PolarAngleAxis @dataKey="month" @tick={{Tick}} />

          <c.PolarGrid />
          <c.Radar @dataKey="desktop" @fill="var(--color-desktop)" @fillOpacity={{0.6}} />
          <c.Radar @dataKey="mobile" @fill="var(--color-mobile)" />
        </chart.RadarChart>
      </ChartContainer>
    </card.Content>
    <card.Footer class="flex-col gap-2 text-sm">
      <div class="flex items-center gap-2 leading-none font-medium">
        Trending up by 5.2% this month
        <Icon @icon={{TrendingUp}} class="h-4 w-4" />
      </div>
      <div class="flex items-center gap-2 leading-none text-muted-foreground">
        January - June 2024
      </div>
    </card.Footer>
  </Card>
</template>
