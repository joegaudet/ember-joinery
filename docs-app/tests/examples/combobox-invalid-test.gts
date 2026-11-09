import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ComboboxHarness } from '@ember-joinery/test-support'
import ComboboxInvalid from 'docs-app/examples/combobox-invalid'

module('Example | combobox-invalid', function (hooks) {
  setupRenderingTest(hooks)

  test('aria-invalid on the input marks it, and its group draws the error', async function (assert) {
    await render(<template><ComboboxInvalid /></template>)
    const combobox = new ComboboxHarness()
    assert.true(combobox.isInvalid)
    const group = combobox.part('input-group')
    const destructive = getComputedStyle(group).borderTopColor
    assert.notStrictEqual(
      destructive,
      getComputedStyle(combobox.input!).color,
      'a border colour of its own',
    )
    await combobox.select('Remix')
    assert.strictEqual(combobox.inputValue, 'Remix', 'it still works')
    await a11yAudit()
  })
})
