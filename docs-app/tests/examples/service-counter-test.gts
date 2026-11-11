import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { click, render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { Harness } from '@ember-joinery/test-support'
import ServiceCounter from 'docs-app/examples/service-counter'

/** The example's shop: a button per item, and the cart's count. */
class ShopHarness extends Harness {
  static component = 'shop'

  get count() {
    return Number(this.part('count').textContent)
  }

  async add(item: string) {
    await click(this.part('add', item))
  }
}

module('Example | service-counter', function (hooks) {
  setupRenderingTest(hooks)

  test('both buttons add to the one cart', async function (assert) {
    await render(<template><ServiceCounter /></template>)
    const shop = new ShopHarness()
    assert.strictEqual(shop.count, 0)

    await shop.add('a lamp')
    await shop.add('a chair')
    assert.strictEqual(shop.count, 2, 'two components, one cart')
    await a11yAudit()
  })

  test('each test gets its own cart', async function (assert) {
    await render(<template><ServiceCounter /></template>)
    assert.strictEqual(new ShopHarness().count, 0, 'nothing carried over from the last test')
    await a11yAudit()
  })
})
