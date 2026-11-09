import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import { ButtonHarness, FieldHarness, SheetHarness } from '@ember-joinery/test-support'
import SheetRtl from 'docs-app/examples/sheet-rtl'

module('Example | sheet-rtl', function (hooks) {
  setupRenderingTest(hooks)

  test('in Arabic, a profile sheet from the left', async function (assert) {
    // The guide shows it with dir="rtl" on the preview; a provider does the same here.
    await render(
      <template>
        <DirectionProvider @dir="rtl"><SheetRtl /></DirectionProvider>
      </template>,
    )
    const sheet = new SheetHarness()
    assert.dom(sheet.trigger).hasText('فتح')
    await sheet.open()
    assert.strictEqual(sheet.side, 'left')
    assert.strictEqual(sheet.label, 'تعديل الملف الشخصي')
    assert.deepEqual(
      sheet.findAll(FieldHarness).map(field => field.label),
      ['الاسم', 'اسم المستخدم'],
    )
    await a11yAudit()
    const close = sheet
      .findAll(ButtonHarness)
      .find(button => button.text === 'إغلاق' && button.element !== sheet.closeButton)!
    await close.click()
    assert.false(sheet.isOpen)
    await a11yAudit()
  })
})
