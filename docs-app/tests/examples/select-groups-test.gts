import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { SelectHarness } from '@ember-joinery/test-support'
import SelectGroups from 'docs-app/examples/select-groups'

module('Example | select-groups', function (hooks) {
  setupRenderingTest(hooks)

  test('fruits and vegetables, each a labelled group, a separator between', async function (assert) {
    await render(<template><SelectGroups /></template>)
    const select = new SelectHarness()
    await select.openWithKeyboard()
    assert.deepEqual(select.groups, ['Fruits', 'Vegetables'])
    assert.deepEqual(select.optionsIn('Fruits'), ['apple', 'banana', 'blueberry'])
    assert.deepEqual(select.optionsIn('Vegetables'), ['carrot', 'broccoli', 'spinach'])
    assert.dom('[data-slot="select-separator"]', select.content).exists({ count: 1 })
    await select.pressKey('End')
    assert.dom(select.option('spinach')).isFocused('End goes past the separator to the last option')
    await select.pressKey('Enter')
    assert.strictEqual(select.valueText, 'Spinach')
    await a11yAudit()
  })
})
