import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { htmlSafe } from '@ember/template'
import type { TOC } from '@ember/component/template-only'
import { Card, Select } from '@ember-joinery/ember'
import {
  ChartContainer,
  ChartStyle,
  ChartTooltipContent,
  Sector,
  type ChartConfig,
  type LabelContentSignature,
  type SectorProps,
} from '@ember-joinery/chart'

const desktopData = [
  { month: 'january', desktop: 186, fill: 'var(--color-january)' },
  { month: 'february', desktop: 305, fill: 'var(--color-february)' },
  { month: 'march', desktop: 237, fill: 'var(--color-march)' },
  { month: 'april', desktop: 173, fill: 'var(--color-april)' },
  { month: 'may', desktop: 209, fill: 'var(--color-may)' },
]

const chartConfig = {
  visitors: {
    label: 'Visitors',
  },
  desktop: {
    label: 'Desktop',
  },
  mobile: {
    label: 'Mobile',
  },
  january: {
    label: 'January',
    color: 'var(--chart-1)',
  },
  february: {
    label: 'February',
    color: 'var(--chart-2)',
  },
  march: {
    label: 'March',
    color: 'var(--chart-3)',
  },
  april: {
    label: 'April',
    color: 'var(--chart-4)',
  },
  may: {
    label: 'May',
    color: 'var(--chart-5)',
  },
} satisfies ChartConfig

const id = 'pie-interactive'
const months = desktopData.map(item => item.month)

const labelOf = (key: string) => chartConfig[key as keyof typeof chartConfig]?.label

/** The swatch's colour: a config key's variable, so it is safe to bind as a style. */
const swatch = (key: string) => htmlSafe(`background-color: var(--color-${key})`)

const eq = (a: unknown, b: unknown) => a === b
const add = (value: number | undefined, more: number) => (value ?? 0) + more
const localeString = (value: unknown) => Number(value).toLocaleString()
const below = (cy = 0) => cy + 24

interface PieShapeSignature {
  Args: { props: SectorProps; index: number; activeIndex: number }
  Element: Element
}

// Each sector, and the chosen month's with a ring around it (upstream's `renderPieShape`).
// Glimmer has no spread, so the sector's props go to Sector as `@props`, as upstream spreads
// `{...props}`; the example curries in the active index, as upstream's callback closes over it.
const PieShape: TOC<PieShapeSignature> = <template>
  {{#if (eq @index @activeIndex)}}
    <g>
      <Sector @props={{@props}} @outerRadius={{add @props.outerRadius 10}} />
      <Sector
        @props={{@props}}
        @outerRadius={{add @props.outerRadius 25}}
        @innerRadius={{add @props.outerRadius 12}}
      />
    </g>
  {{else}}
    <Sector @props={{@props}} @outerRadius={{@props.outerRadius}} />
  {{/if}}
</template>

// The chosen month's visitors in the donut's hole (upstream's Label `content` function); the
// Label's `@value` carries them, as upstream's function reads `desktopData[activeIndex]`.
const MonthVisitors: TOC<LabelContentSignature> = <template>
  <text x={{@viewBox.cx}} y={{@viewBox.cy}} text-anchor="middle" dominant-baseline="middle">
    <tspan
      x={{@viewBox.cx}}
      y={{@viewBox.cy}}
      class="fill-foreground text-3xl font-bold"
    >{{localeString @value}}</tspan>
    <tspan x={{@viewBox.cx}} y={{below @viewBox.cy}} class="fill-muted-foreground">Visitors</tspan>
  </text>
</template>

export default class ChartPieInteractive extends Component {
  @tracked activeMonth = desktopData[0]!.month

  get activeIndex(): number {
    return desktopData.findIndex(item => item.month === this.activeMonth)
  }

  get activeVisitors(): number {
    return desktopData[this.activeIndex]!.desktop
  }

  setActiveMonth = (month: string) => {
    this.activeMonth = month
  }

  <template>
    <Card data-chart={{id}} class="flex flex-col" as |card|>
      <ChartStyle @id={{id}} @config={{chartConfig}} />
      <card.Header class="flex-row items-start space-y-0 pb-0">
        <div class="grid gap-1">
          <card.Title>Pie Chart - Interactive</card.Title>
          <card.Description>January - June 2024</card.Description>
        </div>
        <Select @value={{this.activeMonth}} @onValueChange={{this.setActiveMonth}} as |s|>
          <s.Trigger class="ml-auto h-7 w-[130px] rounded-lg pl-2.5" aria-label="Select a value">
            <s.Value @placeholder="Select month" />
          </s.Trigger>
          <s.Content @align="end" class="rounded-xl">
            {{#each months as |key|}}
              {{#if (labelOf key)}}
                <s.Item @value={{key}} class="rounded-lg [&_span]:flex">
                  <div class="flex items-center gap-2 text-xs">
                    <span class="flex h-3 w-3 shrink-0 rounded-xs" style={{swatch key}} />
                    {{labelOf key}}
                  </div>
                </s.Item>
              {{/if}}
            {{/each}}
          </s.Content>
        </Select>
      </card.Header>
      <card.Content class="flex flex-1 justify-center pb-0">
        <ChartContainer
          @id={{id}}
          @config={{chartConfig}}
          class="mx-auto aspect-square w-full max-w-[300px]"
          as |chart|
        >
          <chart.PieChart as |c|>
            <c.ChartTooltip
              @cursor={{false}}
              @content={{component ChartTooltipContent hideLabel=true}}
            />
            <c.Pie
              @data={{desktopData}}
              @dataKey="desktop"
              @nameKey="month"
              @innerRadius={{60}}
              @strokeWidth={{5}}
              @shape={{component PieShape activeIndex=this.activeIndex}}
              as |pie|
            >
              <pie.Label @value={{this.activeVisitors}} @content={{MonthVisitors}} />
            </c.Pie>
          </chart.PieChart>
        </ChartContainer>
      </card.Content>
    </Card>
  </template>
}
