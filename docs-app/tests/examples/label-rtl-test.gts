import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import { CheckboxHarness, LabelHarness } from '@ember-joinery/test-support'
import LabelRtl from 'docs-app/examples/label-rtl'

module('Example | label-rtl', function (hooks) {
  setupRenderingTest(hooks)

  test('in Arabic, the checkbox on the right of its label', async function (assert) {
    // The guide shows it with dir="rtl" on the preview; a provider does the same here.
    await render(
      <template>
        <DirectionProvider @dir="rtl"><LabelRtl /></DirectionProvider>
      </template>,
    )
    const label = new LabelHarness()
    const terms = new CheckboxHarness()

    assert.strictEqual(label.text, 'قبول الشروط والأحكام')
    assert.strictEqual(terms.label, 'قبول الشروط والأحكام', 'the label names the checkbox')
    assert.ok(
      terms.element.getBoundingClientRect().left >= label.element.getBoundingClientRect().right,
      'the checkbox comes first, on the right',
    )

    await label.click()
    assert.true(terms.isChecked, 'a click on the label checks it')
    await a11yAudit()
  })
})
