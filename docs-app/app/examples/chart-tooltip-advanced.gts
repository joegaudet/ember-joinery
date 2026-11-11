import type { TOC } from '@ember/component/template-only'
import { htmlSafe } from '@ember/template'
import { Card } from '@ember-joinery/ember'
import {
  ChartContainer,
  ChartTooltipContent,
  type ChartConfig,
  type TooltipFormatterSignature,
} from '@ember-joinery/chart'

const chartData = [
  { date: '2024-07-15', running: 450, swimming: 300 },
  { date: '2024-07-16', running: 380, swimming: 420 },
  { date: '2024-07-17', running: 520, swimming: 120 },
  { date: '2024-07-18', running: 140, swimming: 550 },
  { date: '2024-07-19', running: 600, swimming: 350 },
  { date: '2024-07-20', running: 480, swimming: 400 },
]

const chartConfig = {
  running: {
    label: 'Running',
    color: 'var(--chart-1)',
  },
  swimming: {
    label: 'Swimming',
    color: 'var(--chart-2)',
  },
} satisfies ChartConfig

const weekday = (value: string) =>
  new Date(value).toLocaleDateString('en-US', {
    weekday: 'short',
  })
const bottom = [0, 0, 4, 4]
const top = [4, 4, 0, 0]

const labelOf = (name: string | number) =>
  chartConfig[name as keyof typeof chartConfig]?.label || name
const colorBg = (name: string | number) => htmlSafe(`--color-bg: var(--color-${name})`)
const isLast = (index: number) => index === 1
const total = (payload: Record<string, unknown> | undefined) =>
  Number(payload?.['running']) + Number(payload?.['swimming'])

// Upstream's `formatter` returns markup; here it is a component, handed the same arguments.
const Kcal: TOC<TooltipFormatterSignature> = <template>
  <div class="h-2.5 w-2.5 shrink-0 rounded-[2px] bg-(--color-bg)" style={{colorBg @name}}></div>
  {{labelOf @name}}
  <div
    class="ml-auto flex items-baseline gap-0.5 font-mono font-medium text-foreground tabular-nums"
  >
    {{@value}}
    <span class="font-normal text-muted-foreground">
      kcal
    </span>
  </div>
  {{! Add this after the last item }}
  {{#if (isLast @index)}}
    <div
      class="mt-1.5 flex basis-full items-center border-t pt-1.5 text-xs font-medium text-foreground"
    >
      Total
      <div
        class="ml-auto flex items-baseline gap-0.5 font-mono font-medium text-foreground tabular-nums"
      >
        {{total @payload}}
        <span class="font-normal text-muted-foreground">
          kcal
        </span>
      </div>
    </div>
  {{/if}}
</template>

<template>
  <Card as |card|>
    <card.Header>
      <card.Title>Tooltip - Advanced</card.Title>
      <card.Description>Tooltip with custom formatter and total.</card.Description>
    </card.Header>
    <card.Content>
      <ChartContainer @config={{chartConfig}} as |chart|>
        <chart.BarChart @accessibilityLayer={{true}} @data={{chartData}} as |c|>
          <c.XAxis
            @dataKey="date"
            @tickLine={{false}}
            @tickMargin={{10}}
            @axisLine={{false}}
            @tickFormatter={{weekday}}
          />
          <c.Bar @dataKey="running" @stackId="a" @fill="var(--color-running)" @radius={{bottom}} />
          <c.Bar @dataKey="swimming" @stackId="a" @fill="var(--color-swimming)" @radius={{top}} />
          <c.ChartTooltip
            @content={{component
              ChartTooltipContent
              hideLabel=true
              class="w-[180px]"
              formatter=Kcal
            }}
            @cursor={{false}}
            @defaultIndex={{1}}
          />
        </chart.BarChart>
      </ChartContainer>
    </card.Content>
  </Card>
</template>
