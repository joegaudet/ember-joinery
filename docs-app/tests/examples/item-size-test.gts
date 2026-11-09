import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ItemHarness } from '@ember-joinery/test-support'
import ItemSize from 'docs-app/examples/item-size'

module('Example | item-size', function (hooks) {
  setupRenderingTest(hooks)

  test('default, small and extra small', async function (assert) {
    await render(<template><ItemSize /></template>)
    const items = ItemHarness.findAll()
    assert.deepEqual(
      items.map(item => item.size),
      ['default', 'sm', 'xs'],
    )
    assert.deepEqual(
      items.map(item => item.title),
      ['Default Size', 'Small Size', 'Extra Small Size'],
    )
    assert.deepEqual(
      items.map(item => getComputedStyle(item.element).paddingTop),
      ['10px', '10px', '8px'],
    )
    assert.strictEqual(
      getComputedStyle(items[2]!.part('description')).fontSize,
      '12px',
      'an extra small description is text-xs',
    )
    await a11yAudit()
  })
})
