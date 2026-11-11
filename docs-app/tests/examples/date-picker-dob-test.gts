import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DatePickerHarness, FieldHarness } from '@ember-joinery/test-support'
import DatePickerDob from 'docs-app/examples/date-picker-dob'

module('Example | date-picker-dob', function (hooks) {
  setupRenderingTest(hooks)

  test('month and year dropdowns go back years; a pick closes it and shows the date', async function (assert) {
    await render(<template><DatePickerDob /></template>)
    const field = new FieldHarness()
    const picker = new DatePickerHarness()
    assert.strictEqual(field.label, 'Date of birth')
    assert.strictEqual(picker.text, 'Select date')
    await a11yAudit()

    await picker.open()
    assert.ok(picker.calendar.monthDropdown(), 'a month dropdown')
    assert.ok(picker.calendar.yearDropdown(), 'a year dropdown')
    await a11yAudit()

    const birthday = new Date(1990, 4, 15)
    await picker.pick(birthday)
    assert.false(picker.isOpen, 'a pick closes it')
    assert.strictEqual(picker.text, birthday.toLocaleDateString())
    assert.dom(picker.trigger).isFocused('focus goes back to the button')

    await picker.open()
    assert.deepEqual(picker.calendar.months, ['1990-05-01'], 'it opens on the month picked')
    assert.true(picker.calendar.isSelected(birthday))
    await a11yAudit()
  })
})
