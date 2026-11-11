import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { FieldGroupHarness, InputHarness } from '@ember-joinery/test-support'
import InputGrid from 'docs-app/examples/input-grid'

module('Example | input-grid', function (hooks) {
  setupRenderingTest(hooks)

  test('first and last name side by side', async function (assert) {
    await render(<template><InputGrid /></template>)
    const [first, last] = new FieldGroupHarness().fields

    assert.strictEqual(first!.label, 'First Name')
    assert.strictEqual(last!.label, 'Last Name')
    const firstBox = first!.element.getBoundingClientRect()
    const lastBox = last!.element.getBoundingClientRect()
    assert.strictEqual(Math.round(firstBox.top), Math.round(lastBox.top), 'on one row')
    assert.true(lastBox.left > firstBox.right)
    await last!.find(InputHarness).fillIn('Lovelace')
    assert.strictEqual(last!.find(InputHarness).value, 'Lovelace')
    await a11yAudit()
  })
})
