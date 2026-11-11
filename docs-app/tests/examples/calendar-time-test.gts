import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { CalendarHarness, InputGroupHarness } from '@ember-joinery/test-support'
import CalendarWithTime from 'docs-app/examples/calendar-time'

module('Example | calendar-time', function (hooks) {
  setupRenderingTest(hooks)

  test('a calendar with start and end times below it', async function (assert) {
    await render(<template><CalendarWithTime /></template>)
    const calendar = new CalendarHarness()
    const now = new Date()
    assert.true(calendar.isSelected(new Date(now.getFullYear(), now.getMonth(), 12)))
    const [start, end] = InputGroupHarness.findAll()
    assert
      .dom(start!.element.querySelector('input'))
      .hasValue('10:30:00')
      .hasAttribute('type', 'time')
    assert.dom(end!.element.querySelector('input')).hasValue('12:30:00')
    assert.dom('label[for="time-from"]').hasText('Start Time')
    await calendar.select(new Date(now.getFullYear(), now.getMonth(), 20))
    assert.true(calendar.isSelected(new Date(now.getFullYear(), now.getMonth(), 20)))
    await a11yAudit()
  })
})
