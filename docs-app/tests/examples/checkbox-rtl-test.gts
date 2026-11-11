import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import { CheckboxHarness, FieldHarness } from '@ember-joinery/test-support'
import CheckboxRtl from 'docs-app/examples/checkbox-rtl'

module('Example | checkbox-rtl', function (hooks) {
  setupRenderingTest(hooks)

  test('in Arabic, each checkbox on the right of its label', async function (assert) {
    // The guide shows it with dir="rtl" on the preview; a provider does the same here.
    await render(
      <template>
        <DirectionProvider @dir="rtl"><CheckboxRtl /></DirectionProvider>
      </template>,
    )
    const [terms, described, disabled, card] = FieldHarness.findAll()
    const box = terms!.find(CheckboxHarness)

    assert.strictEqual(box.label, 'قبول الشروط والأحكام')
    assert.true(
      box.element.getBoundingClientRect().left >
        terms!.element.querySelector('label')!.getBoundingClientRect().right,
      'the checkbox comes first, on the right',
    )
    assert.true(described!.find(CheckboxHarness).isChecked)
    assert.strictEqual(described!.description, 'بالنقر على هذا المربع، فإنك توافق على الشروط.')
    assert.true(disabled!.find(CheckboxHarness).isDisabled)
    assert.strictEqual(card!.label, 'تفعيل الإشعارات')
    await card!.find(CheckboxHarness).check()
    assert.true(card!.find(CheckboxHarness).isChecked)
    await a11yAudit()
  })
})
