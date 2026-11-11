import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { PowerCalendarHarness } from '@ember-joinery/power-calendar/test-support'
import PowerCalendarRangeDemo from 'docs-app/examples/power-calendar-range-demo'

module('Example | power-calendar-range-demo', function (hooks) {
  setupRenderingTest(hooks)

  test('a stay is its first night to its last', async function (assert) {
    await render(<template><PowerCalendarRangeDemo /></template>)
    const stay = new PowerCalendarHarness('stay')

    assert.strictEqual(stay.kind, 'range')
    assert.strictEqual(stay.label, 'Stay')
    assert.deepEqual(stay.selected, [
      '2026-11-12',
      '2026-11-13',
      '2026-11-14',
      '2026-11-15',
      '2026-11-16',
    ])
    assert.dom(stay.day('2026-11-12')).hasAttribute('data-range-start', 'true')
    assert.dom(stay.day('2026-11-14')).hasAttribute('data-range-middle', 'true')
    assert.dom(stay.day('2026-11-16')).hasAttribute('data-range-end', 'true')

    await stay.selectRange('2026-11-24', '2026-11-20')
    assert.deepEqual(stay.selected, [
      '2026-11-20',
      '2026-11-21',
      '2026-11-22',
      '2026-11-23',
      '2026-11-24',
    ])
    await a11yAudit()
  })
})
