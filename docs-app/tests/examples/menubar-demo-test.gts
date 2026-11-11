import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { MenubarHarness, pressKey } from '@ember-joinery/test-support'
import MenubarDemo from 'docs-app/examples/menubar-demo'

module('Example | menubar-demo', function (hooks) {
  setupRenderingTest(hooks)

  test('four menus; the arrows move between them while one is open', async function (assert) {
    await render(<template><MenubarDemo /></template>)
    const menubar = new MenubarHarness()
    assert.deepEqual(menubar.menus, ['File', 'Edit', 'View', 'Profiles'])
    const file = menubar.menu('File')
    await file.openWithKeyboard()
    assert.deepEqual(file.items, [
      'New Tab',
      'New Window',
      'New Incognito Window',
      'Share',
      'Print...',
    ])
    assert.strictEqual(file.shortcut('New Tab'), '⌘T')
    assert.true(file.isDisabled('New Incognito Window'))
    assert.strictEqual(file.highlighted, 'New Tab')
    await a11yAudit()

    const share = file.sub('Share')
    await share.open()
    assert.deepEqual(share.items, ['Email link', 'Messages', 'Notes'])
    await menubar.pressEscape()

    await file.openWithKeyboard()
    await pressKey('ArrowRight')
    const edit = menubar.menu('Edit')
    assert.strictEqual(menubar.openMenu, 'Edit')
    assert.deepEqual(edit.items, ['Undo', 'Redo', 'Find', 'Cut', 'Copy', 'Paste'])
    await edit.sub('Find').openWithKeyboard()
    assert.strictEqual(edit.sub('Find').highlighted, 'Search the web')
    assert.deepEqual(edit.sub('Find').items, [
      'Search the web',
      'Find...',
      'Find Next',
      'Find Previous',
    ])
    await pressKey('ArrowRight')
    const view = menubar.menu('View')
    assert.strictEqual(menubar.openMenu, 'View', 'ArrowRight from the submenu’s item')
    assert.false(view.isChecked('Bookmarks Bar'))
    assert.true(view.isChecked('Full URLs'))
    assert.true(view.isDisabled('Force Reload'))
    await a11yAudit()

    await menubar.menu('Profiles').hoverTrigger()
    const profiles = menubar.menu('Profiles')
    assert.strictEqual(menubar.openMenu, 'Profiles', 'the pointer moves to another menu')
    assert.true(profiles.isChecked('Benoit'))
    await a11yAudit()
  })
})
