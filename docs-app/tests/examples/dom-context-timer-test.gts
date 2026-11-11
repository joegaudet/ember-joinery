import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render, waitUntil } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { Harness } from '@ember-joinery/test-support'
import DomContextTimer from 'docs-app/examples/dom-context-timer'

class TimerHarness extends Harness {
  static component = 'timer'

  get elapsed() {
    return this.part('elapsed').textContent!.trim()
  }

  get also() {
    return this.part('also').textContent!.trim()
  }
}

module('Example | dom-context-timer', function (hooks) {
  setupRenderingTest(hooks)

  test('both consumers read the one timer the function made, as it ticks', async function (assert) {
    await render(<template><DomContextTimer /></template>)
    const timer = new TimerHarness()
    assert.strictEqual(timer.elapsed, 'Seconds elapsed: 0')
    assert.strictEqual(timer.also, 'Also showing: 0s')

    // The timer ticks each second; wait for the first tick, as a reader would watch it.
    await waitUntil(() => timer.elapsed !== 'Seconds elapsed: 0', { timeout: 3000 })
    assert.strictEqual(timer.elapsed, 'Seconds elapsed: 1')
    assert.strictEqual(timer.also, 'Also showing: 1s', 'the same timer, not one each')
    await a11yAudit()
  })
})
