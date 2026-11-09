import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ToggleGroupHarness } from '@ember-joinery/test-support'
import ToggleGroupHeadless from 'docs-app/examples/toggle-group-headless'

module('Example | toggle-group-headless', function (hooks) {
  setupRenderingTest(hooks)

  test('one alignment at a time', async function (assert) {
    await render(<template><ToggleGroupHeadless /></template>)
    const group = new ToggleGroupHarness()
    assert.dom(group.element).hasAttribute('aria-label', 'Text alignment')
    assert.deepEqual(group.value, ['left'])
    await group.toggle('center')
    assert.deepEqual(group.value, ['center'])
    await a11yAudit()
  })
})
