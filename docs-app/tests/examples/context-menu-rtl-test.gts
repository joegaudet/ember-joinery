import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ContextMenuHarness, pressKey } from '@ember-joinery/test-support'
import ContextMenuRtl from 'docs-app/examples/context-menu-rtl'

module('Example | context-menu-rtl', function (hooks) {
  setupRenderingTest(hooks)

  test('in Arabic, right to left, with its submenus on the left', async function (assert) {
    await render(
      <template>
        <div dir="rtl"><ContextMenuRtl /></div>
      </template>,
    )
    const menu = new ContextMenuHarness()
    await menu.open()
    assert.deepEqual(menu.items, [
      'التنقل',
      'المزيد من الأدوات',
      'إظهار الإشارات المرجعية',
      'إظهار عناوين URL الكاملة',
      'Pedro Duarte',
      'Colm Tuite',
    ])
    assert.true(menu.isChecked('إظهار الإشارات المرجعية'))
    assert.true(menu.isChecked('Pedro Duarte'))
    await pressKey('ArrowDown')
    await pressKey('ArrowLeft')
    const navigation = menu.sub('التنقل')
    assert.true(navigation.isOpen)
    assert.strictEqual(navigation.side, 'left')
    assert.deepEqual(navigation.items, ['رجوع', 'تقدم', 'إعادة تحميل'])
    assert.true(navigation.isDisabled('تقدم'))
    await a11yAudit()
    await menu.select('Colm Tuite')
    await menu.open()
    assert.true(menu.isChecked('Colm Tuite'))
    await a11yAudit()
  })
})
