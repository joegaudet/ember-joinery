import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import { PowerCalendarHarness } from '@ember-joinery/power-calendar/test-support'
import PowerCalendarRtl from 'docs-app/examples/power-calendar-rtl'

module('Example | power-calendar-rtl', function (hooks) {
  setupRenderingTest(hooks)

  test('in Arabic, right to left, the arrow keys flip', async function (assert) {
    // The guide shows it with dir="rtl" on the preview; a provider does the same here.
    await render(
      <template>
        <DirectionProvider @dir="rtl"><PowerCalendarRtl /></DirectionProvider>
      </template>,
    )
    const calendar = new PowerCalendarHarness('rtl')

    assert.strictEqual(calendar.label, 'اختر تاريخًا')
    assert.dom(calendar.previousButton).hasAttribute('aria-label', 'الشهر السابق')
    assert.dom(calendar.nextButton).hasAttribute('aria-label', 'الشهر التالي')
    assert.strictEqual(
      calendar.month,
      new Intl.DateTimeFormat('ar', { month: 'long', year: 'numeric' }).format(
        new Date(2026, 2, 4),
      ),
    )
    assert.true(
      calendar.previousButton.getBoundingClientRect().left >
        calendar.nextButton.getBoundingClientRect().left,
      'the previous month is on the right',
    )

    await calendar.focusDay('2026-03-04')
    await calendar.pressKey('ArrowLeft')
    assert.strictEqual(calendar.focusedDay, '2026-03-05', 'left moves forward')
    await calendar.select('2026-03-05')
    assert.deepEqual(calendar.selected, ['2026-03-05'])
    await a11yAudit()
  })
})
