import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { CalendarHarness } from '@ember-joinery/test-support'
import CalendarDemo from 'docs-app/examples/calendar-demo'

const caption = (date: Date) =>
  new Intl.DateTimeFormat('en-US', { month: 'long', year: 'numeric' }).format(date)

module('Example | calendar-demo', function (hooks) {
  setupRenderingTest(hooks)

  test('today is selected; another press selects that day, and the dropdowns change the month', async function (assert) {
    await render(<template><CalendarDemo /></template>)
    const calendar = new CalendarHarness()
    const today = new Date()
    assert.strictEqual(calendar.caption, caption(today))
    assert.true(calendar.isSelected(today))
    assert.true(calendar.isToday(today))

    const other = new Date(today.getFullYear(), today.getMonth(), today.getDate() === 10 ? 11 : 10)
    await calendar.select(other)
    assert.true(calendar.isSelected(other))
    assert.false(calendar.isSelected(today))

    await calendar.chooseMonth(0)
    await calendar.chooseYear(today.getFullYear() - 1)
    assert.strictEqual(calendar.caption, `January ${today.getFullYear() - 1}`)
    await a11yAudit()
  })
})
