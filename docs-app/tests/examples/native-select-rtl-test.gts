import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import { NativeSelectHarness } from '@ember-joinery/test-support'
import NativeSelectRtl from 'docs-app/examples/native-select-rtl'

module('Example | native-select-rtl', function (hooks) {
  setupRenderingTest(hooks)

  test('right to left, the chevron is on the left', async function (assert) {
    // The guide shows it with dir="rtl" on the preview; a provider does the same here.
    await render(
      <template>
        <DirectionProvider @dir="rtl"><NativeSelectRtl /></DirectionProvider>
      </template>,
    )
    const status = new NativeSelectHarness()
    assert.strictEqual(status.label, 'الحالة')
    assert.strictEqual(status.selectedText, 'اختر الحالة')

    const box = status.element.getBoundingClientRect()
    const chevron = status.icon.getBoundingClientRect()
    assert.ok(chevron.left < box.left + box.width / 2, 'the chevron is on the left')
    assert.strictEqual(getComputedStyle(status.control).paddingLeft, '32px', 'with its room')

    await status.select('done')
    assert.strictEqual(status.selectedText, 'منجز')
    await a11yAudit()
  })
})
