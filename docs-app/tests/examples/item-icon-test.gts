import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ButtonHarness, IconHarness, ItemHarness } from '@ember-joinery/test-support'
import ItemIcon from 'docs-app/examples/item-icon'

module('Example | item-icon', function (hooks) {
  setupRenderingTest(hooks)

  test('an alert with an icon and a review button', async function (assert) {
    await render(<template><ItemIcon /></template>)
    const item = new ItemHarness()
    assert.strictEqual(item.title, 'Security Alert')
    assert.strictEqual(item.description, 'New login detected from unknown device.')
    assert.strictEqual(item.mediaVariant, 'icon')
    const icon = item.find(IconHarness)
    assert.true(icon.isDecorative)
    assert.strictEqual(getComputedStyle(icon.element).width, '16px', 'size-4 in icon media')
    assert.strictEqual(item.find(ButtonHarness).label, 'Review')
    await a11yAudit()
  })
})
