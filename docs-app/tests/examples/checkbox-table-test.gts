import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { CheckboxHarness, TableHarness } from '@ember-joinery/test-support'
import CheckboxTable from 'docs-app/examples/checkbox-table'

module('Example | checkbox-table', function (hooks) {
  setupRenderingTest(hooks)

  test('a checkbox on each row, and one in the header that checks them all', async function (assert) {
    await render(<template><CheckboxTable /></template>)
    const people = new TableHarness()
    const all = new CheckboxHarness('select-all')
    const rows = ['1', '2', '3', '4'].map(id => new CheckboxHarness(`row-${id}`))
    const checked = () => rows.map(row => row.isChecked)
    const selected = () => people.rowElements.map(row => row.dataset['state'] === 'selected')

    assert.deepEqual(people.columns, ['', 'Name', 'Email', 'Role'])
    assert.deepEqual(people.rows[1], [
      '',
      'Marcus Rodriguez',
      'marcus.rodriguez@example.com',
      'User',
    ])
    assert.strictEqual(all.label, 'Select all rows')
    assert.strictEqual(rows[0]!.label, 'Select Sarah Chen')
    assert.deepEqual(checked(), [true, false, false, false], 'Sarah Chen starts selected')
    assert.deepEqual(selected(), [true, false, false, false], 'and her row says so')
    assert.false(all.isChecked)
    assert.notStrictEqual(
      getComputedStyle(people.row(0)).backgroundColor,
      getComputedStyle(people.row(1)).backgroundColor,
      'a selected row is shaded (data-[state=selected]:bg-muted)',
    )

    await all.check()
    assert.deepEqual(checked(), [true, true, true, true], 'the header checks every row')
    assert.deepEqual(selected(), [true, true, true, true])

    await rows[2]!.uncheck()
    assert.false(all.isChecked, 'one unchecked row unchecks the header')
    assert.deepEqual(checked(), [true, true, false, true])

    await rows[2]!.check()
    assert.true(all.isChecked, 'and checking it again checks the header')

    await all.uncheck()
    assert.deepEqual(checked(), [false, false, false, false], 'the header unchecks every row')
    assert.deepEqual(selected(), [false, false, false, false])
    await a11yAudit()
  })
})
