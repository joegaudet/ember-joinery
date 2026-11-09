import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { PopoverHarness } from '@ember-joinery/test-support'
import PopoverHeadless from 'docs-app/examples/popover-headless'

module('Example | popover-headless', function (hooks) {
  setupRenderingTest(hooks)

  test('a popover of your own, placed by ember-primitives’ arguments, with an arrow', async function (assert) {
    await render(<template><PopoverHeadless /></template>)
    const popover = new PopoverHarness()
    await popover.open()
    assert.true(popover.isShown)
    assert.true(['top', 'bottom'].includes(popover.side!), `placed ${popover.side}`)
    assert.strictEqual(popover.title, `Placed ${popover.side}`, 'the yielded data says where')
    assert.strictEqual(popover.description, 'Escape or a press outside closes it.')
    assert.strictEqual(popover.arrow!.style.position, 'absolute', 'the arrow is placed')

    await popover.clickClose()
    assert.false(popover.isOpen)
    await a11yAudit()
  })
})
