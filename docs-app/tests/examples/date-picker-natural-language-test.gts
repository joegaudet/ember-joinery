import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DatePickerHarness, FieldHarness, InputGroupHarness } from '@ember-joinery/test-support'
import DatePickerNaturalLanguage from 'docs-app/examples/date-picker-natural-language'

const written = (date: Date) =>
  date.toLocaleDateString('en-US', { day: '2-digit', month: 'long', year: 'numeric' })

function inDays(days: number): Date {
  const today = new Date()
  return new Date(today.getFullYear(), today.getMonth(), today.getDate() + days)
}

module('Example | date-picker-natural-language', function (hooks) {
  setupRenderingTest(hooks)

  test('words become a date: "In 2 days", "tomorrow", and a pick writes the date out', async function (assert) {
    await render(<template><DatePickerNaturalLanguage /></template>)
    const field = new FieldHarness()
    const input = new InputGroupHarness()
    const picker = new DatePickerHarness()
    assert.strictEqual(field.label, 'Schedule Date')
    assert.strictEqual(input.value, 'In 2 days')
    assert.strictEqual(input.placeholder, 'Tomorrow or next week')
    assert.strictEqual(field.text.includes(`published on ${written(inDays(2))}.`), true)
    await a11yAudit()

    await input.fillIn('tomorrow')
    assert.true(field.text.includes(`published on ${written(inDays(1))}.`), field.text)
    await input.fillIn('not a date')
    assert.true(
      field.text.includes(`published on ${written(inDays(1))}.`),
      'words it can’t read change nothing',
    )

    await picker.open()
    assert.true(picker.calendar.isSelected(inDays(1)))
    assert.ok(picker.calendar.yearDropdown(), 'month and year dropdowns')
    const day = inDays(10)
    await picker.pick(day)
    assert.false(picker.isOpen)
    assert.strictEqual(input.value, written(day))
    assert.true(field.text.includes(`published on ${written(day)}.`))
    await a11yAudit()
  })
})
