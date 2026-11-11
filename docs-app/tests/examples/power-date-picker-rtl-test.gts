import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import { DatePickerHarness } from '@ember-joinery/power-calendar/test-support'
import PowerDatePickerRtl from 'docs-app/examples/power-date-picker-rtl'

module('Example | power-date-picker-rtl', function (hooks) {
  setupRenderingTest(hooks)

  test('in Arabic, right to left', async function (assert) {
    // The guide shows it with dir="rtl" on the preview; a provider does the same here.
    await render(
      <template>
        <DirectionProvider @dir="rtl"><PowerDatePickerRtl /></DirectionProvider>
      </template>,
    )
    const picker = new DatePickerHarness('rtl')
    assert.strictEqual(picker.text, 'اختر تاريخًا')
    assert.strictEqual(picker.label, 'اختر تاريخًا', 'its placeholder names it')

    const button = picker.trigger.getBoundingClientRect()
    const chevron = picker.trigger.querySelector('svg')!.getBoundingClientRect()
    assert.true(chevron.left < button.left + button.width / 2, 'the chevron is on the left')

    await picker.open()
    const calendar = picker.calendar
    assert.strictEqual(calendar.label, 'اختر تاريخًا')
    const today = calendar.focusedDay!
    await calendar.pressKey('ArrowLeft')
    assert.notEqual(calendar.focusedDay, today)
    await calendar.select(calendar.focusedDay!)
    assert.false(picker.isEmpty)
    await a11yAudit()
  })
})
