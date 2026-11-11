import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { focus, render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { MenubarHarness, pressKey } from '@ember-joinery/test-support'
import MenubarHeadless from 'docs-app/examples/menubar-headless'

module('Example | menubar-headless', function (hooks) {
  setupRenderingTest(hooks)

  test('the headless menubar: the arrows between triggers, and between menus', async function (assert) {
    await render(<template><MenubarHeadless /></template>)
    const menubar = new MenubarHarness()
    assert.deepEqual(menubar.menus, ['File', 'Edit'])
    await focus(menubar.trigger('File'))
    await pressKey('ArrowRight')
    assert.strictEqual(menubar.focusedTrigger, 'Edit')
    await menubar.menu('File').openWithKeyboard()
    assert.deepEqual(menubar.menu('File').items, ['New Tab', 'New Window', 'Share ›'])
    await a11yAudit()
    await pressKey('ArrowRight')
    assert.strictEqual(menubar.openMenu, 'Edit')
    await menubar.menu('Edit').select('Undo')
    assert.false(menubar.isOpen)
    await a11yAudit()
  })
})
