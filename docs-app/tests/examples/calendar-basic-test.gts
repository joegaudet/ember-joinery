import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { CalendarHarness } from '@ember-joinery/test-support'
import CalendarBasic from 'docs-app/examples/calendar-basic'

module('Example | calendar-basic', function (hooks) {
  setupRenderingTest(hooks)

  test('it selects a day of its own, and lets it go', async function (assert) {
    await render(<template><CalendarBasic /></template>)
    const calendar = new CalendarHarness()
    const today = new Date()
    assert.deepEqual(calendar.selectedDays, [])
    assert.dom(calendar.element).hasClass('rounded-lg').hasClass('border')
    await calendar.select(today)
    assert.true(calendar.isSelected(today))
    await calendar.select(today)
    assert.deepEqual(calendar.selectedDays, [])
    await a11yAudit()
  })
})
