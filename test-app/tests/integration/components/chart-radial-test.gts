import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { render } from '@ember/test-helpers'
import type { TOC } from '@ember/component/template-only'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import {
  ChartContainer,
  ChartTooltipContent,
  type ChartConfig,
  type PolarLabelContentSignature,
} from '@ember-joinery/chart'
import { PolarChartHarness } from '@ember-joinery/chart/test-support'

// The data and config of shadcn's radial charts (registry/new-york-v4/charts/chart-radial-*).
const chartData = [
  { browser: 'chrome', visitors: 275, fill: 'var(--color-chrome)' },
  { browser: 'safari', visitors: 200, fill: 'var(--color-safari)' },
  { browser: 'firefox', visitors: 187, fill: 'var(--color-firefox)' },
  { browser: 'edge', visitors: 173, fill: 'var(--color-edge)' },
  { browser: 'other', visitors: 90, fill: 'var(--color-other)' },
]

const chartConfig = {
  visitors: { label: 'Visitors' },
  chrome: { label: 'Chrome', color: 'var(--chart-1)' },
  safari: { label: 'Safari', color: 'var(--chart-2)' },
  firefox: { label: 'Firefox', color: 'var(--chart-3)' },
  edge: { label: 'Edge', color: 'var(--chart-4)' },
  other: { label: 'Other', color: 'var(--chart-5)' },
} satisfies ChartConfig

const stackedData = [{ month: 'january', mobile: 570, desktop: 1260 }]
const stackedConfig = {
  desktop: { label: 'Desktop', color: 'var(--chart-1)' },
  mobile: { label: 'Mobile', color: 'var(--chart-2)' },
} satisfies ChartConfig

// The gallery's radial charts are 250px square (`aspect-square max-h-[250px]` in their card).
const square = 'width: 250px; height: 250px; aspect-ratio: auto'

// What recharts 3.8 draws for the same charts at the same size (dumped from the parity app).
const RECHARTS = {
  simple: [
    'M 168.6,125\n    A 43.6,43.6,0,\n    1,0,\n    168.6,125.0008\n  L 156.6,125.0006\n            A 31.6,31.6,0,\n            1,1,\n            156.6,125 Z',
    'M 184.6,125\n    A 59.6,59.6,0,\n    1,0,\n    116.518,183.9934\n  L 118.2258,172.1155\n            A 47.6,47.6,0,\n            1,1,\n            172.6,125 Z',
  ],
  label: {
    second:
      'M 125,184.6\n    A 59.6,59.6,0,\n    1,0,\n    106.4028,181.6242\n  L 110.1472,170.2234\n            A 47.6,47.6,0,\n            1,1,\n            125,172.6 Z',
    arc: 'M128.27705592731195,162.45692064824965\n    A37.6,37.6,0,1,0,\n    127.6228434127791,162.5084082897694',
  },
  stacked: {
    mobile:
      'M 226.8774,125\n    A5,5,0,0,0,231.8714,119.7549\n    A107,107,0,0,0,146.1149,20.104\n    A5,5,0,0,0,140.184,24.2605\n  L138.0945,38.1235\n      A5,5,0,0,0,142.0138,43.7625\n      A83,83,0,0,1,207.8659,120.2841\n      A5,5,0,0,0,212.8578,125Z',
    desktop:
      'M 140.184,24.2605\n    A5,5,0,0,0,135.7418,18.5406\n    A107,107,0,0,0,18.1286,119.7549\n    A5,5,0,0,0,23.1226,125\n  L37.1422,125\n      A5,5,0,0,0,42.1341,120.2841\n      A83,83,0,0,1,132.6873,42.3568\n      A5,5,0,0,0,138.0945,38.1235Z',
  },
  text: 'M 209.9058,125\n    A4,4,0,0,0,213.9014,120.8118\n    A89,89,0,1,0,90.6583,207.1075\n    A4,4,0,0,0,95.9605,204.7854\n  L95.9605,204.7854\n      A4,4,0,0,0,93.7452,199.7271\n      A81,81,0,1,1,205.9103,121.1882\n      A4,4,0,0,0,209.9058,125Z',
  grid: [
    'M 167.4,125\n    A 42.4,42.4,0,\n    1,0,\n    167.4,125.0007\n  L 156.4,125.0005\n            A 31.4,31.4,0,\n            1,1,\n            156.4,125 Z',
  ],
}

const Total: TOC<PolarLabelContentSignature> = <template>
  <text x={{@viewBox.cx}} y={{@viewBox.cy}} text-anchor="middle" data-total>
    <tspan x={{@viewBox.cx}} y={{@viewBox.cy}}>1,830</tspan>
  </text>
</template>

const textRadii = [90, 80]
const shapeClass = 'first:fill-muted last:fill-background'

module('Integration | components | chart-radial', function (hooks) {
  setupRenderingTest(hooks)

  test('a radial bar chart draws the bars and tracks recharts draws', async function (assert) {
    await render(
      <template>
        <ChartContainer @config={{chartConfig}} @name="radial" style={{square}} as |chart|>
          <chart.RadialBarChart @data={{chartData}} @innerRadius={{30}} @outerRadius={{110}} as |c|>
            <c.ChartTooltip
              @cursor={{false}}
              @content={{component ChartTooltipContent hideLabel=true nameKey="browser"}}
            />
            <c.RadialBar @dataKey="visitors" @background={{true}} />
          </chart.RadialBarChart>
        </ChartContainer>
      </template>,
    )
    const chart = new PolarChartHarness('radial')
    assert.strictEqual(chart.layout, 'radial')
    assert.deepEqual(chart.ring, {
      cx: 125,
      cy: 125,
      innerRadius: 30,
      outerRadius: 110,
      startAngle: 0,
      endAngle: 360,
    })
    assert.deepEqual(chart.categories, [38, 54, 70, 86, 102], 'a ring per browser, out from 30px')
    const bars = chart.radialBars('visitors')
    assert.strictEqual(bars.length, 5)
    assert.dom(bars[0]).hasAttribute('d', RECHARTS.simple[0]!, 'the largest goes all the way round')
    assert.dom(bars[1]).hasAttribute('d', RECHARTS.simple[1]!)
    assert
      .dom(bars[1])
      .hasAttribute('fill', 'var(--color-safari)', "a row's fill colours its bar")
      .hasClass('recharts-radial-bar-sector')
      .hasClass('recharts-sector')
    const tracks = chart.backgroundSectors
    assert.strictEqual(tracks.length, 5, 'a track behind each bar')
    assert.dom(tracks[0]).hasAttribute('d', RECHARTS.simple[0]!).hasAttribute('fill', '#eee')
    assert.notStrictEqual(
      getComputedStyle(tracks[1]!).fill,
      'rgb(238, 238, 238)',
      "the chart's CSS fills the tracks with --muted",
    )
    await a11yAudit()
  })

  test('a grid, labels along the bars, and start and end angles', async function (assert) {
    await render(
      <template>
        <ChartContainer @config={{chartConfig}} @name="grid" style={{square}} as |chart|>
          <chart.RadialBarChart @data={{chartData}} @innerRadius={{30}} @outerRadius={{100}} as |c|>
            <c.PolarGrid @gridType="circle" />
            <c.RadialBar @dataKey="visitors" />
          </chart.RadialBarChart>
        </ChartContainer>
        <ChartContainer @config={{chartConfig}} @name="label" style={{square}} as |chart|>
          <chart.RadialBarChart
            @data={{chartData}}
            @startAngle={{-90}}
            @endAngle={{380}}
            @innerRadius={{30}}
            @outerRadius={{110}}
            as |c|
          >
            <c.RadialBar @dataKey="visitors" @background={{true}} as |bar|>
              <bar.LabelList
                @position="insideStart"
                @dataKey="browser"
                @class="fill-white capitalize mix-blend-luminosity"
                @fontSize={{11}}
              />
            </c.RadialBar>
          </chart.RadialBarChart>
        </ChartContainer>
      </template>,
    )
    const grid = new PolarChartHarness('grid')
    assert.deepEqual(grid.polarGrid!.radii, [37, 51, 65, 79, 93], "a ring at each band's middle")
    assert.strictEqual(
      grid.polarGrid!.angles.length,
      14,
      "a spoke at each of the angle axis's ticks (0 to 260)",
    )
    assert.dom(grid.radialBars('visitors')[0]).hasAttribute('d', RECHARTS.grid[0]!)
    assert.strictEqual(grid.backgroundSectors.length, 0, 'no tracks without @background')

    const label = new PolarChartHarness('label')
    assert.dom(label.radialBars('visitors')[1]).hasAttribute('d', RECHARTS.label.second)
    assert.deepEqual(label.labels('visitors'), ['chrome', 'safari', 'firefox', 'edge', 'other'])
    const [first] = Array.from(
      label.surface.querySelectorAll<SVGTextElement>('[data-test-jn-part="label"]'),
    )
    assert
      .dom(first)
      .hasClass('recharts-radial-bar-label')
      .hasClass('capitalize')
      .hasAttribute('font-size', '11')
      .hasAttribute('dominant-baseline', 'central')
      .hasAttribute('fill', 'var(--color-chrome)')
    const arc = first!.querySelector('defs path')!
    assert.strictEqual(
      arc.getAttribute('d'),
      RECHARTS.label.arc,
      "the arc it runs along, from the bar's start",
    )
    assert.dom(first!.querySelector('textPath')).hasAttribute('href', `#${arc.id}`)
    await a11yAudit()
  })

  test('stacked bars with rounded corners, and a Label in the middle', async function (assert) {
    await render(
      <template>
        <ChartContainer @config={{stackedConfig}} @name="stacked" style={{square}} as |chart|>
          <chart.RadialBarChart
            @data={{stackedData}}
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
      </template>,
    )
    const chart = new PolarChartHarness('stacked')
    assert.dom(chart.radialBars('mobile')[0]).hasAttribute('d', RECHARTS.stacked.mobile)
    assert
      .dom(chart.radialBars('desktop')[0])
      .hasAttribute(
        'd',
        RECHARTS.stacked.desktop,
        "stacked on mobile's, and cut at the end of the angle axis, as recharts cuts it",
      )
    assert.dom(chart.seriesFor('mobile').element).hasClass('stroke-transparent')
    assert.dom(chart.radialBars('mobile')[0]).hasAttribute('fill', 'var(--color-mobile)')
    const total = chart.radiusAxis!.querySelector('[data-total]')!
    assert.dom(total).hasAttribute('x', '125').hasAttribute('y', '125', "handed the chart's centre")
    assert.deepEqual(chart.radiusTicks, [], 'no ticks')
    assert.dom(chart.radiusAxis!.querySelector('line')).doesNotExist('no axis line')

    await chart.hover(0)
    assert.deepEqual(chart.tooltip?.names, ['Desktop', 'Mobile'])
    assert.deepEqual(chart.tooltip?.entryValues, ['1,260', '570'])
    await a11yAudit()
  })

  test("a grid's rings at given radii, with classes on each", async function (assert) {
    const data = [{ browser: 'safari', visitors: 200, fill: 'var(--color-safari)' }]
    await render(
      <template>
        <ChartContainer @config={{chartConfig}} @name="text" style={{square}} as |chart|>
          <chart.RadialBarChart
            @data={{data}}
            @startAngle={{0}}
            @endAngle={{250}}
            @outerRadius={{90}}
            @innerRadius={{80}}
            as |c|
          >
            <c.PolarGrid
              @gridType="circle"
              @radialLines={{false}}
              @stroke="none"
              @class={{shapeClass}}
              @polarRadius={{textRadii}}
            />
            <c.RadialBar @dataKey="visitors" @background={{true}} @cornerRadius={{10}} />
          </chart.RadialBarChart>
        </ChartContainer>
      </template>,
    )
    const chart = new PolarChartHarness('text')
    const grid = chart.polarGrid!
    assert.deepEqual(grid.radii, [90, 80])
    assert.dom(grid.rings[0]).hasAttribute('stroke', 'none').hasClass('first:fill-muted')
    assert.strictEqual(
      grid.rings[0]!.parentElement!.children.length,
      2,
      'the two rings alone in their group, so first: and last: pick them',
    )
    assert.deepEqual(grid.spokes, [])
    assert
      .dom(chart.radialBars('visitors')[0])
      .hasAttribute('d', RECHARTS.text, 'corners rounded by at most half the bar')
    assert.dom(chart.backgroundSectors[0]).hasAttribute('d', RECHARTS.text)
    await a11yAudit()
  })

  test('the tooltip finds the bar under the pointer, and the keyboard steps through them', async function (assert) {
    await render(
      <template>
        <ChartContainer @config={{chartConfig}} @name="tooltip" style={{square}} as |chart|>
          <chart.RadialBarChart @data={{chartData}} @innerRadius={{30}} @outerRadius={{110}} as |c|>
            <c.ChartTooltip
              @isAnimationActive={{false}}
              @content={{component ChartTooltipContent hideLabel=true nameKey="browser"}}
            />
            <c.RadialBar @dataKey="visitors" @background={{true}} />
          </chart.RadialBarChart>
        </ChartContainer>
      </template>,
    )
    const chart = new PolarChartHarness('tooltip')
    await chart.hover(2)
    assert.deepEqual(chart.tooltip?.names, ['Firefox'], "named by the row's browser")
    assert.deepEqual(chart.tooltip?.entryValues, ['187'])
    const indicator = chart.tooltip!.items[0]!.indicator!
    assert.true(
      indicator.getAttribute('style')!.includes('var(--color-firefox)'),
      "the indicator takes the row's fill",
    )
    assert
      .dom(chart.cursor)
      .hasClass('recharts-sector', "a ring cursor through the bar (recharts')")
    await chart.unhover()
    assert.false(chart.isTooltipVisible)

    await chart.focus()
    assert.deepEqual(chart.tooltip?.names, ['Chrome'], 'focus shows the first bar')
    await chart.press('ArrowRight')
    assert.deepEqual(chart.tooltip?.names, ['Safari'])
    await a11yAudit()
  })
})
