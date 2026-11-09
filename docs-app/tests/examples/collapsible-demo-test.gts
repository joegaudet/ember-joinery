import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ButtonHarness, CollapsibleHarness } from '@ember-joinery/test-support'
import CollapsibleDemo from 'docs-app/examples/collapsible-demo'

module('Example | collapsible-demo', function (hooks) {
  setupRenderingTest(hooks)

  test('an icon button shows and hides the order details', async function (assert) {
    await render(<template><CollapsibleDemo /></template>)
    const order = new CollapsibleHarness()
    const toggle = order.find(ButtonHarness)

    assert.strictEqual(order.trigger, toggle.element, 'the ghost icon Button is the trigger')
    assert.strictEqual(toggle.variant, 'ghost')
    assert.strictEqual(toggle.size, 'icon')
    assert.strictEqual(toggle.label, 'Toggle details', 'named by its hidden text')
    assert.false(order.isOpen)
    assert.false(order.isShown, 'the details start hidden')
    assert.dom(order.element).includesText('Status').includesText('Shipped')

    await order.open()
    assert.true(order.isOpen)
    assert.strictEqual(
      order.text,
      'Shipping address 100 Market St, San Francisco Items 2x Studio Headphones',
    )

    await toggle.click()
    assert.false(order.isShown, 'the same button hides them again')
    await a11yAudit()
  })
})
