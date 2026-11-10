import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { render } from '@ember/test-helpers'
import type { TOC } from '@ember/component/template-only'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import {
  ChartContainer,
  ChartTooltipContent,
  Rectangle,
  type BarShapeSignature,
  type ChartConfig,
} from '@ember-joinery/chart'
import { ChartHarness } from '@ember-joinery/chart/test-support'

// The data and configs of shadcn's bar charts (registry/new-york-v4/charts/chart-bar-*), drawn
// at the size the charts gallery draws them, 275 × 155.
const size = 'width: 275px; height: 155px'
const flat = (d: string | null) => (d ?? '').replace(/\s+/g, ' ')

const browsers = [
  { browser: 'chrome', visitors: 275, fill: 'var(--color-chrome)' },
  { browser: 'safari', visitors: 200, fill: 'var(--color-safari)' },
  { browser: 'firefox', visitors: 187, fill: 'var(--color-firefox)' },
  { browser: 'edge', visitors: 173, fill: 'var(--color-edge)' },
  { browser: 'other', visitors: 90, fill: 'var(--color-other)' },
]

const browserConfig = {
  visitors: { label: 'Visitors' },
  chrome: { label: 'Chrome', color: 'var(--chart-1)' },
  safari: { label: 'Safari', color: 'var(--chart-2)' },
  firefox: { label: 'Firefox', color: 'var(--chart-3)' },
  edge: { label: 'Edge', color: 'var(--chart-4)' },
  other: { label: 'Other', color: 'var(--chart-5)' },
} satisfies ChartConfig

const months = [
  { month: 'January', visitors: 186 },
  { month: 'February', visitors: 205 },
  { month: 'March', visitors: -207 },
  { month: 'April', visitors: 173 },
  { month: 'May', visitors: -209 },
  { month: 'June', visitors: 214 },
]

const browserLabel = (value: string) => browserConfig[value as keyof typeof browserConfig]?.label
const isPositive = (value: number) => value > 0

// What recharts 3.8 draws for the same charts (dumped from the parity app).
const RECHARTS = {
  negative: [
    'M 9.4167,32.55 h 35 v 44.95 h -35 Z',
    'M 53.5833,27.9583 h 35 v 49.5417 h -35 Z',
    'M 97.75,127.525 h 35 v -50.025 h -35 Z',
    'M 141.9167,35.6917 h 35 v 41.8083 h -35 Z',
    'M 186.0833,128.0083 h 35 v -50.5083 h -35 Z',
    'M 230.25,25.7833 h 35 v 51.7167 h -35 Z',
  ],
  mixedFirst:
    'M 60,8.1 A 5,5,0,0,1,65,3.1 L 266.1607,3.1 A 5,5,0,0,1,271.1607,8.1 L 271.1607,22.1 A 5,5,0,0,1,266.1607,27.1 L 65,27.1 A 5,5,0,0,1,60,22.1 Z',
  activeThird:
    'M 116.3,15.0536 A 8,8,0,0,1,124.3,7.0536 L 150.3,7.0536 A 8,8,0,0,1,158.3,15.0536 L 158.3,112 A 8,8,0,0,1,150.3,120 L 124.3,120 A 8,8,0,0,1,116.3,112 Z',
  customFirst:
    'M 0,6.5833 A 4,4,0,0,1,4,2.5833 L 146.5438,2.5833 A 4,4,0,0,1,150.5438,6.5833 L 150.5438,18.5833 A 4,4,0,0,1,146.5438,22.5833 L 4,22.5833 A 4,4,0,0,1,0,18.5833 Z',
}

const ACTIVE_INDEX = 2
const isActiveBar = (index: number) => index === ACTIVE_INDEX

const ActiveBar: TOC<BarShapeSignature> = <template>
  {{#if (isActiveBar @index)}}
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

module('Integration | components | chart | bar', function (hooks) {
  setupRenderingTest(hooks)

  test("negative bars, each Cell's fill, and labels in the bar's fill", async function (assert) {
    const config = { visitors: { label: 'Visitors' } } satisfies ChartConfig
    await render(
      <template>
        <ChartContainer @config={{config}} style={{size}} as |chart|>
          <chart.BarChart @accessibilityLayer={{true}} @data={{months}} as |c|>
            <c.CartesianGrid @vertical={{false}} />
            <c.ChartTooltip
              @cursor={{false}}
              @content={{component ChartTooltipContent hideLabel=true hideIndicator=true}}
            />
            <c.Bar @dataKey="visitors" as |bar|>
              <bar.LabelList @position="top" @dataKey="month" @fillOpacity={{1}} />
              {{#each months as |item|}}
                <bar.Cell
                  @fill={{if (isPositive item.visitors) "var(--chart-1)" "var(--chart-2)"}}
                />
              {{/each}}
            </c.Bar>
          </chart.BarChart>
        </ChartContainer>
      </template>,
    )
    const chart = new ChartHarness()
    const bars = chart.bars('visitors')
    assert.deepEqual(
      bars.map(bar => flat(bar.getAttribute('d'))),
      RECHARTS.negative,
    )
    assert.deepEqual(
      bars.map(bar => bar.getAttribute('fill')),
      [
        'var(--chart-1)',
        'var(--chart-1)',
        'var(--chart-2)',
        'var(--chart-1)',
        'var(--chart-2)',
        'var(--chart-1)',
      ],
      "each Cell's fill",
    )
    assert.deepEqual(
      chart.labels('visitors'),
      months.map(row => row.month),
    )
    const labels = chart.surface.querySelectorAll('.recharts-label-list text')
    assert.dom(labels[0]).hasClass('recharts-label', "recharts' class, without one of your own")
    assert.dom(labels[0]).hasAttribute('fill', 'var(--chart-1)', "the bar's fill")
    assert.dom(labels[0]).hasAttribute('fill-opacity', '1')
    assert.dom(labels[2]).hasAttribute('fill', 'var(--chart-2)')
    assert.strictEqual(Number(labels[2]!.getAttribute('y')), 132.525, 'below a negative bar')
    assert.dom(labels[2]!.querySelector('tspan')).hasAttribute('dy', '0.71em')
    await chart.hover(2)
    assert.deepEqual(chart.tooltip!.entryValues, ['-207'])
    assert.strictEqual(chart.tooltip!.items[0]!.indicator, null, 'hideIndicator')
    await a11yAudit()
  })

  test("a bar takes its row's fill, in a vertical chart named by the config", async function (assert) {
    const margin = { left: 0 }
    await render(
      <template>
        <ChartContainer @config={{browserConfig}} style={{size}} as |chart|>
          <chart.BarChart
            @accessibilityLayer={{true}}
            @data={{browsers}}
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
      </template>,
    )
    const chart = new ChartHarness()
    const bars = chart.bars('visitors')
    assert.strictEqual(flat(bars[0]!.getAttribute('d')), RECHARTS.mixedFirst)
    assert.deepEqual(
      bars.map(bar => bar.getAttribute('fill')),
      browsers.map(row => row.fill),
      "each bar in its row's fill, the bar having none",
    )
    assert.deepEqual(chart.yTicks, ['Chrome', 'Safari', 'Firefox', 'Edge', 'Other'])
    await chart.hover(0)
    assert.deepEqual(chart.tooltip!.names, ['Visitors'])
    assert.true(
      chart.tooltip!.items[0]!.indicator!.getAttribute('style')!.includes('var(--color-chrome)'),
      "the indicator in the row's fill",
    )
    await a11yAudit()
  })

  test("a bar's @shape draws each bar, here the active one dashed", async function (assert) {
    const data = [
      { browser: 'chrome', visitors: 187, fill: 'var(--color-chrome)' },
      { browser: 'safari', visitors: 200, fill: 'var(--color-safari)' },
      { browser: 'firefox', visitors: 275, fill: 'var(--color-firefox)' },
      { browser: 'edge', visitors: 173, fill: 'var(--color-edge)' },
      { browser: 'other', visitors: 90, fill: 'var(--color-other)' },
    ]
    await render(
      <template>
        <ChartContainer @config={{browserConfig}} style={{size}} as |chart|>
          <chart.BarChart @accessibilityLayer={{true}} @data={{data}} as |c|>
            <c.CartesianGrid @vertical={{false}} />
            <c.XAxis
              @dataKey="browser"
              @tickLine={{false}}
              @tickMargin={{10}}
              @axisLine={{false}}
              @tickFormatter={{browserLabel}}
            />
            <c.Bar @dataKey="visitors" @strokeWidth={{2}} @radius={{8}} @shape={{ActiveBar}} />
          </chart.BarChart>
        </ChartContainer>
      </template>,
    )
    const chart = new ChartHarness()
    const bars = chart.bars('visitors')
    assert.strictEqual(bars.length, 5)
    const active = bars[2]!
    assert.strictEqual(flat(active.getAttribute('d')), RECHARTS.activeThird)
    assert
      .dom(active)
      .hasClass('recharts-rectangle')
      .hasAttribute('fill', 'var(--color-firefox)')
      .hasAttribute('stroke', 'var(--color-firefox)')
      .hasAttribute('stroke-width', '2')
      .hasAttribute('fill-opacity', '0.8')
      .hasAttribute('stroke-dasharray', '4')
    assert.dom(bars[0]).doesNotHaveAttribute('stroke-dasharray')
    assert.dom(bars[0]).doesNotHaveAttribute('stroke')
    assert.dom(active.parentElement).hasClass('recharts-inactive-bar')
    await a11yAudit()
  })

  test('labels inside and beside the bars of a vertical chart', async function (assert) {
    const data = [
      { month: 'January', desktop: 186 },
      { month: 'February', desktop: 305 },
      { month: 'March', desktop: 237 },
      { month: 'April', desktop: 73 },
      { month: 'May', desktop: 209 },
      { month: 'June', desktop: 214 },
    ]
    const config = {
      desktop: { label: 'Desktop', color: 'var(--chart-2)' },
      label: { color: 'var(--background)' },
    } satisfies ChartConfig
    const margin = { right: 16 }
    await render(
      <template>
        <ChartContainer @config={{config}} style={{size}} as |chart|>
          <chart.BarChart @data={{data}} @layout="vertical" @margin={{margin}} as |c|>
            <c.CartesianGrid @horizontal={{false}} />
            <c.YAxis @dataKey="month" @type="category" @hide={{true}} />
            <c.XAxis @dataKey="desktop" @type="number" @hide={{true}} />
            <c.Bar @dataKey="desktop" @fill="var(--color-desktop)" @radius={{4}} as |bar|>
              <bar.LabelList
                @dataKey="month"
                @position="insideLeft"
                @offset={{8}}
                @class="fill-(--color-label)"
                @fontSize={{12}}
              />
              <bar.LabelList
                @dataKey="desktop"
                @position="right"
                @offset={{8}}
                @class="fill-foreground"
                @fontSize={{12}}
              />
            </c.Bar>
          </chart.BarChart>
        </ChartContainer>
      </template>,
    )
    const chart = new ChartHarness()
    assert.strictEqual(flat(chart.bars('desktop')[0]!.getAttribute('d')), RECHARTS.customFirst)
    const [inside, beside] = chart.labelLists('desktop')
    assert.deepEqual(
      inside,
      data.map(row => row.month),
    )
    assert.deepEqual(
      beside,
      data.map(row => String(row.desktop)),
    )
    const texts = chart.surface.querySelectorAll('.recharts-label-list text')
    assert.dom(texts[0]).hasAttribute('x', '8').hasAttribute('text-anchor', 'start')
    assert.dom(texts[0]).hasClass('fill-(--color-label)').doesNotHaveClass('recharts-label')
    assert.dom(texts[0]).hasAttribute('fill', '#808080', 'grey, the row having no fill')
    assert.strictEqual(
      Number(texts[6]!.getAttribute('x')).toFixed(4),
      '158.5438',
      "the bar's end, plus 8",
    )
    await a11yAudit()
  })

  test('a bar with no length is left out, as recharts leaves it out', async function (assert) {
    const data = [
      { month: 'January', desktop: 186 },
      { month: 'February', desktop: 0 },
      { month: 'March', desktop: 237 },
    ]
    const config = { desktop: { label: 'Desktop', color: 'var(--chart-1)' } } satisfies ChartConfig
    await render(
      <template>
        <ChartContainer @config={{config}} style={{size}} as |chart|>
          <chart.BarChart @data={{data}} as |c|>
            <c.Bar @dataKey="desktop" @fill="var(--color-desktop)" />
          </chart.BarChart>
        </ChartContainer>
      </template>,
    )
    const chart = new ChartHarness()
    assert.deepEqual(
      chart.bars('desktop').map(bar => bar.getAttribute('data-test-jn-value')),
      ['186', '237'],
    )
    await a11yAudit()
  })
})
