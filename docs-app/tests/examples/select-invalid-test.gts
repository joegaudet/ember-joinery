import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { FieldHarness, SelectHarness } from '@ember-joinery/test-support'
import SelectInvalid from 'docs-app/examples/select-invalid'

module('Example | select-invalid', function (hooks) {
  setupRenderingTest(hooks)

  test('the field and its trigger show the error', async function (assert) {
    await render(<template><SelectInvalid /></template>)
    const field = new FieldHarness()
    assert.true(field.isInvalid)
    assert.strictEqual(field.label, 'Fruit')
    assert.strictEqual(field.error, 'Please select a fruit.')

    const select = new SelectHarness()
    assert.true(select.isInvalid)
    assert.strictEqual(select.label, 'Fruit', 'named by the field’s label')
    assert.true(select.isPlaceholder)
    assert.strictEqual(
      getComputedStyle(select.trigger).borderTopColor,
      getComputedStyle(field.element).color,
      'the trigger’s border takes the field’s destructive colour',
    )
    await a11yAudit()

    await select.open()
    assert.deepEqual(select.optionTexts, ['Apple', 'Banana', 'Blueberry'])
    await select.pressOption('apple')
    assert.strictEqual(select.valueText, 'Apple')
    await a11yAudit()
  })
})
