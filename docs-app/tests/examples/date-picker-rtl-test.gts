import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DatePickerHarness, pressKey } from '@ember-joinery/test-support'
import DatePickerRtl from 'docs-app/examples/date-picker-rtl'

const arabic = (date: Date, options: Intl.DateTimeFormatOptions) =>
  new Intl.DateTimeFormat('ar-SA-u-ca-gregory-nu-latn', options).format(date)

module('Example | date-picker-rtl', function (hooks) {
  setupRenderingTest(hooks)

  test('in Arabic, right to left: the calendar starts on the right and the arrow keys flip', async function (assert) {
    await render(<template><DatePickerRtl /></template>)
    const picker = new DatePickerHarness()
    assert.strictEqual(picker.text, 'اختر تاريخًا')
    assert.dom(picker.trigger).hasAttribute('data-empty', 'true')
    assert.strictEqual(getComputedStyle(picker.trigger).direction, 'rtl')
    await a11yAudit()

    await picker.open()
    const today = new Date()
    assert.strictEqual(getComputedStyle(picker.content!).direction, 'rtl')
    assert.strictEqual(
      picker.calendar.caption,
      arabic(today, { month: 'long', year: 'numeric' }),
      'Arabic names, Latin digits',
    )

    const day = new Date(today.getFullYear(), today.getMonth(), 10)
    await picker.calendar.focus(day)
    await pressKey('ArrowLeft')
    assert.strictEqual(
      picker.calendar.focusedDay,
      `${day.getFullYear()}-${String(day.getMonth() + 1).padStart(2, '0')}-11`,
      'left is the next day',
    )

    await picker.pick(day)
    const month = arabic(day, { month: 'long' })
    assert.strictEqual(
      picker.text,
      `${month} 10, ${day.getFullYear()}`,
      "date-fns' arSA PPP: the month, then the day, a comma and the year",
    )
    assert.dom(picker.trigger).hasAttribute('data-empty', 'false')
    await a11yAudit()
  })
})
