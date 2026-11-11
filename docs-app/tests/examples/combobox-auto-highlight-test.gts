import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ComboboxHarness } from '@ember-joinery/test-support'
import ComboboxAutoHighlight from 'docs-app/examples/combobox-auto-highlight'

module('Example | combobox-auto-highlight', function (hooks) {
  setupRenderingTest(hooks)

  test('the first match is highlighted as you type, so Enter chooses it', async function (assert) {
    await render(<template><ComboboxAutoHighlight /></template>)
    const combobox = new ComboboxHarness()
    await combobox.type('r')
    assert.deepEqual(combobox.items, ['Remix', 'Astro'])
    assert.strictEqual(combobox.highlighted, 'Remix')
    await combobox.type('o')
    assert.strictEqual(combobox.highlighted, 'Astro')
    await a11yAudit()
    await combobox.pressKey('Enter')
    assert.strictEqual(combobox.inputValue, 'Astro')
    await a11yAudit()
  })
})
