import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import { DialogHarness, InputHarness } from '@ember-joinery/test-support'
import DialogRtl from 'docs-app/examples/dialog-rtl'

module('Example | dialog-rtl', function (hooks) {
  setupRenderingTest(hooks)

  test('in Arabic, the profile form right to left, its close button at the top left', async function (assert) {
    // The guide shows it with dir="rtl" on the preview; a provider does the same here.
    await render(
      <template>
        <DirectionProvider @dir="rtl"><DialogRtl /></DirectionProvider>
      </template>,
    )
    const dialog = new DialogHarness()
    assert.dom(dialog.trigger).hasText('فتح الحوار')
    await dialog.open()
    assert.strictEqual(dialog.label, 'تعديل الملف الشخصي')
    const [name, username] = dialog.findAll(InputHarness)
    assert.strictEqual(name!.label, 'الاسم')
    assert.strictEqual(username!.label, 'اسم المستخدم')
    const content = dialog.content!.getBoundingClientRect()
    const close = dialog.closeButton!.getBoundingClientRect()
    assert.true(
      close.left - content.left < content.right - close.right,
      'the close button at the left',
    )
    await a11yAudit()
  })
})
