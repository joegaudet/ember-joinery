import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { PowerCalendarHarness } from '@ember-joinery/power-calendar/test-support'
import PowerCalendarDisabledDays from 'docs-app/examples/power-calendar-disabled-days'

module('Example | power-calendar-disabled-days', function (hooks) {
  setupRenderingTest(hooks)

  test('only weekdays from November 2nd to December 18th can be chosen', async function (assert) {
    await render(<template><PowerCalendarDisabledDays /></template>)
    const shipsOn = new PowerCalendarHarness('ships-on')

    assert.strictEqual(shipsOn.label, 'Ships on')
    assert.strictEqual(shipsOn.month, 'November 2026')
    assert.deepEqual(shipsOn.selected, ['2026-11-18'])
    assert.true(shipsOn.isDayDisabled('2026-11-01'), 'before the first day, and a Sunday')
    assert.true(shipsOn.isDayDisabled('2026-11-07'), 'a Saturday')
    assert.false(shipsOn.isDayDisabled('2026-11-02'))
    assert.true(shipsOn.isPreviousDisabled, 'October is out of bounds')

    await shipsOn.select('2026-12-18')
    assert.deepEqual(shipsOn.selected, ['2026-12-18'])
    assert.true(shipsOn.isDayDisabled('2026-12-21'), 'after the last day')
    assert.true(shipsOn.isNextDisabled)

    await shipsOn.select('2026-12-18')
    assert.deepEqual(shipsOn.selected, ['2026-12-18'], '@required keeps it')
    await a11yAudit()
  })
})
