import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { CalendarHarness, CardHarness } from '@ember-joinery/test-support'
import CalendarWeekNumbers from 'docs-app/examples/calendar-week-numbers'

module('Example | calendar-week-numbers', function (hooks) {
  setupRenderingTest(hooks)

  test('a column of week numbers beside February', async function (assert) {
    await render(<template><CalendarWeekNumbers /></template>)
    const calendar = new CalendarHarness()
    const year = new Date().getFullYear()
    assert.true(new CardHarness().exists)
    assert.strictEqual(calendar.caption, `February ${year}`)
    assert.strictEqual(calendar.weekNumbers.length, calendar.cells.length / 7)
    assert.true(calendar.weekNumbers.every(number => /^\d\d$/.test(number)))
    assert.true(calendar.isSelected(new Date(year, 1, 3)))
    await a11yAudit()
  })
})
