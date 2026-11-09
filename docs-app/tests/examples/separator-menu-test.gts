import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { getRootElement, render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { SeparatorHarness } from '@ember-joinery/test-support'
import SeparatorMenu from 'docs-app/examples/separator-menu'

module('Example | separator-menu', function (hooks) {
  setupRenderingTest(hooks)

  test('vertical lines between menu items, the last one only on wider screens', async function (assert) {
    await render(<template><SeparatorMenu /></template>)
    const [first, second] = SeparatorHarness.findAll()
    assert.strictEqual(first!.orientation, 'vertical')
    assert.strictEqual(second!.orientation, 'vertical')
    assert.ok(
      Number.parseFloat(getComputedStyle(first!.element).height) > 20,
      'as tall as the items',
    )
    // `hidden md:block`: the test page is wider than md (768px), so it shows.
    const wide = window.matchMedia('(min-width: 48rem)').matches
    assert.strictEqual(getComputedStyle(second!.element).display, wide ? 'block' : 'none')
    assert.ok(getRootElement().textContent!.includes('Profile & security'))
    await a11yAudit()
  })
})
