import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { PowerCalendarHarness } from '@ember-joinery/power-calendar/test-support'
import PowerCalendarMultipleDemo from 'docs-app/examples/power-calendar-multiple-demo'

module('Example | power-calendar-multiple-demo', function (hooks) {
  setupRenderingTest(hooks)

  test('up to three days, each press adding or removing one', async function (assert) {
    await render(<template><PowerCalendarMultipleDemo /></template>)
    const days = new PowerCalendarHarness('days')
    const count = () =>
      document.querySelector('p[aria-live]')!.textContent!.replace(/\s+/g, ' ').trim()

    assert.strictEqual(days.kind, 'multiple')
    assert.deepEqual(days.selected, ['2026-03-03', '2026-03-10'])
    assert.strictEqual(count(), '2 of 3 days chosen')

    await days.select('2026-03-17')
    assert.strictEqual(count(), '3 of 3 days chosen')
    assert.true(days.isDayDisabled('2026-03-24'), 'no fourth')

    await days.select('2026-03-03')
    assert.deepEqual(days.selected, ['2026-03-10', '2026-03-17'])
    assert.false(days.isDayDisabled('2026-03-24'))
    await a11yAudit()
  })
})
