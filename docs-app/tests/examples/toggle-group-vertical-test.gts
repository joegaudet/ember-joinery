import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ToggleGroupHarness, tab } from '@ember-joinery/test-support'
import ToggleGroupVertical from 'docs-app/examples/toggle-group-vertical'

module('Example | toggle-group-vertical', function (hooks) {
  setupRenderingTest(hooks)

  test('stacked, with bold and italic on', async function (assert) {
    await render(<template><ToggleGroupVertical /></template>)
    const group = new ToggleGroupHarness()
    assert.strictEqual(group.orientation, 'vertical')
    assert.strictEqual(getComputedStyle(group.element).flexDirection, 'column')
    assert.deepEqual(group.value, ['bold', 'italic'])
    await tab()
    await group.press('ArrowDown')
    assert.strictEqual(group.focused, 'italic', 'the down arrow moves on')
    await group.toggle('underline')
    assert.deepEqual(group.value, ['bold', 'italic', 'underline'])
    await a11yAudit()
  })
})
