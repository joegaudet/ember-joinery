import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ChartContainer, ChartTooltipContent, type ChartConfig } from '@ember-joinery/chart'
import { ChartHarness, PolarChartHarness } from '@ember-joinery/chart/test-support'

// The data and config of shadcn's tooltip charts (registry/new-york-v4/charts/chart-tooltip-*).
const chartData = [
  { date: '2024-07-15', running: 450, swimming: 300 },
  { date: '2024-07-16', running: 380, swimming: 420 },
  { date: '2024-07-17', running: 520, swimming: 120 },
  { date: '2024-07-18', running: 140, swimming: 550 },
  { date: '2024-07-19', running: 600, swimming: 350 },
  { date: '2024-07-20', running: 480, swimming: 400 },
]

const chartConfig = {
  running: { label: 'Running', color: 'var(--chart-1)' },
  swimming: { label: 'Swimming', color: 'var(--chart-2)' },
} satisfies ChartConfig

const radarData = [
  { month: 'January', desktop: 186 },
  { month: 'February', desktop: 305 },
  { month: 'March', desktop: 237 },
]

const radarConfig = { desktop: { label: 'Desktop', color: 'var(--chart-1)' } } satisfies ChartConfig

const animations: (boolean | 'auto')[] = ['auto', true, false]

const bottomLeft = [0, 0, 4, 4]
const topRight = [4, 4, 0, 0]

const transitionOf = (chart: ChartHarness) => {
  const wrapper = chart.wrapper.querySelector<HTMLElement>('.recharts-tooltip-wrapper')!
  return [wrapper.style.transitionProperty, wrapper.style.transitionDuration]
}

module('Integration | components | chart tooltip', function (hooks) {
  setupRenderingTest(hooks)

  test("a bar chart's @defaultIndex and keyboard tooltip points at the row's tick, half way down the chart (as Recharts does)", async function (assert) {
    await render(
      <template>
        <ChartContainer @config={{chartConfig}} style="width: 600px" as |chart|>
          <chart.BarChart @data={{chartData}} as |c|>
            <c.XAxis @dataKey="date" @tickLine={{false}} @tickMargin={{10}} @axisLine={{false}} />
            <c.Bar
              @dataKey="running"
              @stackId="a"
              @fill="var(--color-running)"
              @radius={{bottomLeft}}
            />
            <c.Bar
              @dataKey="swimming"
              @stackId="a"
              @fill="var(--color-swimming)"
              @radius={{topRight}}
            />
            <c.ChartTooltip
              @content={{component ChartTooltipContent}}
              @cursor={{false}}
              @defaultIndex={{1}}
            />
          </chart.BarChart>
        </ChartContainer>
      </template>,
    )
    const chart = new ChartHarness()
    assert.strictEqual(chart.tooltip?.label, '2024-07-16')
    // Recharts' Bar has no point of its own for the tooltip (its `getPosition` is a no-op), so the
    // tooltip falls back to the tick, at (offset.top + height) / 2, 10px off it.
    const middle = (chart.plot.y + chart.height) / 2
    assert.deepEqual(
      chart.tooltipPosition,
      { x: chart.categories[1]! + 10, y: middle + 10 },
      "at the row's tick, half way down: not on its bar",
    )

    // The keyboard's tooltip goes to the same place.
    // (The harness reads the categories to three places, the tooltip's translate to four.)
    const atRow = () => {
      const index = chartData.findIndex(row => row.date === chart.tooltip?.label)
      const position = chart.tooltipPosition
      return (
        !!position &&
        Math.abs(position.x - (chart.categories[index]! + 10)) < 0.001 &&
        position.y === middle + 10
      )
    }
    await chart.focus()
    assert.true(atRow(), 'focus')
    await chart.press('ArrowRight')
    assert.true(atRow(), 'ArrowRight')
    await chart.press('ArrowRight')
    assert.true(atRow(), 'ArrowRight again')
    await a11yAudit()
  })

  test('the tooltip glides from row to row unless the user prefers reduced motion (@isAnimationActive)', async function (assert) {
    await render(
      <template>
        {{#each animations as |animate|}}
          <ChartContainer
            @config={{chartConfig}}
            @name="bars-{{animate}}"
            style="width: 400px"
            as |chart|
          >
            <chart.BarChart @data={{chartData}} as |c|>
              <c.XAxis @dataKey="date" />
              <c.Bar @dataKey="running" @fill="var(--color-running)" />
              <c.ChartTooltip
                @content={{component ChartTooltipContent}}
                @defaultIndex={{0}}
                @isAnimationActive={{animate}}
              />
            </chart.BarChart>
          </ChartContainer>
          <ChartContainer
            @config={{radarConfig}}
            @name="radar-{{animate}}"
            style="width: 250px; height: 250px"
            as |chart|
          >
            <chart.RadarChart @data={{radarData}} as |c|>
              <c.PolarAngleAxis @dataKey="month" />
              <c.Radar @dataKey="desktop" @fill="var(--color-desktop)" />
              <c.ChartTooltip
                @content={{component ChartTooltipContent}}
                @defaultIndex={{0}}
                @isAnimationActive={{animate}}
              />
            </chart.RadarChart>
          </ChartContainer>
        {{/each}}
      </template>,
    )
    const reduced = window.matchMedia('(prefers-reduced-motion: reduce)').matches
    for (const [name, Harness] of [
      ['bars', ChartHarness],
      ['radar', PolarChartHarness],
    ] as const) {
      assert.deepEqual(
        transitionOf(new Harness(`${name}-true`)),
        ['transform', '400ms'],
        `${name}: true always glides, for 400ms`,
      )
      assert.deepEqual(transitionOf(new Harness(`${name}-false`)), ['', ''], `${name}: false never`)
      assert.deepEqual(
        transitionOf(new Harness(`${name}-auto`)),
        reduced ? ['', ''] : ['transform', '400ms'],
        `${name}: by default, only without prefers-reduced-motion (here ${reduced ? 'on' : 'off'})`,
      )
    }
    await a11yAudit()
  })
})
