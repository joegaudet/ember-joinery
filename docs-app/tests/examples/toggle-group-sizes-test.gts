import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ToggleGroupHarness } from '@ember-joinery/test-support'
import ToggleGroupSizes from 'docs-app/examples/toggle-group-sizes'

module('Example | toggle-group-sizes', function (hooks) {
  setupRenderingTest(hooks)

  test('a small group and a default one', async function (assert) {
    await render(<template><ToggleGroupSizes /></template>)
    const [small, normal] = ToggleGroupHarness.findAll()
    assert.strictEqual(small!.size, 'sm')
    assert.strictEqual(normal!.size, null, 'no @size: each item is the default')
    assert.strictEqual(getComputedStyle(small!.item('top')).height, '28px')
    assert.strictEqual(getComputedStyle(normal!.item('top')).height, '32px')
    assert.deepEqual(small!.value, ['top'])
    await small!.toggle('left')
    assert.deepEqual(small!.value, ['left'])
    assert.deepEqual(normal!.value, ['top'], 'each group has its own value')
    await a11yAudit()
  })
})
