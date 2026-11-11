import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { MenubarHarness, pressKey } from '@ember-joinery/test-support'
import MenubarSubmenu from 'docs-app/examples/menubar-submenu'

module('Example | menubar-submenu', function (hooks) {
  setupRenderingTest(hooks)

  test('a submenu in each menu, opened by the arrow pointing into it', async function (assert) {
    await render(<template><MenubarSubmenu /></template>)
    const menubar = new MenubarHarness()
    const file = menubar.menu('File')
    await file.openWithKeyboard()
    assert.deepEqual(file.items, ['Share', 'Print...'])
    assert.strictEqual(file.highlighted, 'Share')
    await pressKey('ArrowRight')
    const share = file.sub('Share')
    assert.true(share.isOpen)
    assert.deepEqual(share.items, ['Email link', 'Messages', 'Notes'])
    assert.strictEqual(share.side, 'right')
    await a11yAudit()
    await pressKey('ArrowLeft')
    assert.false(share.isOpen)
    assert.strictEqual(menubar.openMenu, 'File')

    await pressKey('ArrowRight')
    await pressKey('ArrowRight')
    assert.strictEqual(menubar.openMenu, 'Edit', 'ArrowRight in the submenu opens the next menu')
    const edit = menubar.menu('Edit')
    await edit.sub('Find').open()
    assert.deepEqual(edit.sub('Find').items, ['Find...', 'Find Next', 'Find Previous'])
    await a11yAudit()
  })
})
