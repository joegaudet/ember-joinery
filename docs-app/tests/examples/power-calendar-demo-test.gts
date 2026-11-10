import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { toIsoDate } from '@ember-joinery/power-calendar'
import { PowerCalendarHarness } from '@ember-joinery/power-calendar/test-support'
import PowerCalendarDemo from 'docs-app/examples/power-calendar-demo'

module('Example | power-calendar-demo', function (hooks) {
  setupRenderingTest(hooks)

  test('it opens on today, chosen, and a press chooses another day', async function (assert) {
    await render(<template><PowerCalendarDemo /></template>)
    const calendar = new PowerCalendarHarness('demo')
    const today = toIsoDate(new Date())

    assert.strictEqual(calendar.today, today)
    assert.deepEqual(calendar.selected, [today])
    assert.strictEqual(calendar.tabStop, today, 'Tab lands on the chosen day')

    const other = calendar.days.find(day => day !== today)!
    await calendar.select(other)
    assert.deepEqual(calendar.selected, [other])

    await calendar.nextMonth()
    assert.notEqual(calendar.shownMonth, today.slice(0, 7))
    await a11yAudit()
  })
})
