import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ToggleGroupHarness } from '@ember-joinery/test-support'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import ToggleGroupRtl from 'docs-app/examples/toggle-group-rtl'

module('Example | toggle-group-rtl', function (hooks) {
  setupRenderingTest(hooks)

  test('right to left, the items run from the right', async function (assert) {
    await render(
      <template>
        <DirectionProvider @dir="rtl"><ToggleGroupRtl /></DirectionProvider>
      </template>,
    )
    const group = new ToggleGroupHarness()
    assert.deepEqual(group.value, ['list'])
    const [list, grid] = group.items.map(item => item.getBoundingClientRect())
    assert.true(list!.left > grid!.left, 'the first item is on the right')
    await group.focus('list')
    await group.press('ArrowLeft')
    assert.strictEqual(group.focused, 'grid', 'the left arrow moves forward')
    await group.toggle('cards')
    assert.deepEqual(group.value, ['cards'])
    await a11yAudit()
  })
})
