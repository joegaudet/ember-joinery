import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { CalendarHarness, ButtonHarness } from '@ember-joinery/test-support'
import CalendarWithPresets from 'docs-app/examples/calendar-presets'

const iso = (date: Date) =>
  `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}-${String(date.getDate()).padStart(2, '0')}`

module('Example | calendar-presets', function (hooks) {
  setupRenderingTest(hooks)

  test('a preset selects a day from today and shows its month', async function (assert) {
    await render(<template><CalendarWithPresets /></template>)
    const calendar = new CalendarHarness()
    const now = new Date()
    assert.strictEqual(calendar.months[0], iso(new Date(now.getFullYear(), now.getMonth(), 1)))
    assert.strictEqual(calendar.cells.length, 42, 'fixed weeks')

    const buttons = ButtonHarness.findAll()
    assert.deepEqual(
      buttons.map(button => button.text),
      ['Today', 'Tomorrow', 'In 3 days', 'In a week', 'In 2 weeks'],
    )
    await buttons[4]!.click()
    const inTwoWeeks = new Date(now.getFullYear(), now.getMonth(), now.getDate() + 14)
    assert.deepEqual(calendar.selectedDays, [iso(inTwoWeeks)])
    assert.strictEqual(
      calendar.months[0],
      iso(new Date(inTwoWeeks.getFullYear(), inTwoWeeks.getMonth(), 1)),
    )
    await buttons[0]!.click()
    assert.deepEqual(calendar.selectedDays, [iso(now)])
    await a11yAudit()
  })
})
