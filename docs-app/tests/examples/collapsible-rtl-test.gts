import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import { ButtonHarness, CollapsibleHarness } from '@ember-joinery/test-support'
import CollapsibleRtl from 'docs-app/examples/collapsible-rtl'

module('Example | collapsible-rtl', function (hooks) {
  setupRenderingTest(hooks)

  test('right to left, the toggle sits at the left of the title', async function (assert) {
    // The guide shows it with dir="rtl" on the preview; a provider does the same here.
    await render(
      <template>
        <DirectionProvider @dir="rtl"><CollapsibleRtl /></DirectionProvider>
      </template>,
    )
    const order = new CollapsibleHarness()
    const toggle = order.find(ButtonHarness)
    assert.strictEqual(toggle.label, 'تبديل التفاصيل')

    const title = order.element.querySelector('h4')!
    assert.ok(
      toggle.element.getBoundingClientRect().right <= title.getBoundingClientRect().left,
      'the title starts on the right, the toggle ends the row on the left',
    )

    await order.open()
    assert.strictEqual(
      order.text,
      'عنوان الشحن 100 Market St, San Francisco العناصر 2x سماعات الاستوديو',
    )
    await a11yAudit()
  })
})
