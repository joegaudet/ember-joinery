import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { FieldHarness, InputGroupHarness } from '@ember-joinery/test-support'
import InputGroupInlineStart from 'docs-app/examples/input-group-inline-start'

module('Example | input-group-inline-start', function (hooks) {
  setupRenderingTest(hooks)

  test('a search icon at the start of a labelled input', async function (assert) {
    await render(<template><InputGroupInlineStart /></template>)
    const field = new FieldHarness()
    const group = field.find(InputGroupHarness)
    assert.strictEqual(group.label, 'Input', 'the FieldLabel names the input')
    assert.strictEqual(field.description, 'Icon positioned at the start.')
    assert.strictEqual(group.placeholder, 'Search...')
    assert.deepEqual(group.aligns, ['inline-start'])
    const icon = group.icons[0]!.getBoundingClientRect()
    const input = group.control.getBoundingClientRect()
    assert.ok(icon.right <= input.left, 'the icon comes before the input')
    assert.strictEqual(getComputedStyle(field.element).maxWidth, '384px', 'max-w-sm')

    await group.fillIn('shadcn')
    assert.strictEqual(group.value, 'shadcn')
    await a11yAudit()
  })
})
