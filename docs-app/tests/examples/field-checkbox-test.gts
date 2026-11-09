import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import {
  CheckboxHarness,
  FieldGroupHarness,
  FieldHarness,
  FieldSetHarness,
  LabelHarness,
} from '@ember-joinery/test-support'
import FieldCheckbox from 'docs-app/examples/field-checkbox'

module('Example | field-checkbox', function (hooks) {
  setupRenderingTest(hooks)

  test('a set of desktop items, a separator, then a described checkbox', async function (assert) {
    await render(<template><FieldCheckbox /></template>)
    const group = new FieldGroupHarness()
    const items = new FieldSetHarness()

    assert.strictEqual(items.legend, 'Show these items on the desktop')
    assert.strictEqual(items.legendVariant, 'label')
    assert.strictEqual(items.description, 'Select the items you want to show on the desktop.')
    assert.deepEqual(
      items.fields.map(field => field.label),
      ['Hard disks', 'External disks', 'CDs, DVDs, and iPods', 'Connected servers'],
    )
    assert.deepEqual(
      items.findAll(CheckboxHarness).map(box => box.isChecked),
      [false, false, false, false],
    )
    assert.deepEqual(group.separators, [''])

    const sync = group.fields.at(-1)!
    assert.strictEqual(sync.label, 'Sync Desktop & Documents folders')
    assert.strictEqual(
      sync.description,
      'Your Desktop & Documents folders are being synced with iCloud Drive. You can access them from other devices.',
    )
    assert.true(sync.find(CheckboxHarness).isChecked)
    assert.strictEqual(
      getComputedStyle(sync.element).alignItems,
      'flex-start',
      'beside a description, the checkbox sits at the top',
    )
    await a11yAudit()
  })

  test('a press on a label checks its box', async function (assert) {
    await render(<template><FieldCheckbox /></template>)
    const disks = new FieldHarness({ index: 0 })
    const label = disks.find(LabelHarness)
    await label.click()
    assert.true(disks.find(CheckboxHarness).isChecked)
    assert.strictEqual(getComputedStyle(label.element).fontWeight, '400', 'font-normal')
    await a11yAudit()
  })
})
