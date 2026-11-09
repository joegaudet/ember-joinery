import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { click, render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { CheckboxHarness } from '@ember-joinery/test-support'
import CheckboxNative from 'docs-app/examples/checkbox-native'

module('Example | checkbox-native', function (hooks) {
  setupRenderingTest(hooks)

  test('each label names its checkbox, and a disabled one dims its label', async function (assert) {
    await render(<template><CheckboxNative /></template>)
    const [terms, described, notifications] = CheckboxHarness.findAll()

    assert.strictEqual(terms!.label, 'Accept terms and conditions')
    assert.false(terms!.isChecked)
    await click('label[for="terms-checkbox-native"]')
    assert.true(terms!.isChecked, 'a click on the label toggles it')

    assert.true(described!.isChecked, 'checked to start with')
    await described!.uncheck()
    assert.false(described!.isChecked)

    assert.true(notifications!.isDisabled)
    const label = document.querySelector('label[for="toggle-checkbox-native"]')!
    assert.strictEqual(getComputedStyle(label).opacity, '0.5', 'peer-disabled:opacity-50')
    await click(label)
    assert.false(notifications!.isChecked, 'a disabled checkbox stays as it is')
    await a11yAudit()
  })
})
