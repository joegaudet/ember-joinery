import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import { ItemHarness, SpinnerHarness } from '@ember-joinery/test-support'
import SpinnerRtl from 'docs-app/examples/spinner-rtl'

module('Example | spinner-rtl', function (hooks) {
  setupRenderingTest(hooks)

  test('right to left, the spinner is on the right and named in Arabic', async function (assert) {
    // The guide shows it with dir="rtl" on the preview; a provider does the same here.
    await render(
      <template>
        <DirectionProvider @dir="rtl"><SpinnerRtl /></DirectionProvider>
      </template>,
    )
    const item = new ItemHarness()
    assert.strictEqual(item.title, 'جاري معالجة الدفع...')
    const spinner = item.find(SpinnerHarness)
    assert.strictEqual(spinner.label, 'جاري التحميل')
    const box = item.element.getBoundingClientRect()
    assert.ok(
      spinner.element.getBoundingClientRect().left > box.left + box.width / 2,
      'the spinner is on the right',
    )
    await a11yAudit()
  })
})
