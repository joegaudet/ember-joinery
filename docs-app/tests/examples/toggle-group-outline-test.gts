import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ToggleGroupHarness } from '@ember-joinery/test-support'
import ToggleGroupOutline from 'docs-app/examples/toggle-group-outline'

module('Example | toggle-group-outline', function (hooks) {
  setupRenderingTest(hooks)

  test('one of two, All to start', async function (assert) {
    await render(<template><ToggleGroupOutline /></template>)
    const group = new ToggleGroupHarness()
    assert.strictEqual(group.type, 'single')
    assert.deepEqual(group.value, ['all'])
    await group.toggle('missed')
    assert.deepEqual(group.value, ['missed'])
    await a11yAudit()
  })
})
