import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { LabelHarness } from '@ember-joinery/test-support'
import LabelNative from 'docs-app/examples/label-native'

module('Example | label-native', function (hooks) {
  setupRenderingTest(hooks)

  test('each label names its checkbox, and dims beside a disabled one', async function (assert) {
    await render(<template><LabelNative /></template>)
    const [terms, marketing] = LabelHarness.findAll()
    assert.strictEqual(terms!.text, 'Accept terms and conditions')
    assert.dom(terms!.control).hasAttribute('type', 'checkbox')

    await terms!.click()
    assert.dom(terms!.control).isChecked('a click on the label toggles its checkbox')
    await terms!.click()
    assert.dom(terms!.control).isNotChecked()
    assert.strictEqual(getComputedStyle(terms!.element).opacity, '1')

    assert.strictEqual(marketing!.text, 'Send me marketing emails')
    assert.true(marketing!.isControlDisabled)
    assert.strictEqual(
      getComputedStyle(marketing!.element).opacity,
      '0.5',
      'peer-disabled:opacity-50',
    )
    await marketing!.click()
    assert.dom(marketing!.control).isNotChecked('a disabled checkbox stays as it is')
    await a11yAudit()
  })
})
