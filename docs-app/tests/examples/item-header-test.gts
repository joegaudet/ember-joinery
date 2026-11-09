import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ItemGroupHarness } from '@ember-joinery/test-support'
import ItemHeader from 'docs-app/examples/item-header'

module('Example | item-header', function (hooks) {
  setupRenderingTest(hooks)

  test('three models in a grid, each with an image header', async function (assert) {
    await render(<template><ItemHeader /></template>)
    const group = new ItemGroupHarness()
    assert.strictEqual(getComputedStyle(group.element).display, 'grid', 'grid grid-cols-3')
    const models = group.items
    assert.deepEqual(
      models.map(model => model.title),
      ['v0-1.5-sm', 'v0-1.5-lg', 'v0-2.0-mini'],
    )
    for (const model of models) {
      const image = model.header.querySelector('img')!
      assert.dom(image).hasAttribute('alt', model.title)
      assert.strictEqual(
        getComputedStyle(model.header).flexBasis,
        '100%',
        'the header takes a row of its own',
      )
    }
    assert.strictEqual(models[2]!.description, 'Open Source model for everyone.')
    await a11yAudit()
  })
})
