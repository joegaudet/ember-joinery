import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DrawerHarness } from '@ember-joinery/test-support'
import DrawerNested from 'docs-app/examples/drawer-nested'

module('Example | drawer-nested', function (hooks) {
  setupRenderingTest(hooks)

  test('a second drawer steps the first back, and Back brings it forward', async function (assert) {
    await render(<template><DrawerNested /></template>)
    const [outer] = DrawerHarness.findAll()
    await outer!.open()
    const inner = outer!.find(DrawerHarness)
    assert.dom(inner.trigger).hasText('Open the second drawer')
    await inner.open()
    assert.strictEqual(inner.label, 'The second drawer')
    const scale = new DOMMatrixReadOnly(outer!.content!.style.transform).a
    assert.ok(scale < 1, 'the first is scaled back')
    await a11yAudit()

    await inner.pressEscape()
    assert.false(inner.isOpen, 'Escape closes the second')
    assert.true(outer!.isOpen, 'and leaves the first open')
    assert.dom(inner.trigger).isFocused('back on its trigger')
    await a11yAudit()
  })
})
