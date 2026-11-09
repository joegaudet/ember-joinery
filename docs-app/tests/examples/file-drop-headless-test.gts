import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { FileDropHarness, tab } from '@ember-joinery/test-support'
import FileDropHeadless from 'docs-app/examples/file-drop-headless'

const cat = new File(['cat'], 'cat.png', { type: 'image/png' })

module('Example | file-drop-headless', function (hooks) {
  setupRenderingTest(hooks)

  test('a dashed zone of its own, reached by Tab, that takes images', async function (assert) {
    await render(<template><FileDropHeadless /></template>)
    const zone = new FileDropHarness()

    assert.strictEqual(zone.text, 'Drop images here, or click to choose')
    await tab()
    assert.true(zone.isFocused, 'Tab reaches its hidden input')
    await zone.drag([cat])
    assert.true(zone.isDragging)
    assert.strictEqual(getComputedStyle(zone.element).borderTopStyle, 'solid')
    await zone.drop([cat])
    assert.dom(zone.element.parentElement!).containsText('Picked: cat.png')
    await a11yAudit()
  })
})
