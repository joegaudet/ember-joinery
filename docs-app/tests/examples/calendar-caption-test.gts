import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { CalendarHarness } from '@ember-joinery/test-support'
import CalendarCaption from 'docs-app/examples/calendar-caption'

module('Example | calendar-caption', function (hooks) {
  setupRenderingTest(hooks)

  test('the month and year dropdowns pick the month shown', async function (assert) {
    await render(<template><CalendarCaption /></template>)
    const calendar = new CalendarHarness()
    const year = new Date().getFullYear()
    assert.strictEqual(calendar.monthOptions().length, 12)
    assert.strictEqual(calendar.yearOptions()[0], String(year - 100))
    assert.strictEqual(calendar.yearOptions().at(-1), String(year))
    await calendar.chooseMonth('Jun')
    await calendar.chooseYear(2000)
    assert.strictEqual(calendar.caption, 'June 2000')
    await calendar.select('2000-06-15')
    assert.deepEqual(calendar.selectedDays, ['2000-06-15'])
    await a11yAudit()
  })
})
