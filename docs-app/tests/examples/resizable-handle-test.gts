import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ResizableHarness } from '@ember-joinery/test-support'
import ResizableHandleExample from 'docs-app/examples/resizable-handle'

module('Example | resizable-handle', function (hooks) {
  setupRenderingTest(hooks)

  test('a sidebar and the content, with a grip on the handle', async function (assert) {
    await render(<template><ResizableHandleExample /></template>)
    const layout = new ResizableHarness()
    assert.deepEqual(layout.sizes, [25, 75])
    const grip = layout.handle(0).querySelector('.jn-resizable-handle-icon')!
    assert.strictEqual(getComputedStyle(grip).height, '24px', 'the grip, h-6')

    await layout.press(0, 'End')
    assert.deepEqual(layout.sizes, [100, 0], 'End: the sidebar takes all it can')
    await layout.press(0, 'Home')
    assert.deepEqual(layout.sizes, [0, 100])
    await layout.doubleClick(0)
    assert.deepEqual(layout.sizes, [25, 75], 'a double-click restores the default')
    await a11yAudit()
  })
})
