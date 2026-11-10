import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DatePickerHarness, FieldHarness } from '@ember-joinery/test-support'
import DatePickerBasic from 'docs-app/examples/date-picker-basic'

const monthName = (date: Date) => new Intl.DateTimeFormat('en-US', { month: 'long' }).format(date)

module('Example | date-picker-basic', function (hooks) {
  setupRenderingTest(hooks)

  test('a labelled field whose button picks a day', async function (assert) {
    await render(<template><DatePickerBasic /></template>)
    const field = new FieldHarness()
    const picker = new DatePickerHarness()
    assert.strictEqual(field.label, 'Date')
    assert.strictEqual(field.labelElement?.getAttribute('for'), picker.trigger.id)
    assert.strictEqual(picker.text, 'Pick a date')
    await a11yAudit()

    const today = new Date()
    const day = new Date(today.getFullYear(), today.getMonth(), 2)
    await picker.pick(day)
    assert.strictEqual(picker.text, `${monthName(day)} 2nd, ${day.getFullYear()}`)
    assert.deepEqual(picker.calendar.selected, [day])
    assert.strictEqual(picker.align, 'start')
    await a11yAudit()
  })
})
