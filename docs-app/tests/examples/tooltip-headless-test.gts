import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { TooltipHarness } from '@ember-joinery/test-support'
import TooltipHeadless from 'docs-app/examples/tooltip-headless'

module('Example | tooltip-headless', function (hooks) {
  setupRenderingTest(hooks)

  test('the first tooltip waits for the provider’s delay; the next opens at once', async function (assert) {
    await render(<template><TooltipHeadless /></template>)
    const [bold, italic] = TooltipHarness.findAll()

    const started = performance.now()
    await bold!.hover()
    assert.true(performance.now() - started >= 390, 'the provider’s 400ms')
    assert.strictEqual(bold!.state, 'delayed-open')
    assert.strictEqual(bold!.description, 'Bold')
    await bold!.unhover()

    await italic!.hover()
    assert.strictEqual(italic!.state, 'instant-open', 'moving along, at once')
    assert.dom('svg', italic!.arrow!).hasClass('fill-gray-900')
    await a11yAudit()
  })
})
