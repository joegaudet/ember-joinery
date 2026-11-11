import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ComboboxHarness } from '@ember-joinery/test-support'
import ComboboxDisabled from 'docs-app/examples/combobox-disabled'

module('Example | combobox-disabled', function (hooks) {
  setupRenderingTest(hooks)

  test('the input and its chevron are disabled, and the group fades', async function (assert) {
    await render(<template><ComboboxDisabled /></template>)
    const combobox = new ComboboxHarness()
    assert.true(combobox.isDisabled)
    assert.dom(combobox.trigger).isDisabled()
    assert.strictEqual(getComputedStyle(combobox.part('input-group')).opacity, '0.5')
    assert.false(combobox.isOpen)
    await a11yAudit()
  })
})
