import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ToggleHarness } from '@ember-joinery/test-support'
import ToggleSizes from 'docs-app/examples/toggle-sizes'

module('Example | toggle-sizes', function (hooks) {
  setupRenderingTest(hooks)

  test('small, default and large', async function (assert) {
    await render(<template><ToggleSizes /></template>)
    const toggles = ToggleHarness.findAll()
    assert.deepEqual(
      toggles.map(toggle => toggle.size),
      ['sm', 'default', 'lg'],
    )
    assert.deepEqual(
      toggles.map(toggle => getComputedStyle(toggle.element).height),
      ['28px', '32px', '36px'],
    )
    await a11yAudit()
  })
})
