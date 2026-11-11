import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { find, render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { CalendarHarness } from '@ember-joinery/test-support'
import CalendarHeadless from 'docs-app/examples/calendar-headless'

module('Example | calendar-headless', function (hooks) {
  setupRenderingTest(hooks)

  test('up to five weekdays, with classes of its own', async function (assert) {
    await render(<template><CalendarHeadless /></template>)
    const calendar = new CalendarHarness()
    const summary = () => find('p')!.textContent!.trim()
    assert.dom(calendar.element).hasClass('rounded-lg').doesNotHaveClass('rdp-root')
    assert.strictEqual(calendar.mode, 'multiple')

    const now = new Date()
    const weekdays = Array.from(
      { length: 28 },
      (_, i) => new Date(now.getFullYear(), now.getMonth(), i + 1),
    )
      .filter(date => date.getDay() !== 0 && date.getDay() !== 6)
      .slice(0, 6)
    const weekend = Array.from(
      { length: 7 },
      (_, i) => new Date(now.getFullYear(), now.getMonth(), i + 1),
    ).find(date => date.getDay() === 6)!
    assert.true(calendar.isDisabled(weekend), 'weekends are disabled')
    await calendar.selectAll(...weekdays.slice(0, 2))
    assert.strictEqual(summary(), '2 days off')
    await calendar.selectAll(...weekdays.slice(2, 5))
    assert.strictEqual(calendar.selectedDays.length, 5)
    await calendar.select(weekdays[5]!)
    assert.strictEqual(summary(), '1 day off', 'a sixth starts again, past @max')
    await a11yAudit()
  })
})
