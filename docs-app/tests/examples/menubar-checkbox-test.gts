import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { MenubarHarness } from '@ember-joinery/test-support'
import MenubarCheckbox from 'docs-app/examples/menubar-checkbox'

module('Example | menubar-checkbox', function (hooks) {
  setupRenderingTest(hooks)

  test('checkbox items, as upstream’s: checked as they start', async function (assert) {
    await render(<template><MenubarCheckbox /></template>)
    const menubar = new MenubarHarness()
    const view = menubar.menu('View')
    await view.open()
    assert.strictEqual(view.role('Always Show Bookmarks Bar'), 'menuitemcheckbox')
    assert.false(view.isChecked('Always Show Bookmarks Bar'))
    assert.true(view.isChecked('Always Show Full URLs'))
    assert.strictEqual(view.shortcut('Reload'), '⌘R')
    assert.true(view.isDisabled('Force Reload'))
    await a11yAudit()

    const format = menubar.menu('Format')
    await format.hoverTrigger()
    assert.true(format.isOpen)
    assert.deepEqual(format.items, ['Strikethrough', 'Code', 'Superscript'])
    assert.true(format.isChecked('Strikethrough'))
    await a11yAudit()
  })
})
