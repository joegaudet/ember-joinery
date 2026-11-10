import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { IconHarness, MenubarHarness } from '@ember-joinery/test-support'
import MenubarIcons from 'docs-app/examples/menubar-icons'

module('Example | menubar-icons', function (hooks) {
  setupRenderingTest(hooks)

  test('items with icons, and a destructive one', async function (assert) {
    await render(<template><MenubarIcons /></template>)
    const menubar = new MenubarHarness()
    const file = menubar.menu('File')
    await file.open()
    assert.deepEqual(file.items, ['New File', 'Open Folder', 'Save'])
    assert.strictEqual(file.shortcut('Save'), '⌘S')
    const icon = new IconHarness({ within: file.item('New File') })
    assert.true(icon.isDecorative, 'its icon is hidden from assistive technology')
    await a11yAudit()

    const more = menubar.menu('More')
    await more.hoverTrigger()
    assert.deepEqual(more.items, ['Settings', 'Help', 'Delete'])
    assert.strictEqual(more.variant('Delete'), 'destructive')
    await a11yAudit()
  })
})
