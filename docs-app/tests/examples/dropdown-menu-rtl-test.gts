import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DropdownMenuHarness, pressKey } from '@ember-joinery/test-support'
import DropdownMenuRtl from 'docs-app/examples/dropdown-menu-rtl'

module('Example | dropdown-menu-rtl', function (hooks) {
  setupRenderingTest(hooks)

  test('in Arabic, right to left: submenus open to the left, by ArrowLeft', async function (assert) {
    await render(
      <template>
        <div dir="rtl"><DropdownMenuRtl /></div>
      </template>,
    )
    const menu = new DropdownMenuHarness()
    await menu.openWithKeyboard()
    assert.deepEqual(menu.labels, ['الفريق', 'عرض', 'الموضع'])
    assert.strictEqual(menu.highlighted, 'الحساب')
    await pressKey('ArrowLeft')
    const account = menu.sub('الحساب')
    assert.true(account.isOpen)
    assert.strictEqual(account.side, 'left')
    assert.deepEqual(account.items, ['الملف الشخصي', 'الفوترة', 'الإعدادات'])
    await pressKey('ArrowRight')
    assert.false(account.isOpen)
    assert.true(menu.isChecked('شريط الحالة'))
    assert.true(menu.isChecked('أسفل'))
    assert.strictEqual(menu.variant('تسجيل الخروج'), 'destructive')
    await a11yAudit()
  })
})
