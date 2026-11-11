import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { MarkerHarness } from '@ember-joinery/test-support'
import MarkerIcon from 'docs-app/examples/marker-icon'

module('Example | marker-icon', function (hooks) {
  setupRenderingTest(hooks)

  test('an icon beside the text, in a separator, and stacked above it with flex-col', async function (assert) {
    await render(<template><MarkerIcon /></template>)
    const [inline, separator, stacked] = MarkerHarness.findAll()
    for (const marker of [inline!, separator!, stacked!]) {
      assert.true(marker.hasIcon)
      assert.dom(marker.icon).hasAttribute('aria-hidden', 'true')
      assert.strictEqual(getComputedStyle(marker.icon.querySelector('svg')!).width, '16px')
    }
    assert.strictEqual(separator!.variant, 'separator')

    assert.strictEqual(getComputedStyle(stacked!.element).flexDirection, 'column')
    assert.ok(
      stacked!.icon.getBoundingClientRect().bottom <= stacked!.content.getBoundingClientRect().top,
      'the icon above the text',
    )
    assert.strictEqual(stacked!.text, 'Syncing completed')
    await a11yAudit()
  })
})
