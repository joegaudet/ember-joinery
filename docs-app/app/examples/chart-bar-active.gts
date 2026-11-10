import type { TOC } from '@ember/component/template-only'
import { Card, Icon } from '@ember-joinery/ember'
import {
  ChartContainer,
  ChartTooltipContent,
  Rectangle,
  type BarShapeSignature,
  type ChartConfig,
} from '@ember-joinery/chart'
import { TrendingUp } from 'lucide'

const chartData = [
  { browser: 'chrome', visitors: 187, fill: 'var(--color-chrome)' },
  { browser: 'safari', visitors: 200, fill: 'var(--color-safari)' },
  { browser: 'firefox', visitors: 275, fill: 'var(--color-firefox)' },
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

const ACTIVE_INDEX = 2

const browserLabel = (value: string) => chartConfig[value as keyof typeof chartConfig]?.label
const isActive = (index: number) => index === ACTIVE_INDEX

// Each bar, the active one dashed (upstream's `shape` function). Glimmer has no spread, so the
// bar's props go to Rectangle as `@props`, as upstream spreads `{...props}` into it.
const BarShape: TOC<BarShapeSignature> = <template>
  {{#if (isActive @index)}}
    <Rectangle
      @props={{@props}}
      fill-opacity="0.8"
      stroke={{@props.payload.fill}}
      stroke-dasharray="4"
      stroke-dashoffset="4"
    />
  {{else}}
    <Rectangle @props={{@props}} />
  {{/if}}
</template>

<template>
  <Card as |card|>
    <card.Header>
      <card.Title>Bar Chart - Active</card.Title>
      <card.Description>January - June 2024</card.Description>
    </card.Header>
    <card.Content>
      <ChartContainer @config={{chartConfig}} as |chart|>
        <chart.BarChart @accessibilityLayer={{true}} @data={{chartData}} as |c|>
          <c.CartesianGrid @vertical={{false}} />
          <c.XAxis
            @dataKey="browser"
            @tickLine={{false}}
            @tickMargin={{10}}
            @axisLine={{false}}
            @tickFormatter={{browserLabel}}
          />
          <c.ChartTooltip
            @cursor={{false}}
            @content={{component ChartTooltipContent hideLabel=true}}
          />
          <c.Bar @dataKey="visitors" @strokeWidth={{2}} @radius={{8}} @shape={{BarShape}} />
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
