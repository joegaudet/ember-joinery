import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ToggleGroupHarness } from '@ember-joinery/test-support'
import ToggleGroupSpacing from 'docs-app/examples/toggle-group-spacing'

module('Example | toggle-group-spacing', function (hooks) {
  setupRenderingTest(hooks)

  test('items two steps apart', async function (assert) {
    await render(<template><ToggleGroupSpacing /></template>)
    const group = new ToggleGroupHarness()
    assert.strictEqual(group.spacing, 2)
    assert.strictEqual(getComputedStyle(group.element).columnGap, '8px')
    assert.strictEqual(
      getComputedStyle(group.item('bottom')).borderTopLeftRadius,
      '8px',
      'each its own corners',
    )
    await a11yAudit()
  })
})
