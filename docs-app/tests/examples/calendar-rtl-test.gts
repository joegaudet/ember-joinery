import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import { CalendarHarness } from '@ember-joinery/test-support'
import CalendarRtl from 'docs-app/examples/calendar-rtl'

module('Example | calendar-rtl', function (hooks) {
  setupRenderingTest(hooks)

  test('in Arabic, right to left, with the arrow keys flipped', async function (assert) {
    // The guide shows it with dir="rtl" on the preview; a provider does the same here.
    await render(
      <template>
        <DirectionProvider @dir="rtl"><CalendarRtl /></DirectionProvider>
      </template>,
    )
    const calendar = new CalendarHarness()
    const today = new Date()
    const month = new Intl.DateTimeFormat('ar-SA-u-ca-gregory-nu-latn', { month: 'long' }).format(
      today,
    )
    assert.true(calendar.caption.includes(month), 'the month in Arabic')
    assert.true(calendar.isSelected(today))
    await calendar.focus(today)
    await calendar.press('ArrowLeft')
    const next = new Date(today.getFullYear(), today.getMonth(), today.getDate() + 1)
    const iso = `${next.getFullYear()}-${String(next.getMonth() + 1).padStart(2, '0')}-${String(next.getDate()).padStart(2, '0')}`
    assert.strictEqual(calendar.focusedDay, iso, 'left is the next day, right to left')
    await a11yAudit()
  })
})
