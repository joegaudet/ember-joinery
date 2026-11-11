import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ResizableHarness } from '@ember-joinery/test-support'
import ResizableDemo from 'docs-app/examples/resizable-demo'

module('Example | resizable-demo', function (hooks) {
  setupRenderingTest(hooks)

  test('two panels side by side, the second split in two, each handle with a grip', async function (assert) {
    await render(<template><ResizableDemo /></template>)
    const [outer, inner] = ResizableHarness.findAll()
    assert.strictEqual(outer!.orientation, 'horizontal')
    assert.deepEqual(outer!.sizes, [50, 50])
    assert.strictEqual(inner!.orientation, 'vertical')
    assert.deepEqual(inner!.sizes, [25, 75])
    for (const group of [outer!, inner!]) {
      assert.dom('.jn-resizable-handle-icon', group.handle(0)).exists('withHandle')
    }

    await outer!.press(0, 'ArrowRight')
    assert.deepEqual(outer!.sizes, [55, 45])
    await inner!.press(0, 'ArrowDown')
    assert.deepEqual(inner!.sizes, [30, 70])
    assert.deepEqual(outer!.sizes, [55, 45], 'each group resizes on its own')
    await a11yAudit()
  })
})
