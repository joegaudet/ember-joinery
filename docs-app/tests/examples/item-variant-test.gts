import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ItemHarness } from '@ember-joinery/test-support'
import ItemVariant from 'docs-app/examples/item-variant'

module('Example | item-variant', function (hooks) {
  setupRenderingTest(hooks)

  test('default, outline and muted', async function (assert) {
    await render(<template><ItemVariant /></template>)
    const items = ItemHarness.findAll()
    assert.deepEqual(
      items.map(item => item.variant),
      ['default', 'outline', 'muted'],
    )
    assert.deepEqual(
      items.map(item => item.title),
      ['Default Variant', 'Outline Variant', 'Muted Variant'],
    )
    for (const item of items) assert.strictEqual(item.mediaVariant, 'icon')
    const [plain, outline, muted] = items.map(item => getComputedStyle(item.element))
    assert.strictEqual(plain!.borderTopColor, 'rgba(0, 0, 0, 0)', 'no border to see')
    assert.notStrictEqual(outline!.borderTopColor, 'rgba(0, 0, 0, 0)', 'a visible border')
    assert.notStrictEqual(muted!.backgroundColor, 'rgba(0, 0, 0, 0)', 'a muted background')
    await a11yAudit()
  })
})
