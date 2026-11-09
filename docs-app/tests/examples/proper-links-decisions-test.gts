import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { Harness } from '@ember-joinery/test-support'
import ProperLinksDecisions from 'docs-app/examples/proper-links-decisions'

class DecisionsHarness extends Harness {
  static component = 'link-decisions'

  decision(label: string) {
    return this.part('link', label).querySelector('[data-test-jn-part="decision"]')!.textContent
  }
}

module('Example | proper-links-decisions', function (hooks) {
  setupRenderingTest(hooks)

  test('the router takes links to the app; the browser keeps the rest', async function (assert) {
    await render(<template><ProperLinksDecisions /></template>)
    const table = new DecisionsHarness()
    assert.strictEqual(table.decision('A page in the app'), 'The router')
    assert.strictEqual(table.decision('A heading on this page'), 'The browser')
    assert.strictEqual(table.decision('In a new tab'), 'The browser')
    assert.strictEqual(table.decision('A download'), 'The browser')
    assert.strictEqual(table.decision('Another site'), 'The browser')
    await a11yAudit()
  })
})
