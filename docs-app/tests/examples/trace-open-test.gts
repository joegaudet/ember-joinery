import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ButtonHarness, TraceCollapsibleHarness } from '@ember-joinery/test-support'
import TraceOpen from 'docs-app/examples/trace-open'

module('Example | trace-open', function (hooks) {
  setupRenderingTest(hooks)

  test('one row starts open, and a button controls the other', async function (assert) {
    await render(<template><TraceOpen /></template>)
    const [node, pnpm] = TraceCollapsibleHarness.findAll()
    assert.true(node!.isOpen, '@defaultOpen')
    assert.false(pnpm!.isOpen)
    const button = new ButtonHarness()
    assert.strictEqual(button.label, 'Show the pnpm output')
    await button.click()
    assert.true(pnpm!.isOpen, 'the button opens the controlled row')
    assert.strictEqual(button.label, 'Hide the pnpm output')
    await pnpm!.toggle()
    assert.false(pnpm!.isOpen, 'and its own trigger closes it, through @onOpenChange')
    assert.strictEqual(button.label, 'Show the pnpm output')
    await a11yAudit()
  })
})
