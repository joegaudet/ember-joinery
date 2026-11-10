import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { formatDateRange, toIsoDate } from '@ember-joinery/power-calendar'
import { PowerCalendarHarness } from '@ember-joinery/power-calendar/test-support'
import PowerCalendarRangeLimits from 'docs-app/examples/power-calendar-range-limits'

const day = (offset: number) => {
  const today = new Date()
  return new Date(today.getFullYear(), today.getMonth(), today.getDate() + offset)
}

module('Example | power-calendar-range-limits', function (hooks) {
  setupRenderingTest(hooks)

  test('one to seven nights, from today on', async function (assert) {
    await render(<template><PowerCalendarRangeLimits /></template>)
    const nights = new PowerCalendarHarness('nights')
    const summary = () => document.querySelector('p[aria-live]')!.textContent!.trim()
    assert.strictEqual(summary(), 'One to seven nights')
    if (new Date().getDate() > 1) {
      assert.true(nights.isDayDisabled(toIsoDate(day(-1))), 'yesterday is past')
    }

    const start = toIsoDate(day(1))
    await nights.select(start)
    await nights.goTo(toIsoDate(day(1)))
    assert.true(nights.isDayDisabled(start), 'the first night is too close to be the last')
    await nights.goTo(toIsoDate(day(9)))
    assert.true(nights.isDayDisabled(toIsoDate(day(9))), 'eight nights is too many')

    await nights.select(toIsoDate(day(4)))
    const range = { from: day(1), to: day(4) }
    assert.strictEqual(
      summary(),
      formatDateRange(range, { locale: 'en-US', format: { dateStyle: 'medium' } }),
    )
    await a11yAudit()
  })
})
