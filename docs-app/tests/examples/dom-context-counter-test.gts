import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { click, render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { Harness } from '@ember-joinery/test-support'
import DomContextCounter from 'docs-app/examples/dom-context-counter'

class CounterHarness extends Harness {
  static component = 'counter'

  get count() {
    return Number(this.part('count').textContent)
  }

  get echo() {
    return this.part('echo').textContent!.trim()
  }

  async increment() {
    await click(this.part('increment'))
  }

  async decrement() {
    await click(this.part('decrement'))
  }
}

module('Example | dom-context-counter', function (hooks) {
  setupRenderingTest(hooks)

  test('every consumer reads the one counter the provider made', async function (assert) {
    await render(<template><DomContextCounter /></template>)
    const counter = new CounterHarness()
    assert.strictEqual(counter.count, 0)

    await counter.increment()
    await counter.increment()
    await counter.decrement()
    assert.strictEqual(counter.count, 1)
    assert.strictEqual(counter.echo, 'The count is 1.', 'the other consumer agrees')
    await a11yAudit()
  })
})
