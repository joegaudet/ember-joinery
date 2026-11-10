import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { TraceHarness } from '@ember-joinery/test-support'
import TraceStatus from 'docs-app/examples/trace-status'

module('Example | trace-status', function (hooks) {
  setupRenderingTest(hooks)

  test('done, error, running and pending lines, the status said in each title', async function (assert) {
    await render(<template><TraceStatus /></template>)
    const [done, error, running, pending] = new TraceHarness().lines
    assert.strictEqual(done!.status, null)
    assert.strictEqual(done!.title, 'Ran pnpm install')
    assert.true(error!.isError)
    assert.strictEqual(error!.title, 'Failed to run pnpm lint')
    assert.true(running!.isRunning)
    assert.strictEqual(running!.title, 'Running pnpm build')
    assert.notStrictEqual(
      getComputedStyle(running!.titleElement).backgroundImage,
      'none',
      'the running title shimmers',
    )
    assert.strictEqual(
      getComputedStyle(running!.icons[0]!.querySelector('svg')!).animationName,
      'spin',
      'its spinner turns (animate-spin)',
    )
    assert.true(pending!.isPending)
    assert.strictEqual(getComputedStyle(pending!.element).opacity, '0.6')
    await a11yAudit()
  })
})
