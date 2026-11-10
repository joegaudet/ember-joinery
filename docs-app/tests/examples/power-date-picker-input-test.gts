import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DatePickerHarness } from '@ember-joinery/power-calendar/test-support'
import PowerDatePickerInput from 'docs-app/examples/power-date-picker-input'

module('Example | power-date-picker-input', function (hooks) {
  setupRenderingTest(hooks)

  test('type the date, or choose it from the calendar button', async function (assert) {
    await render(<template><PowerDatePickerInput /></template>)
    const subscription = new DatePickerHarness('subscription')

    assert.strictEqual(subscription.label, 'Subscription Date')
    assert.strictEqual(subscription.text, 'June 01, 2025')
    assert.strictEqual(subscription.triggerLabel, 'Select date')

    await subscription.typeDate('July 4, 2025')
    assert.strictEqual(subscription.text, 'July 04, 2025', 'read, then written back')

    await subscription.pressKeyInInput('ArrowDown')
    assert.true(subscription.isOpen, 'ArrowDown opens the calendar')
    assert.strictEqual(subscription.calendar.month, 'July 2025')
    await subscription.calendar.select('2025-07-15')
    assert.strictEqual(subscription.text, 'July 15, 2025')
    assert.dom(subscription.input).isFocused()

    await subscription.open()
    assert.strictEqual(subscription.calendar.focusedDay, '2025-07-15')
    await a11yAudit()
  })
})
