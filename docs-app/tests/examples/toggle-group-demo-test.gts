import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ToggleGroupHarness, tab } from '@ember-joinery/test-support'
import ToggleGroupDemo from 'docs-app/examples/toggle-group-demo'

module('Example | toggle-group-demo', function (hooks) {
  setupRenderingTest(hooks)

  test('three outline toggles, any of them on', async function (assert) {
    await render(<template><ToggleGroupDemo /></template>)
    const group = new ToggleGroupHarness()
    assert.strictEqual(group.type, 'multiple')
    assert.strictEqual(group.variant, 'outline')
    assert.deepEqual(group.itemValues, ['bold', 'italic', 'strikethrough'])
    assert.strictEqual(group.label('strikethrough'), 'Toggle strikethrough')
    await tab()
    assert.strictEqual(group.focused, 'bold', 'Tab enters on the first item')
    await group.press('ArrowRight')
    assert.strictEqual(group.focused, 'italic', 'the arrows move between them')
    await group.toggle('bold')
    await group.toggle('italic')
    assert.deepEqual(group.value, ['bold', 'italic'])
    await a11yAudit()
  })
})
