import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ToggleGroupHarness } from '@ember-joinery/test-support'
import ToggleGroupDisabled from 'docs-app/examples/toggle-group-disabled'

module('Example | toggle-group-disabled', function (hooks) {
  setupRenderingTest(hooks)

  test('every item disabled', async function (assert) {
    await render(<template><ToggleGroupDisabled /></template>)
    const group = new ToggleGroupHarness()
    assert.true(group.isDisabled())
    await group.toggle('bold').catch(() => undefined)
    assert.deepEqual(group.value, [])
    await a11yAudit()
  })
})
