import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import { AlertHarness } from '@ember-joinery/test-support'
import AlertRtl from 'docs-app/examples/alert-rtl'

module('Example | alert-rtl', function (hooks) {
  setupRenderingTest(hooks)

  test('right to left, the icon is on the right', async function (assert) {
    // The guide shows it with dir="rtl" on the preview; a provider does the same here.
    await render(
      <template>
        <DirectionProvider @dir="rtl"><AlertRtl /></DirectionProvider>
      </template>,
    )
    const [payment, feature] = AlertHarness.findAll()
    assert.strictEqual(payment!.title, 'تم الدفع بنجاح')
    assert.strictEqual(feature!.title, 'ميزة جديدة متاحة')
    for (const alert of [payment!, feature!]) {
      const icon = alert.element.querySelector('svg')!.getBoundingClientRect()
      const title = alert.part('title').getBoundingClientRect()
      assert.ok(icon.left > title.left, 'the icon is right of the title')
      assert.strictEqual(getComputedStyle(alert.element).direction, 'rtl')
    }
    await a11yAudit()
  })
})
