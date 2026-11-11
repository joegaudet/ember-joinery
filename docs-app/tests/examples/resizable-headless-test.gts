import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { click, render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ResizableHarness } from '@ember-joinery/test-support'
import ResizableHeadless from 'docs-app/examples/resizable-headless'

module('Example | resizable-headless', function (hooks) {
  setupRenderingTest(hooks)

  test('it opens with the saved layout, saves each change, and the file list collapses', async function (assert) {
    await render(<template><ResizableHeadless /></template>)
    const layout = new ResizableHarness()
    assert.deepEqual(layout.sizes, [30, 70], 'the saved layout')
    assert.dom('output').hasText('30% · 70%')

    await layout.press(0, 'ArrowRight')
    assert.dom('output').hasText('35% · 65%', 'saved')

    await click(layout.panel('files').querySelector('button')!)
    assert.true(layout.isCollapsed('files'))
    assert.deepEqual(layout.sizes, [0, 100])
    assert.dom('output').hasText('0% · 100%')

    await layout.press(0, 'Enter')
    assert.false(layout.isCollapsed('files'), 'Enter on the handle opens it again')
    assert.deepEqual(layout.sizes, [35, 65], 'to the size it had')
    await a11yAudit()
  })
})
