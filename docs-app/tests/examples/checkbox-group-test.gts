import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { CheckboxHarness, FieldSetHarness } from '@ember-joinery/test-support'
import CheckboxGroup from 'docs-app/examples/checkbox-group'

module('Example | checkbox-group', function (hooks) {
  setupRenderingTest(hooks)

  test('a list of checkboxes under a legend, two checked', async function (assert) {
    await render(<template><CheckboxGroup /></template>)
    const set = new FieldSetHarness()
    const boxes = set.findAll(CheckboxHarness)

    assert.strictEqual(set.legend, 'Show these items on the desktop:')
    assert.strictEqual(set.legendVariant, 'label')
    assert.strictEqual(set.description, 'Select the items you want to show on the desktop.')
    assert.deepEqual(
      boxes.map(box => box.label),
      ['Hard disks', 'External disks', 'CDs, DVDs, and iPods', 'Connected servers'],
    )
    assert.deepEqual(
      boxes.map(box => box.isChecked),
      [true, true, false, false],
    )
    await boxes[3]!.check()
    assert.true(boxes[3]!.isChecked)
    await a11yAudit()
  })
})
