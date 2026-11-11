import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ItemHarness, tab } from '@ember-joinery/test-support'
import ItemLink from 'docs-app/examples/item-link'

module('Example | item-link', function (hooks) {
  setupRenderingTest(hooks)

  test('two items that are links, one opening a new tab', async function (assert) {
    await render(<template><ItemLink /></template>)
    const [docs, external] = ItemHarness.findAll()
    assert.true(docs!.isLink)
    assert.strictEqual(docs!.title, 'Visit our documentation')
    assert.strictEqual(docs!.variant, 'default')

    assert.true(external!.isLink)
    assert.strictEqual(external!.variant, 'outline')
    assert
      .dom(external!.element)
      .hasAttribute('target', '_blank')
      .hasAttribute('rel', 'noopener noreferrer')

    await docs!.focus()
    await tab()
    assert.true(external!.isFocused, 'Tab moves from one link to the next')
    await a11yAudit()
  })
})
