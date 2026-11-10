import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ButtonHarness, DatePickerHarness } from '@ember-joinery/test-support'
import DatePickerDemo from 'docs-app/examples/date-picker-demo'

const caption = (date: Date) =>
  new Intl.DateTimeFormat('en-US', { month: 'long', year: 'numeric' }).format(date)
const monthName = (date: Date) => new Intl.DateTimeFormat('en-US', { month: 'long' }).format(date)

module('Example | date-picker-demo', function (hooks) {
  setupRenderingTest(hooks)

  test("an outline button opens a calendar at its start; the day picked shows as date-fns' PPP", async function (assert) {
    await render(<template><DatePickerDemo /></template>)
    const picker = new DatePickerHarness()
    const button = new ButtonHarness()
    assert.strictEqual(button.variant, 'outline')
    assert.strictEqual(picker.text, 'Pick a date')
    assert.true(picker.isEmpty, 'data-empty greys the placeholder')
    await a11yAudit()

    await picker.open()
    const today = new Date()
    assert.strictEqual(picker.align, 'start')
    assert.strictEqual(picker.calendar.caption, caption(today), "today's month")

    const year = today.getFullYear()
    const month = today.getMonth()
    const name = monthName(today)
    await picker.pick(new Date(year, month, 1))
    assert.strictEqual(picker.text, `${name} 1st, ${year}`)
    assert.false(picker.isEmpty)
    assert.true(picker.isOpen, 'it stays open, as upstream’s does')
    await picker.pick(new Date(year, month, 22))
    assert.strictEqual(picker.text, `${name} 22nd, ${year}`)
    await picker.pick(new Date(year, month, 13))
    assert.strictEqual(picker.text, `${name} 13th, ${year}`)
    await picker.pick(new Date(year, month, 3))
    assert.strictEqual(picker.text, `${name} 3rd, ${year}`)
    await a11yAudit()

    await picker.pressEscape()
    assert.false(picker.isOpen)
    assert.true(button.isFocused)
  })
})
