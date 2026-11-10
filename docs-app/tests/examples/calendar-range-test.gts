import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { CalendarHarness, CardHarness } from '@ember-joinery/test-support'
import CalendarRange from 'docs-app/examples/calendar-range'

module('Example | calendar-range', function (hooks) {
  setupRenderingTest(hooks)

  test('two months in a card, with a month-long range from 12 January, and the future disabled', async function (assert) {
    await render(<template><CalendarRange /></template>)
    const calendar = new CalendarHarness()
    const year = new Date().getFullYear()
    assert.true(new CardHarness().exists)
    assert.deepEqual(calendar.captions, [`January ${year}`, `February ${year}`])
    assert.strictEqual(calendar.rangePosition(new Date(year, 0, 12)), 'start')
    assert.strictEqual(calendar.rangePosition(new Date(year, 0, 20)), 'middle')
    assert.strictEqual(calendar.rangePosition(new Date(year, 1, 11)), 'end')
    assert.strictEqual(calendar.selectedDays.length, 31)

    await calendar.select(new Date(year, 0, 5))
    assert.strictEqual(
      calendar.rangePosition(new Date(year, 0, 5)),
      'start',
      'an earlier press moves the start',
    )

    await calendar.next()
    await calendar.next()
    const tomorrow = new Date(
      new Date().getFullYear(),
      new Date().getMonth(),
      new Date().getDate() + 1,
    )
    if (
      calendar.months.some(month => new Date(`${month}T00:00`).getMonth() === tomorrow.getMonth())
    ) {
      assert.true(calendar.isDisabled(tomorrow), 'days after today are disabled')
    }
    await a11yAudit()
  })
})
