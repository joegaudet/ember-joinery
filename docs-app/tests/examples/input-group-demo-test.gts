import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { InputGroupHarness } from '@ember-joinery/test-support'
import InputGroupDemo from 'docs-app/examples/input-group-demo'

module('Example | input-group-demo', function (hooks) {
  setupRenderingTest(hooks)

  test('a search field with an icon before it and a count after', async function (assert) {
    await render(<template><InputGroupDemo /></template>)
    const search = new InputGroupHarness()
    assert.strictEqual(search.placeholder, 'Search...')
    assert.deepEqual(search.aligns, ['inline-start', 'inline-end'])
    assert.strictEqual(search.icons.length, 1)
    assert.strictEqual(search.addonText('inline-end'), '12 results')

    const icon = search.addon('inline-start').getBoundingClientRect()
    const input = search.control.getBoundingClientRect()
    const count = search.addon('inline-end').getBoundingClientRect()
    assert.ok(icon.right <= input.left && input.right <= count.left, 'icon, input, count')
    assert.strictEqual(getComputedStyle(search.element).maxWidth, '320px', 'max-w-xs')

    await search.clickAddon('inline-end')
    assert.true(search.isFocused, 'pressing an addon focuses the input')
    await search.typeIn('dialog')
    assert.strictEqual(search.value, 'dialog')
    await a11yAudit()
  })
})
