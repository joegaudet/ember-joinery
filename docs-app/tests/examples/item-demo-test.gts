import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ButtonHarness, IconHarness, ItemHarness } from '@ember-joinery/test-support'
import ItemDemo from 'docs-app/examples/item-demo'

module('Example | item-demo', function (hooks) {
  setupRenderingTest(hooks)

  test('an item with an action, and a small one that is a link', async function (assert) {
    await render(<template><ItemDemo /></template>)
    const [basic, verified] = ItemHarness.findAll()

    assert.strictEqual(basic!.variant, 'outline')
    assert.strictEqual(basic!.title, 'Basic Item')
    assert.strictEqual(basic!.description, 'A simple item with title and description.')
    const action = basic!.find(ButtonHarness)
    assert.strictEqual(action.label, 'Action')
    assert.strictEqual(action.size, 'sm')

    assert.strictEqual(verified!.size, 'sm')
    assert.true(verified!.isLink)
    assert.strictEqual(verified!.href, '#')
    assert.strictEqual(verified!.title, 'Your profile has been verified.')
    const [badge, chevron] = verified!.findAll(IconHarness)
    assert.strictEqual(getComputedStyle(badge!.element).width, '20px', 'size-5')
    assert.strictEqual(getComputedStyle(chevron!.element).width, '16px', 'size-4')
    await a11yAudit()
  })
})
