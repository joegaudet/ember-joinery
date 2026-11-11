import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ResizableHarness } from '@ember-joinery/test-support'
import ResizableVertical from 'docs-app/examples/resizable-vertical'

module('Example | resizable-vertical', function (hooks) {
  setupRenderingTest(hooks)

  test('a header above the content, resized with Up and Down', async function (assert) {
    await render(<template><ResizableVertical /></template>)
    const layout = new ResizableHarness()
    assert.strictEqual(layout.orientation, 'vertical')
    assert.deepEqual(layout.sizes, [25, 75])
    assert.ok(layout.element.offsetHeight >= 200, 'at least min-h-[200px]')
    assert.dom(layout.handle(0)).hasAttribute('aria-orientation', 'horizontal')
    assert.dom('.jn-resizable-handle-icon', layout.handle(0)).doesNotExist('a plain line')

    await layout.press(0, 'ArrowDown')
    assert.deepEqual(layout.sizes, [30, 70])
    // A tenth of the height the panels share (the group's, less the 1px handle).
    await layout.drag(0, -(layout.element.clientHeight - 1) / 10)
    assert.deepEqual(layout.sizes.map(Math.round), [20, 80], 'a drag up a tenth')
    await a11yAudit()
  })
})
