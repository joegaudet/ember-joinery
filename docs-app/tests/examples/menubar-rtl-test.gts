import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { MenubarHarness, pressKey } from '@ember-joinery/test-support'
import MenubarRtl from 'docs-app/examples/menubar-rtl'

module('Example | menubar-rtl', function (hooks) {
  setupRenderingTest(hooks)

  test('in Arabic, right to left: ArrowLeft opens the next menu, and submenus open to the left', async function (assert) {
    await render(
      <template>
        <div dir="rtl"><MenubarRtl /></div>
      </template>,
    )
    const menubar = new MenubarHarness()
    assert.deepEqual(menubar.menus, ['ملف', 'تعديل', 'عرض', 'الملفات الشخصية'])
    const file = menubar.menu('ملف')
    await file.openWithKeyboard()
    assert.strictEqual(file.highlighted, 'علامة تبويب جديدة')
    const share = file.sub('مشاركة')
    await share.openWithKeyboard()
    assert.true(share.isOpen)
    assert.strictEqual(share.side, 'left')
    await a11yAudit()
    await pressKey('ArrowRight')
    assert.false(share.isOpen, 'ArrowRight closes the submenu')
    await pressKey('ArrowLeft')
    await pressKey('ArrowLeft')
    assert.strictEqual(menubar.openMenu, 'تعديل', 'ArrowLeft moves on to the next menu')
    await pressKey('ArrowLeft')
    await pressKey('ArrowLeft')
    const profiles = menubar.menu('الملفات الشخصية')
    assert.strictEqual(menubar.openMenu, 'الملفات الشخصية')
    assert.true(profiles.isChecked('Benoit'))
    await profiles.select('Andy')
    await profiles.open()
    assert.true(profiles.isChecked('Andy'))
    await a11yAudit()
  })
})
