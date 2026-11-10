import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { FieldHarness, InputGroupHarness } from '@ember-joinery/test-support'
import InputGroupInlineEnd from 'docs-app/examples/input-group-inline-end'

module('Example | input-group-inline-end', function (hooks) {
  setupRenderingTest(hooks)

  test('an eye-off icon at the end of a labelled password input', async function (assert) {
    await render(<template><InputGroupInlineEnd /></template>)
    const field = new FieldHarness()
    const group = field.find(InputGroupHarness)
    assert.strictEqual(group.label, 'Input', 'the FieldLabel names the input')
    assert.strictEqual(field.description, 'Icon positioned at the end.')
    assert.strictEqual(group.control.type, 'password')
    assert.strictEqual(group.placeholder, 'Enter password')
    assert.deepEqual(group.aligns, ['inline-end'])
    const icon = group.icons[0]!.getBoundingClientRect()
    const input = group.control.getBoundingClientRect()
    assert.ok(input.right <= icon.left, 'the icon comes after the input')

    await group.typeIn('hunter2')
    assert.strictEqual(group.value, 'hunter2')
    await a11yAudit()
  })
})
