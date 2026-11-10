import { Card, Icon } from '@ember-joinery/ember'
import { ChartContainer, ChartTooltipContent, type ChartConfig } from '@ember-joinery/chart'
import { TrendingUp } from 'lucide'

const chartData = [
  { month: 'January', visitors: 186 },
  { month: 'February', visitors: 205 },
  { month: 'March', visitors: -207 },
  { month: 'April', visitors: 173 },
  { month: 'May', visitors: -209 },
  { month: 'June', visitors: 214 },
]

const chartConfig = {
  visitors: {
    label: 'Visitors',
  },
} satisfies ChartConfig

const cellFill = (visitors: number) => (visitors > 0 ? 'var(--chart-1)' : 'var(--chart-2)')

<template>
  <Card as |card|>
    <card.Header>
      <card.Title>Bar Chart - Negative</card.Title>
      <card.Description>January - June 2024</card.Description>
    </card.Header>
    <card.Content>
      <ChartContainer @config={{chartConfig}} as |chart|>
        <chart.BarChart @accessibilityLayer={{true}} @data={{chartData}} as |c|>
          <c.CartesianGrid @vertical={{false}} />
          <c.ChartTooltip
            @cursor={{false}}
            @content={{component ChartTooltipContent hideLabel=true hideIndicator=true}}
          />
          <c.Bar @dataKey="visitors" as |bar|>
            <bar.LabelList @position="top" @dataKey="month" @fillOpacity={{1}} />
            {{#each chartData as |item|}}
              <bar.Cell @fill={{cellFill item.visitors}} />
            {{/each}}
          </c.Bar>
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
