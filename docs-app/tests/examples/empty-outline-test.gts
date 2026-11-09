import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ButtonHarness, EmptyHarness } from '@ember-joinery/test-support'
import EmptyOutline from 'docs-app/examples/empty-outline'

module('Example | empty-outline', function (hooks) {
  setupRenderingTest(hooks)

  test('a dashed outline, from the border class', async function (assert) {
    await render(<template><EmptyOutline /></template>)
    const empty = new EmptyHarness()
    assert.strictEqual(empty.title, 'Cloud Storage Empty')
    const style = getComputedStyle(empty.element)
    assert.strictEqual(style.borderTopWidth, '1px', 'border')
    assert.strictEqual(style.borderTopStyle, 'dashed', 'border-dashed')
    const upload = empty.find(ButtonHarness)
    assert.strictEqual(upload.label, 'Upload Files')
    assert.strictEqual(upload.variant, 'outline')
    assert.strictEqual(upload.size, 'sm')
    await a11yAudit()
  })
})
